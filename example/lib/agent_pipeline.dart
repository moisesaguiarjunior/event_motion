import 'package:event_motion/event_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:fluvie/fluvie.dart' as video;

final _diagram = MotionDiagram(
  nodes: const [
    MotionNode('brief', 'Brief', Offset(0.5, 0)),
    MotionNode('research', 'Research', Offset(0, 0.44)),
    MotionNode('compose', 'Compose', Offset(1, 0.44)),
    MotionNode('review', 'Review', Offset(0.5, 0.94)),
  ],
  links: const [
    MotionLink('brief', 'research'),
    MotionLink('brief', 'compose'),
    MotionLink('research', 'review'),
    MotionLink('compose', 'review'),
  ],
);

final _timeline = MotionTimeline(const [
  MotionEvent(
    at: Duration.zero,
    node: 'brief',
    status: MotionStatus.active,
    message: 'Brief received',
  ),
  MotionEvent(
    at: Duration(milliseconds: 500),
    node: 'brief',
    status: MotionStatus.complete,
  ),
  MotionEvent(
    at: Duration(milliseconds: 500),
    node: 'research',
    from: 'brief',
    status: MotionStatus.active,
    message: 'Gathering source notes',
  ),
  MotionEvent(
    at: Duration(milliseconds: 1050),
    node: 'compose',
    from: 'brief',
    status: MotionStatus.active,
    message: 'Assembling the visual',
  ),
  MotionEvent(
    at: Duration(milliseconds: 1625),
    node: 'research',
    status: MotionStatus.complete,
  ),
  MotionEvent(
    at: Duration(milliseconds: 2000),
    node: 'compose',
    status: MotionStatus.complete,
  ),
  MotionEvent(
    at: Duration(milliseconds: 2000),
    node: 'review',
    from: 'compose',
    status: MotionStatus.active,
    message: 'Checking the draft against the brief',
  ),
  MotionEvent(
    at: Duration(milliseconds: 2300),
    node: 'review',
    from: 'research',
    status: MotionStatus.active,
    message: 'Checking source notes',
  ),
  MotionEvent(
    at: Duration(milliseconds: 3000),
    node: 'review',
    status: MotionStatus.complete,
    message: 'Ready for human review',
  ),
]);

/// A 4:5 composition sharing one sampled frame across the diagram and the feed.
video.Video build() => video.Video(
  width: 480,
  height: 600,
  fps: 24,
  poster: const video.Time.seconds(2.5),
  scenes: [
    video.Scene(
      background: video.Background.color(const Color(0xFF101C2E)),
      duration: const video.Time.seconds(4),
      children: [
        Positioned.fill(
          // The example pins the Fluvie revision that exports this frame clock.
          // ignore: experimental_member_use
          child: video.FrameBuilder((clock) {
            final localFrame = clock.frame - clock.scope.startFrame;
            final elapsed = Duration(
              microseconds:
                  (localFrame * Duration.microsecondsPerSecond / clock.fps)
                      .round(),
            );
            return _Pipeline(frame: _timeline.at(elapsed));
          }),
        ),
      ],
    ),
  ],
);

class _Pipeline extends StatelessWidget {
  const _Pipeline({required this.frame});

  final MotionFrame frame;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'From brief to draft',
          style: TextStyle(
            color: Color(0xFFF1F6FF),
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'A simulated workflow with four agents',
          style: TextStyle(color: Color(0xFFA9BAD3), fontSize: 16),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: MotionGraph(diagram: _diagram, frame: frame),
        ),
        const SizedBox(height: 30),
        Container(height: 1, color: const Color(0xFF405370)),
        const SizedBox(height: 15),
        const Text(
          'Recent activity',
          style: TextStyle(color: Color(0xFF4DE2BA), fontSize: 14),
        ),
        const SizedBox(height: 9),
        SizedBox(
          height: 68,
          child: MotionEventFeed(
            frame: frame,
            style: const TextStyle(color: Color(0xFFE4EDFB), fontSize: 14),
          ),
        ),
      ],
    ),
  );
}
