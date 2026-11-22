#!/usr/bin/env python3
"""Render the shared card sequence locally and optionally composite it in Fluvie."""

import argparse
from fractions import Fraction
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
from tempfile import TemporaryDirectory
from time import monotonic
from urllib.parse import urljoin, urlparse, unquote


ROOT = Path(__file__).resolve().parent.parent
EXAMPLE = ROOT / 'example'
PROJECT = EXAMPLE / 'hyperframes'
FPS = 24
LEAD_FRAMES = 18


def run(command, **options):
    return subprocess.run(command, check=True, **options)


def fluvie_fonts():
    config = EXAMPLE / '.dart_tool/package_config.json'
    if not config.is_file():
        run(['flutter', 'pub', 'get'], cwd=EXAMPLE)
    package = next(item for item in json.loads(config.read_text())['packages'] if item['name'] == 'fluvie')
    uri = urljoin(config.as_uri(), package['rootUri'])
    return Path(unquote(urlparse(uri).path)) / 'fonts'


def hyperframes_cli():
    executable = PROJECT / 'node_modules/.bin/hyperframes'
    installed = PROJECT / 'node_modules/hyperframes/package.json'
    expected = json.loads((PROJECT / 'package.json').read_text())['devDependencies']['hyperframes']
    if not (executable.is_file() and installed.is_file() and json.loads(installed.read_text())['version'] == expected):
        run(['npm', 'ci', '--no-audit', '--no-fund'], cwd=PROJECT)
    return executable


def stage_project(directory, source, mode, audio):
    directory.mkdir()
    cards = directory / 'cards.json'
    shutil.copyfile(source, cards)
    fonts = fluvie_fonts()
    run(['dart', str(EXAMPLE / 'bin/validate_cards.dart'), str(cards)], cwd=EXAMPLE)
    data = json.loads(cards.read_text(encoding='utf-8'))
    canvas = (480, 600) if mode == 'compare' else (1080, 1350)
    template = PROJECT / 'template'
    for file in ('cards.js', 'cards.css'):
        shutil.copyfile(template / file, directory / file)
    for original, name in [('JetBrainsMono-Regular.ttf', 'regular.ttf'), ('JetBrainsMono-Bold.ttf', 'bold.ttf')]:
        shutil.copyfile(fonts / original, directory / name)
    (directory / 'payload.js').write_text(f'window.eventMotionCards = {json.dumps(data)};\n', encoding='utf-8')
    duration = data['durationMs'] / 1000
    audio_tag = ''
    if audio is not None:
        shutil.copyfile(audio, directory / 'sound.wav')
        audio_tag = f'<audio data-start="0" data-duration="{duration}" data-track-index="1" src="sound.wav"></audio>'
    html = (template / 'index.html').read_text(encoding='utf-8')
    for cue, value in {
        'WIDTH': canvas[0], 'HEIGHT': canvas[1], 'SCALE': canvas[0] / 480,
        'DURATION': duration, 'MODE': 'overlay' if mode == 'overlay' else 'opaque', 'AUDIO': audio_tag,
    }.items():
        html = html.replace(f'__{cue}__', str(value))
    (directory / 'index.html').write_text(html, encoding='utf-8')
    return cards, data, canvas


def check_clip(path, canvas, expected_frames, *, alpha=False, audio=False):
    result = run(['ffprobe', '-v', 'error', '-count_frames', '-show_streams', '-show_format', '-of', 'json', str(path)], capture_output=True)
    metadata = json.loads(result.stdout)
    video = next((stream for stream in metadata['streams'] if stream['codec_type'] == 'video'), None)
    if video is None or (video['width'], video['height']) != canvas or Fraction(video['r_frame_rate']) != FPS:
        raise ValueError(f'{path.name} must have a {canvas[0]} × {canvas[1]} video stream at {FPS} fps.')
    frames = int(video['nb_read_frames'])
    duration = float(metadata['format']['duration'])
    if abs(frames - expected_frames) > 1 or abs(duration - frames / FPS) > 1 / FPS:
        raise ValueError(f'{path.name} has {frames} frames over {duration:g} s, expected {expected_frames} frames.')
    if audio and not any(stream['codec_type'] == 'audio' for stream in metadata['streams']):
        raise ValueError(f'{path.name} is missing the requested audio stream.')
    if alpha:
        tags = {key.lower(): value for key, value in video.get('tags', {}).items()}
        if video['codec_name'] != 'vp9' or tags.get('alpha_mode') != '1':
            raise ValueError(f'{path.name} does not declare VP9 alpha.')
        plane = run(['ffmpeg', '-v', 'error', '-ss', '0.75', '-c:v', 'libvpx-vp9', '-i', str(path),
                     '-vf', 'alphaextract', '-frames:v', '1', '-f', 'rawvideo', '-'], capture_output=True).stdout
        if not plane or min(plane) != 0 or max(plane) < 240:
            raise ValueError(f'{path.name} must contain both transparent and opaque pixels.')
    return frames


def render(args):
    output = (args.out or EXAMPLE / 'build/hyperframes' / args.mode).resolve()
    overlay = args.mode == 'overlay'
    with TemporaryDirectory(prefix='event-motion-hyperframes-') as temporary:
        sandbox = Path(temporary)
        cards, data, canvas = stage_project(sandbox / 'scene', args.cards, args.mode, args.audio)
        executable = hyperframes_cli()
        codec = 'webm' if overlay else 'mp4'
        clip = sandbox / f'hyperframes.{codec}'
        log = sandbox / 'hyperframes.log'
        start = monotonic()
        with log.open('wb') as stream:
            try:
                run([str(executable), 'render', str(cards.parent), '--format', codec, '--output', str(clip),
                     '--fps', str(FPS), '--workers', '1'], stdout=stream, stderr=subprocess.STDOUT,
                    env={**os.environ, 'DO_NOT_TRACK': '1'})
            except subprocess.CalledProcessError:
                print(log.read_text(errors='replace')[-4000:], file=sys.stderr)
                raise
        elapsed = monotonic() - start
        expected = (data['durationMs'] * FPS + 500) // 1000
        frames = check_clip(clip, canvas, expected, alpha=overlay, audio=args.audio is not None)
        artifacts = [clip]
        metrics = {
            'hyperframes_seconds': round(elapsed, 2), 'source_frames': frames,
            'source_bytes': clip.stat().st_size, 'width': canvas[0], 'height': canvas[1], 'fps': FPS,
        }
        if args.mode == 'compare':
            cover = sandbox / 'hyperframes.png'
            run(['ffmpeg', '-v', 'error', '-ss', str(data['coverMs'] / 1000), '-i', str(clip), '-frames:v', '1', str(cover)])
            artifacts.append(cover)
        else:
            start = monotonic()
            render_dir = sandbox / 'fluvie'
            capture_tmp = sandbox / 'capture'
            capture_tmp.mkdir()
            run(['flutter', 'test', '--dart-define=RENDER_EXAMPLE=true', 'test/render_example_test.dart',
                 '--plain-name', 'exports hybrid as MP4 and PNG'], cwd=EXAMPLE, env={
                     **os.environ, 'TMPDIR': str(capture_tmp), 'EVENT_MOTION_CARDS': str(cards),
                     'EVENT_MOTION_HYBRID_CLIP': str(clip), 'EVENT_MOTION_HYBRID_FRAMES': str(frames),
                     'EVENT_MOTION_HYBRID_ALPHA': '1' if overlay else '0',
                     'EVENT_MOTION_HYBRID_OUT': str(render_dir),
                 })
            movie = render_dir / 'hybrid.mp4'
            check_clip(movie, canvas, frames + LEAD_FRAMES, audio=args.audio is not None)
            artifacts.extend([movie, render_dir / 'hybrid.png'])
            metrics.update(
                fluvie_seconds=round(monotonic() - start, 2),
                fluvie_capture_bytes=int((render_dir / 'capture-bytes.txt').read_text()),
                final_bytes=movie.stat().st_size,
            )
        report = sandbox / 'metrics.json'
        report.write_text(json.dumps(metrics, indent=2) + '\n', encoding='utf-8')
        output.mkdir(parents=True, exist_ok=True)
        for file in [*artifacts, report]:
            shutil.copyfile(file, output / file.name)
    print(f'Saved {output}')


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('mode', choices=['compare', 'overlay', 'opaque'])
    parser.add_argument('--cards', type=Path, default=EXAMPLE / 'fixtures/cards.json')
    parser.add_argument('--audio', type=Path, help='WAVE soundtrack for opaque mode')
    parser.add_argument('--out', type=Path)
    args = parser.parse_args()
    if args.audio is not None and (args.mode != 'opaque' or args.audio.suffix.lower() != '.wav'):
        parser.error('--audio takes a WAVE file in opaque mode')
    try:
        render(args)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        print(error, file=sys.stderr)
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
