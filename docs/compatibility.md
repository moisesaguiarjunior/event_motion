# Compatibility and release scope

| Component | Version or requirement |
| --- | --- |
| Library | Flutter 3.44 or later and Dart 3.12 or later. Development and CI target Flutter 3.47.9. |
| Fluvie examples | [`b2f578a`](https://github.com/moisesaguiarjunior/fluvie/tree/b2f578a343d8f019cab577bdcef10740545e0fad). The experimental frame adapter lives inside the example. |
| Handcrafted examples | [`9eda99d`](https://github.com/moisesaguiarjunior/handcrafted_flutter/tree/9eda99d2d4e12b849733b8962a2ebe3b178ff562), through the example dependency. |
| HyperFrames bridge | HyperFrames 0.9.79, Node.js 22+, Chrome, Python 3, and FFmpeg with `libvpx-vp9`. |
| Local authoring | Ollama 0.40.17 with `qwen3.5:4b` used for verification. |
| Social Studio Story review | [`b13ecea`](https://github.com/moisesaguiarjunior/social-studio/tree/b13ecea0d488afbd3f3e26abb6f3c4bbf4a9829c). The desktop package uses its own Fluvie 0.3.1 dependency. The bridge passes media and a job. |
| Export and adoption | The supplied commands target desktop developer environments. Flutter renders were exercised locally on macOS, and the quality workflow targets Ubuntu 24.04. |

The library's public import is `package:event_motion/event_motion.dart`. It provides `MotionTimeline`, `MotionFrame`, `MotionEvent`, `MotionStatus`, `MotionDiagram`, `MotionNode`, `MotionLink`, `MotionGraph`, and `MotionEventFeed`. `MotionGraph` accepts `cardSize`, a `statusLabel` callback for the default card, and a `nodeBuilder` for a different card. The example schemas, render commands, and bridges ship with the checkout and can evolve with their dependencies.

Event Motion uses the [MIT license](../LICENSE). The root package depends only on the Flutter SDK. The example uses Fluvie and Handcrafted under MIT, HyperFrames under Apache-2.0, GSAP under its [Standard License](https://gsap.com/standard-license/), and JetBrains Mono under SIL OFL 1.1. The HyperFrames tool reads the font files from the installed Fluvie package into a temporary render directory. FFmpeg, Ollama, and the optional local ComfyUI server are supplied separately. Source illustrations and committed example data were created for this repository. Generated media, model weights, fonts, and installed dependencies are excluded from the source tree.
