# Verification

The local tests used an Apple M1 Max with 32 GB of memory, Flutter 3.47.9, Ollama 0.40.17, and the HyperFrames version pinned in the lockfile. Render durations are observations from one machine and include tool startup where specified.

## Model and layout

| Brief | Valid attempt | Authoring time | Result |
| --- | ---: | ---: | --- |
| [Newsletter](../example/fixtures/briefs/newsletter.txt) | 1 | 25.23 s | Three-stage vertical story with the requested heading. |
| [Script review](../example/fixtures/briefs/script-review.txt) | 1 | 30.13 s | Four-stage diamond with Portuguese status captions. The model misspelled one word in the title. |
| [Locked review](../example/fixtures/briefs/locked-review.txt) | 1 | 2.03 s | All fields besides title and subtitle matched the supplied workflow. |

All three accepted specs exported a PNG and an MP4. Replaying the locked spec produced byte-identical outputs. A follow-up brief supplying the exact Portuguese title also passed on its first attempt and reproduced the title correctly in 16.15 s. Structural validity and spelling are separate review checks. The test suite also exercises repair after an invalid model response using a local stub server.

Rendered samples were checked at 360 pixels wide with short and long Portuguese copy, the diamond and vertical layouts, and the paper comparison. The vertical template assigns wider cards with a consistent gap when a long heading takes more space. The 1080 × 1350 activation covers an active review and includes an optional AAC track from a synthetic WAVE file. The comparison image uses a common scale for all bars and measures both ends of each interval from that scale.

## Matching card renders

| 480 × 600, seven seconds at 24 fps | Observed export |
| --- | ---: |
| Flutter and FFmpeg | 5.17 s for PNG and MP4, including command startup |
| HyperFrames | 35.15 s for MP4, including local Chrome startup |

The Flutter example reuses its existing frame widgets and render harness. The HyperFrames example needs a separate HTML layout, CSS and a time-driven canvas painter. Both read the same four-card fixture and show the focus, rail and final mosaic. Visually, the covers share the layout and typography. The browser version places the top row slightly higher and uses squared preview marks in some illustrations. Flutter is the simpler path for this template. HyperFrames is useful when the scene already exists as HTML or needs browser animation.

## Hybrid and adoption

The transparent and opaque imports were tested at 1080 × 1350. Each source had 168 frames and the Fluvie result had 186. In the transparent result, sampled opaque pixels at source frame 24 matched composite frame 42 within the comparison tolerance. The Flutter background remained visible outside the cards. In the opaque result, decoded audio was silent before the 750 ms introduction ended and present after the clip began.

| Full-size stage | HyperFrames | Fluvie and probe | Source clip | Raw Flutter capture | Final MP4 |
| --- | ---: | ---: | ---: | ---: | ---: |
| Transparent | 8.89 s | 31.45 s | 263,536 B | 1,084,752,000 B | 158,791 B |
| Opaque with sound | 18.39 s | 23.04 s | 970,715 B | 1,084,752,000 B | 754,565 B |

An export from a clean source archive installed the pinned dependencies and rebuilt the hybrid. Its final PNG and MP4 matched the originals byte for byte. The raw Flutter capture was 1,084,752,000 bytes as measured before teardown.

Eight samples from the agent panel passed Social Studio's Story job validator and produced a 12-second review bundle. The storyboard follows Social Studio's photo-sequence input format. In Chrome, scene selection sought to 7.5 seconds and caption selection sought to 9 seconds. Both paused playback at the selected moment.

## Quality and package candidate

The automated checks cover formatting, analysis, six library tests, thirteen example tests, and a headless export of the 96-frame agent workflow. The GitHub workflow ran on Ubuntu 24.04 with Flutter 3.47.9. [Passing Quality run](https://github.com/moisesaguiarjunior/event_motion/actions/runs/44973728685)

The Flutter package candidate is `0.1.0` under MIT. `flutter pub publish --dry-run` validated the 47 KB archive with zero warnings. The archive contains the Flutter source, synthetic fixtures and tools. Generated media, fonts and installed dependencies stayed outside the package. `npm audit` reported zero known advisories for the pinned HyperFrames dependency tree during verification. See the [dependency and asset provenance](compatibility.md).

## Editorial compositions in 0.2.0

| Composition | PNG | MP4 at 24 fps |
| --- | --- | ---: |
| Eight-tile editorial grid | 1080 × 1350 | 180 frames |
| Twelve-tile editorial grid | 1080 × 1350 | 252 frames |
| Character poster | 1080 × 1350 | — |
| Character dashboard | 1080 × 1350 | 192 frames |
| Grid authored from a brief | 1080 × 1350 | 180 frames |

The covers were reviewed at 360 pixels wide. Sampled frames cover the initial layout, tile focus and internal diagram changes, curved signals and callouts, and the end states with every step complete. A long-text, reverse-order twelve-tile render caught a layout overflow. The compact three-column layout keeps room for diagrams and the twelve-tile render now runs in CI.

The original three compositions and the grid from the saved model JSON produced byte-identical PNG and MP4 outputs on local replay. The v0.1.0 agent pipeline and card sequence also matched both archived files. The comparison PNGs and activation cover matched their archives.

The first catalog model run exceeded the note limit. Direct length constraints in the Ollama schema and shorter instructions fixed that failure. With the final [Portuguese brief](../example/fixtures/briefs/editorial-catalog.txt), local `qwen3.5:4b` produced the requested “Como nasce um fio” title and eight complete notes on the first attempt in 8.80 seconds, before rendering. A stub test covers semantic repair of a repeated ID and refusal to replace an existing catalog.

The [reference library index](../references/README.md) credits the source posts. Its local folders also contain the source media, archived exports, contact sheets, and editable final documents.
