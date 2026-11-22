import 'dart:ui' show lerpDouble;

import 'package:event_motion/event_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:fluvie/fluvie.dart' as video;

import 'src/motion_clock.dart';

const _ink = Color(0xFF202C2F);
const _paper = Color(0xFFF4EFE6);
const _accent = Color(0xFFA73524);
const _mosaic = 'mosaic';

const _cards = [
  _Card(
    _Step.outline,
    'Outline',
    'Give the idea a clear sequence.',
    _accent,
    0,
  ),
  _Card(
    _Step.layout,
    'Layout',
    'Make each point easy to scan.',
    Color(0xFF306545),
    1300,
  ),
  _Card(
    _Step.motion,
    'Motion',
    'Show what changes over time.',
    Color(0xFF54418D),
    2600,
  ),
  _Card(
    _Step.export,
    'Export',
    'Pick a frame and export the clip.',
    Color(0xFF2D5874),
    3900,
  ),
];

final _timeline = MotionTimeline([
  for (final card in _cards)
    MotionEvent(
      at: Duration(milliseconds: card.startMs),
      node: card.id,
      status: MotionStatus.active,
    ),
  const MotionEvent(
    at: Duration(milliseconds: 5350),
    node: _mosaic,
    status: MotionStatus.complete,
  ),
]);

/// A 4:5 composition with a focused card, a row of previous steps and a mosaic.
video.Video build() => video.Video(
  width: 480,
  height: 600,
  fps: 24,
  poster: const video.Time.seconds(6.5),
  scenes: [
    video.Scene(
      duration: const video.Time.seconds(7),
      background: video.Background.color(_paper),
      children: [
        Positioned.fill(
          child: atMotionTime(_timeline, (frame) => _Sequence(frame: frame)),
        ),
      ],
    ),
  ],
);

class _Sequence extends StatelessWidget {
  const _Sequence({required this.frame});

  final MotionFrame frame;

  @override
  Widget build(BuildContext context) {
    final next = _cards.indexWhere((card) => frame.latestFor(card.id) == null);
    final status = switch (next) {
      >= 0 => 'Up next  ${_cards[next].title}',
      _ when frame.latestFor(_mosaic) != null => 'Draft ready for review',
      _ => 'Preparing the final draft',
    };
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 41, 30, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'From idea to post',
            style: TextStyle(
              color: _ink,
              fontSize: 35,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Four steps to a visual draft',
            style: TextStyle(color: _ink, fontSize: 16),
          ),
          const SizedBox(height: 25),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = constraints.biggest;
                final mosaic = _progress(_mosaic, 620);
                return Stack(
                  children: [
                    for (final (index, card) in _cards.indexed)
                      if (frame.statusOf(card.id) == MotionStatus.active)
                        _place(card, index, size, mosaic),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Container(width: 24, height: 2, color: _accent),
              const SizedBox(width: 10),
              Text(status, style: const TextStyle(color: _ink, fontSize: 13)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _place(_Card card, int index, Size stage, double mosaic) {
    final entered = _progress(card.id, 420);
    final dock = index + 1 < _cards.length
        ? _progress(_cards[index + 1].id, 480)
        : 0.0;
    final focused = Rect.fromLTWH(
      8,
      14 + 24 * (1 - entered),
      stage.width - 16,
      269,
    );
    final railWidth = (stage.width - 24) / 4;
    final rail = Rect.fromLTWH(
      index * (railWidth + 8),
      stage.height - 79,
      railWidth,
      64,
    );
    final gridWidth = (stage.width - 12) / 2;
    final gridHeight = (stage.height - 30) / 2;
    final slot = Rect.fromLTWH(
      (index % 2) * (gridWidth + 12),
      8 + (index ~/ 2) * (gridHeight + 12),
      gridWidth,
      gridHeight,
    );
    final rect = Rect.lerp(Rect.lerp(focused, rail, dock), slot, mosaic)!;
    final detail = 1 - dock * (1 - mosaic);

    return Positioned.fromRect(
      key: ValueKey(card.id),
      rect: rect,
      child: Opacity(
        opacity: entered,
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(0.23 * (1 - entered)),
          child: _CardFace(
            card: card,
            detail: detail,
            reveal: _progress(card.id, 790),
          ),
        ),
      ),
    );
  }

  double _progress(String id, int milliseconds) {
    final cue = frame.latestFor(id);
    if (cue == null) return 0;
    return Curves.easeOutCubic.transform(
      frame.progressSince(cue.at, Duration(milliseconds: milliseconds)),
    );
  }
}

enum _Step { outline, layout, motion, export }

class _Card {
  const _Card(this.step, this.title, this.caption, this.color, this.startMs);

  String get id => step.name;

  final _Step step;
  final String title;
  final String caption;
  final Color color;
  final int startMs;
}

class _CardFace extends StatelessWidget {
  const _CardFace({
    required this.card,
    required this.detail,
    required this.reveal,
  });

  final _Card card;
  final double detail;
  final double reveal;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final width = constraints.maxWidth;
      final large = ((width - 200) / 200).clamp(0.0, 1.0);
      final inset = lerpDouble(8, 19, detail)!;
      return DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: card.color.withValues(alpha: 0.46)),
          borderRadius: BorderRadius.circular(lerpDouble(9, 16, detail)!),
          color: const Color(0xFFFFFBF4),
          boxShadow: [
            BoxShadow(
              color: _ink.withValues(alpha: 0.10 * detail),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(inset),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card.title,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: TextStyle(
                  color: card.color,
                  fontSize: lerpDouble(12, lerpDouble(21, 32, large), detail),
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (detail > 0.6)
                Text(
                  card.caption,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _ink,
                    fontSize: lerpDouble(14, 16, large),
                    height: 1.15,
                  ),
                ),
              const SizedBox(height: 5),
              Expanded(
                child: CustomPaint(
                  size: Size.infinite,
                  painter: _Preview(card: card, reveal: reveal),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _Preview extends CustomPainter {
  const _Preview({required this.card, required this.reveal});

  final _Card card;
  final double reveal;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final panel = RRect.fromRectAndRadius(
      Offset.zero & size,
      const Radius.circular(7),
    );
    canvas.drawRRect(
      panel,
      Paint()..color = card.color.withValues(alpha: 0.08),
    );
    final ink = Paint()
      ..color = card.color
      ..strokeCap = StrokeCap.round
      ..strokeWidth = (size.height * 0.05).clamp(1, 5);
    Offset at(double x, double y) => Offset(size.width * x, size.height * y);

    switch (card.step) {
      case _Step.outline:
        for (final (row, length) in [0.58, 0.44, 0.52].indexed) {
          final y = 0.29 + row * 0.21;
          canvas.drawCircle(at(0.18, y), ink.strokeWidth / 2, ink);
          canvas.drawLine(at(0.26, y), at(0.26 + length * reveal, y), ink);
        }
      case _Step.layout:
        for (var index = 0; index < 4; index++) {
          final x = 0.21 + (index % 2) * 0.31;
          final y = 0.22 + (index ~/ 2) * 0.33;
          final fill = Paint()
            ..color = card.color.withValues(
              alpha: reveal * (0.92 - 0.17 * index),
            );
          canvas.drawRRect(
            RRect.fromRectAndRadius(
              Rect.fromPoints(at(x, y), at(x + 0.26, y + 0.25)),
              const Radius.circular(3),
            ),
            fill,
          );
        }
      case _Step.motion:
        final start = at(0.19, 0.68);
        final firstControl = at(0.48, 0.68);
        final secondControl = at(0.54, 0.32);
        final end = at(0.82, 0.32);
        final track = Path()
          ..moveTo(start.dx, start.dy)
          ..cubicTo(
            firstControl.dx,
            firstControl.dy,
            secondControl.dx,
            secondControl.dy,
            end.dx,
            end.dy,
          );
        final metric = track.computeMetrics().first;
        final tip = metric
            .getTangentForOffset(metric.length * reveal)!
            .position;
        canvas.drawPath(track, ink..style = PaintingStyle.stroke);
        canvas.drawCircle(
          tip,
          ink.strokeWidth * 1.45,
          ink..style = PaintingStyle.fill,
        );
      case _Step.export:
        final area = Rect.fromPoints(at(0.25, 0.2), at(0.75, 0.78));
        canvas.drawRRect(
          RRect.fromRectAndRadius(area, const Radius.circular(5)),
          ink..style = PaintingStyle.stroke,
        );
        canvas.drawLine(at(0.31, 0.67), at(0.31 + 0.38 * reveal, 0.67), ink);
        final play = Path()
          ..addPolygon([at(0.47, 0.36), at(0.47, 0.54), at(0.56, 0.45)], true);
        canvas.drawPath(play, ink..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(_Preview oldDelegate) =>
      card != oldDelegate.card || reveal != oldDelegate.reveal;
}
