# Event Motion

Flutter widgets for showing what happened and when. Describe the events once, then use the same point in time to draw a diagram, a feed, or any other Flutter widget.

## Use it

Add `event_motion` as a [local path dependency](https://dart.dev/tools/pub/dependencies#path-packages) while the package is in development. Import `package:event_motion/event_motion.dart` alongside `package:flutter/widgets.dart`.

```dart
final diagram = MotionDiagram(
  nodes: const [
    MotionNode('draft', 'Draft', Offset(0, 0.5)),
    MotionNode('review', 'Review', Offset(1, 0.5)),
  ],
  links: const [MotionLink('draft', 'review')],
);

final timeline = MotionTimeline(const [
  MotionEvent(
    at: Duration(seconds: 1),
    from: 'draft',
    node: 'review',
    status: MotionStatus.active,
    message: 'Review started',
  ),
]);

final frame = timeline.at(const Duration(milliseconds: 1300));

final graph = SizedBox(
  width: 360,
  height: 160,
  child: MotionGraph(diagram: diagram, frame: frame),
);
final feed = MotionEventFeed(frame: frame);
```

Pass the desired elapsed time from your app or renderer. At 1.3 seconds, the review card is running and a pulse is moving along the connection. Sampling 0.5 seconds restores the earlier state. Use `frame.statusOf(id)` and `frame.progressSince(start, duration)` to drive a card, caption, or custom painter on the same clock. Use `nodeBuilder` to supply your own widget for each node.

## Render the example

Run from the repository root with Flutter 3.44 or newer and FFmpeg available on `PATH`.

```sh
bash tool/render_example.sh
```

The [four-agent example](example/lib/agent_pipeline.dart) turns a fictional workflow into a four-second video at 480 × 600 and 24 fps. The command writes `agent_pipeline.mp4` and `agent_pipeline.png` to `example/build/agent_pipeline/`. The example pins a Fluvie revision and uses its frame clock and export pipeline. The library itself depends only on Flutter.

## Develop

```sh
flutter pub get
flutter analyze
flutter test
```

The [architecture notes](docs/architecture.md) describe timing, layout, and the external clip boundary. The [roadmap](docs/roadmap.md) tracks the remaining work for a local post workflow.
