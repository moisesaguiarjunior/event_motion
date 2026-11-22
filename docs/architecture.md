# Architecture

## Go from an event to a frame

1. Create a `MotionTimeline` once from chronological `MotionEvent` values. Each event sets a node's state and may include a source ID and a feed message.
2. Call `timeline.at(elapsed)` once per output frame. Events take effect at their exact timestamp. At a tie, the last event for a node wins. Each directed link retains its own latest event, so two links can pulse toward the same node at the same time.
3. Pass the `MotionFrame` to the widgets that need it. A diagram uses declared card positions and connections. A feed reads the recent messages. Other widgets can read the status or progress directly.

The frame samples from an immutable history. A caller can seek backward or render an individual frame after mounting at any time. Effects use elapsed time, so their duration stays consistent across frame rates. Short sequences are the current target. Sampling walks the reached events, and the cost grows with the history.

`MotionDiagram` validates node IDs, normalized coordinates, and directed links when constructed. A link-triggering event pulses only a declared link with matching endpoints. Each layout uses a finite box supplied by Flutter. The caller chooses positions to fit the scene and can customize the node widget using `nodeBuilder`.

## Connect a renderer

The library renders Flutter widgets at a supplied time. Both examples use a [shared clock adapter](../example/lib/src/motion_clock.dart) that reads Fluvie's experimental `FrameBuilder` from a pinned revision and converts the scene-local frame to elapsed time. Fluvie handles scene transitions, media and output. Handcrafted materials can be composed inside a custom node or used as the scene's surface.

The [card sequence](../example/lib/card_sequence.dart) uses `statusOf` to show cards once their cue is reached and `progressSince` to move them between the focus area, the row of previous cards and the final mosaic. Layout and perspective stay with the composition. The same timeline API is enough to drive the cards and their painted previews.

Use HyperFrames for a scene authored in HTML or for a transparent effect. Render it locally before starting the Fluvie export. Place opaque clips with `Clip.file('scene.mp4')` or transparent VP9 clips with `Clip.file('overlay.webm')`. Match the frame rate and declare the clip's start in the Fluvie composition. The local desktop path has been checked with a one-second silent WebM over a Flutter background. A reusable adapter still needs coverage across clip starts, audio and output sizes. [HyperFrames transparent export](https://github.com/heygen-com/hyperframes/blob/main/docs/guides/rendering.mdx#transparent-video)

## Feed a local model into a template

The agent pipeline reads a [versioned JSON document](workflow-json.md). A plain Dart reader validates the fields, layout, references and event order. The Flutter adapter turns the validated data into a diagram and timeline. The local authoring command uses the same reader to check model output before rendering. The two card sequence renderers read a shared document for copy, color, and timing.
