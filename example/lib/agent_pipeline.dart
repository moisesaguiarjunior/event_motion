import 'dart:math' as math;

import 'package:event_motion/event_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:fluvie/fluvie.dart' as video;

import 'src/motion_clock.dart';
import 'src/workflow_spec.dart';

/// A 4:5 composition sharing one sampled frame across the diagram and the feed.
video.Video build(WorkflowSpec spec, {bool fullSize = false, String? audio}) =>
    video.Video(
      width: fullSize ? 1080 : 480,
      height: fullSize ? 1350 : 600,
      fps: WorkflowSpec.fps,
      poster: video.Time.frames(spec.coverFrame),
      audio: [if (audio != null) video.Audio.music(audio)],
      scenes: [
        video.Scene(
          background: video.Background.color(const Color(0xFF101C2E)),
          duration: video.Time.frames(spec.frameCount),
          children: [
            Positioned.fill(
              child: atMotionTime(spec.timeline, (frame) {
                final panel = _Pipeline(spec: spec, frame: frame);
                return fullSize
                    ? FittedBox(
                        child: SizedBox(width: 480, height: 600, child: panel),
                      )
                    : panel;
              }),
            ),
          ],
        ),
      ],
    );

class _Pipeline extends StatelessWidget {
  const _Pipeline({required this.spec, required this.frame});

  final WorkflowSpec spec;

  final MotionFrame frame;

  static String _statusPt(MotionStatus status) => switch (status) {
    MotionStatus.idle => 'Aguardando',
    MotionStatus.active => 'Em execução',
    MotionStatus.complete => 'Concluído',
    MotionStatus.failed => 'Falhou',
  };

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final count = spec.diagram.nodes.length;
              final height = (constraints.maxHeight - (count - 1) * 12) / count;
              return MotionGraph(
                diagram: spec.diagram,
                frame: frame,
                statusLabel: spec.document.locale == 'pt-BR' ? _statusPt : null,
                cardSize: spec.document.layout == 'vertical'
                    ? Size(212, math.min(60, height))
                    : null,
              );
            },
          ),
        ),
        const SizedBox(height: 30),
        Container(height: 1, color: const Color(0xFF405370)),
        const SizedBox(height: 15),
        Text(
          spec.document.locale == 'pt-BR'
              ? 'Atividade recente'
              : 'Recent activity',
          style: const TextStyle(color: Color(0xFF4DE2BA), fontSize: 14),
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
