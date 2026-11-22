# Local render integrations

## HyperFrames and Fluvie

Use Python, Node.js 22+, Flutter, FFmpeg with `libvpx-vp9`, and Chrome. The command installs the locked HyperFrames dependencies with `npm ci` when needed. Set `HYPERFRAMES_BROWSER_PATH` to select your Chrome executable. The render stages contain the local template, the validated card data, and the JetBrains Mono fonts from the pinned Fluvie package. [HyperFrames local rendering](https://github.com/heygen-com/hyperframes/blob/main/docs/guides/rendering.mdx)

```sh
bash tool/render_example.sh card_sequence
python3 tool/render_hyperframes.py compare
python3 tool/render_hyperframes.py overlay
python3 tool/render_hyperframes.py opaque --audio ./sound.wav
```

`compare` exports the same card sequence and its selected cover at 480 × 600. `overlay` renders a transparent 1080 × 1350 VP9 WebM and places it over a Flutter background and headings. `opaque` places a 1080 × 1350 MP4, optionally carrying WAVE audio, into the same Fluvie composition. Both hybrids start the clip after an 18-frame Flutter introduction at 24 fps.

Use `--cards ./cards.json` to supply the same document to HyperFrames that `bash tool/render_example.sh card_sequence ./cards.json` passes to Flutter. Start from the [shared fixture](../example/fixtures/cards.json). The four card slots control the four illustrations. Keep their order and IDs while editing titles, copy, colors, and cue times.

Results are written under `example/build/hyperframes/<mode>/` unless `--out` is supplied. The bridge checks dimensions, frame rate, duration, and decoded alpha where applicable before giving the clip to Fluvie. Hybrid outputs include `hybrid.mp4`, `hybrid.png`, and metrics for stage timing and file sizes.

## Social Studio review

The current Social Studio desktop Story job accepts images and WAV audio. The adapter samples eight frames from Event Motion's four-second pipeline, letterboxes those frames for 9:16, and creates a twelve-second Story using the existing photo-sequence job and a silent audio track. Open the resulting review page to seek by scene or caption.

```sh
bash tool/render_example.sh agent_pipeline
python3 tool/social_studio_preview.py ../social-studio
```

The bridge was verified with [Social Studio `b13ecea`](https://github.com/moisesaguiarjunior/social-studio/tree/b13ecea0d488afbd3f3e26abb6f3c4bbf4a9829c). Use `--out` with a new destination for subsequent previews. The default review is at `example/build/social-studio/review.html`. Keep the generated files together so the page can play the video.
