#!/usr/bin/env python3
"""Send a storyboard sampled from the agent pipeline through Social Studio."""

import argparse
import json
from pathlib import Path
import subprocess
from tempfile import TemporaryDirectory


def preview(checkout, movie, destination):
    studio = checkout.resolve() / 'flutter/social_studio'
    output = destination.resolve()
    if output.exists():
        raise ValueError(f'Choose a new Social Studio output directory. {output} already exists.')
    if not movie.is_file():
        raise ValueError(f'Render the agent pipeline first. {movie} was not found.')
    subprocess.run(['flutter', 'pub', 'get', '--enforce-lockfile'], cwd=studio, check=True)
    with TemporaryDirectory(prefix='event-motion-storyboard-') as temporary:
        root = Path(temporary)
        subprocess.run([
            'ffmpeg', '-v', 'error', '-i', str(movie.resolve()), '-vf',
            'fps=2,scale=1080:1350,pad=1080:1920:0:285:color=0x101C2E',
            '-frames:v', '8', str(root / 'frame-%02d.png'),
        ], check=True)
        frames = sorted(root.glob('frame-*.png'))
        if len(frames) != 8:
            raise ValueError('The four-second agent pipeline should yield eight storyboard frames.')
        subprocess.run([
            'ffmpeg', '-v', 'error', '-f', 'lavfi', '-i', 'anullsrc=r=48000:cl=mono',
            '-t', '12', str(root / 'silence.wav'),
        ], check=True)
        job = root / 'story.json'
        job.write_text(json.dumps({
            'version': 1, 'template': 'story-photo-v1', 'audio': 'silence.wav',
            'durationMs': 12000, 'coverMs': 7500,
            'scenes': [{'image': frame.name, 'durationMs': 1500} for frame in frames],
            'captions': [
                {'startMs': 0, 'endMs': 4500, 'text': 'An illustrative workflow'},
                {'startMs': 9000, 'endMs': 12000, 'text': 'Ready for human review'},
            ],
        }, indent=2) + '\n', encoding='utf-8')
        cli = ['dart', 'run', 'bin/social_studio.dart']
        subprocess.run([*cli, 'validate', str(job)], cwd=studio, check=True)
        subprocess.run([*cli, 'render', str(job), str(output)], cwd=studio, check=True)
    review = output / 'review.html'
    if not review.is_file():
        raise ValueError(f'Social Studio did not write {review}.')
    print(f'Open {review}')


def main():
    root = Path(__file__).resolve().parent.parent
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('checkout', type=Path, help='Social Studio checkout')
    parser.add_argument('--movie', type=Path, default=root / 'example/build/agent_pipeline/agent_pipeline.mp4')
    parser.add_argument('--out', type=Path, default=root / 'example/build/social-studio')
    args = parser.parse_args()
    try:
        preview(args.checkout, args.movie, args.out)
    except (OSError, ValueError, subprocess.CalledProcessError) as error:
        parser.exit(1, f'{error}\n')


if __name__ == '__main__':
    main()
