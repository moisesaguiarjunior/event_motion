import 'package:event_motion/event_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:fluvie/fluvie.dart' as video;

import 'src/motion_clock.dart';
import 'src/workflow_spec.dart';

/// A 4:5 composition sharing one sampled frame across the diagram and the feed.
video.Video build(WorkflowSpec spec) => video.Video(
  width: 480,
  height: 600,
  fps: WorkflowSpec.fps,
  poster: video.Time.frames(spec.coverFrame),
  scenes: [
    video.Scene(
      background: video.Background.color(const Color(0xFF101C2E)),
      duration: video.Time.frames(spec.frameCount),
      children: [
        Positioned.fill(
          child: atMotionTime(
            spec.timeline,
            (frame) => _Pipeline(spec: spec, frame: frame),
          ),
        ),
      ],
    ),
  ],
);

class _Pipeline extends StatelessWidget {
  const _Pipeline({required this.spec, required this.frame});

  final WorkflowSpec spec;

  final MotionFrame frame;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(32, 36, 32, 32),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          spec.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFFF1F6FF),
            fontSize: 36,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (spec.subtitle case final subtitle?) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Color(0xFFA9BAD3), fontSize: 16),
          ),
        ],
        const SizedBox(height: 32),
        Expanded(
          child: MotionGraph(diagram: spec.diagram, frame: frame),
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
