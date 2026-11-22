# Event Motion

Flutter widgets for showing what happened and when. Describe the events once, then use the same point in time to draw a diagram, a feed, or any other Flutter widget.

## Use it

Add `event_motion` as a [Git or local path dependency](https://dart.dev/tools/pub/dependencies) in a Flutter app. Import `package:event_motion/event_motion.dart` alongside `package:flutter/widgets.dart`. See [compatibility and API scope](https://github.com/moisesaguiarjunior/event_motion/blob/main/docs/compatibility.md).

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

## Render the examples

Run from the repository root with Flutter 3.44 or newer and FFmpeg available on `PATH`.

```sh
bash tool/render_example.sh
bash tool/render_example.sh card_sequence
bash tool/render_example.sh activation
bash tool/render_example.sh comparison paper
```

The first command renders both examples. Pass `agent_pipeline` or `card_sequence` to render one. Each writes an MP4 and a PNG under `example/build/<name>/` at 480 × 600 and 24 fps.

- [Agent pipeline](example/lib/agent_pipeline.dart) shows state changes, pulses and an activity feed over four seconds.
- [Card sequence](example/lib/card_sequence.dart) brings each card into focus, then arranges the four cards in a mosaic over seven seconds.

The activation example adds Portuguese captions and a 1080 × 1350 export. Pass a local `audio.wav` as its second argument to include sound. The comparison exports a PNG at the same size with a common bar scale, ranges, and source notes. Choose `paper`, `linen`, or the default flat surface. The examples use pinned Fluvie and Handcrafted revisions. The library itself depends only on Flutter.

## Make an editorial post

```sh
bash tool/render_example.sh editorial_catalog
bash tool/render_example.sh character_poster
bash tool/render_example.sh character_dashboard
```

The grid highlights eight to twelve illustrated notes in order and exports the complete grid as a cover. The character poster and animated dashboard share one team file. The dashboard shows signal paths, contextual callouts, an activity feed, and completion. All three use a 1080 × 1350 canvas. See the [input templates, local authoring command, and visual references](docs/editorial-styles.md).

## Render a workflow from JSON

Copy the [example input](example/fixtures/agent_pipeline.json) and edit its title, nodes, links and timed events. Then render it with the same command as the demo.

```sh
bash tool/render_example.sh agent_pipeline ./workflow.json
```

The command writes `workflow.mp4` and `workflow.png` to `example/build/workflow/` or to a directory you supply as the last argument. Invalid input fails with the path to the field to fix. See the [workflow contract](https://github.com/moisesaguiarjunior/event_motion/blob/main/docs/workflow-json.md) and the [JSON Schema](example/spec/workflow.v1.schema.json).

## Generate a workflow with a local model

With Ollama running and `qwen3.5:4b` installed, run the authoring command from the checkout.

```sh
bash tool/author_workflow.sh example/fixtures/briefs/newsletter.txt example/build/my-post
```

The command writes an editable JSON spec, a video, and a cover alongside one another. Supply a workflow JSON as a third argument to keep a supplied event log intact. See [local authoring](https://github.com/moisesaguiarjunior/event_motion/blob/main/docs/local-authoring.md) and [the HyperFrames and Social Studio examples](https://github.com/moisesaguiarjunior/event_motion/blob/main/docs/integrations.md).

## Develop

```sh
flutter pub get
flutter analyze
flutter test
(cd example && flutter test)
```

See the [architecture](https://github.com/moisesaguiarjunior/event_motion/blob/main/docs/architecture.md), [roadmap](https://github.com/moisesaguiarjunior/event_motion/blob/main/docs/roadmap.md), and [verification results](https://github.com/moisesaguiarjunior/event_motion/blob/main/docs/verification.md).
