import 'package:flutter/widgets.dart';
import 'package:fluvie/fluvie.dart' as video;
import 'package:handcrafted_flutter/handcrafted_flutter.dart';

const _ink = Color(0xFF202C2F);
const _paper = Color(0xFFF4EFE6);
const _green = Color(0xFF3E7658);

typedef _Timing = ({String label, int seconds, int low, int high});

const _timings = <_Timing>[
  (label: 'Prepare', seconds: 24, low: 18, high: 31),
  (label: 'Compose', seconds: 59, low: 51, high: 68),
  (label: 'Review', seconds: 38, low: 30, high: 45),
  (label: 'Export', seconds: 12, low: 9, high: 17),
];

/// An editorial comparison on a 1080 × 1350 canvas.
video.Video build({CraftMaterial? material}) => video.Video(
  width: 1080,
  height: 1350,
  fps: 24,
  poster: const video.Time.frames(0),
  scenes: [
    video.Scene(
      duration: const video.Time.frames(1),
      children: [
        Positioned.fill(
          child: FittedBox(
            child: SizedBox(
              width: 480,
              height: 600,
              child: material == null
                  ? const ColoredBox(color: _paper, child: _Article())
                  : CraftSurface(
                      material: material,
                      color: _paper,
                      strength: 0.55,
                      seed: 19,
                      child: const _Article(),
                    ),
            ),
          ),
        ),
      ],
    ),
  ],
);

class _Article extends StatelessWidget {
  const _Article();

  @override
  Widget build(BuildContext context) {
    final largest = _timings
        .map((run) => run.high)
        .reduce((a, b) => a > b ? a : b);
    final scaleMaximum = (largest / 10).ceil() * 10;
    return Padding(
      padding: const EdgeInsets.fromLTRB(30, 38, 30, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How long does\na draft take?',
            style: TextStyle(
              color: _ink,
              fontSize: 36,
              fontWeight: FontWeight.bold,
              height: 1.04,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            'Time per step, in seconds',
            style: TextStyle(color: _ink, fontSize: 18),
          ),
          const SizedBox(height: 30),
          for (final timing in _timings) ...[
            _TimingRow(timing: timing, maximum: scaleMaximum),
            const SizedBox(height: 16),
          ],
          const Spacer(),
          Container(color: _ink, height: 1),
          const SizedBox(height: 13),
          const Text(
            'Whiskers show the example ranges.',
            style: TextStyle(color: _ink, fontSize: 14),
          ),
          const SizedBox(height: 6),
          const Text(
            'Source  ·  Event Motion synthetic fixture',
            style: TextStyle(color: _ink, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _TimingRow extends StatelessWidget {
  const _TimingRow({required this.timing, required this.maximum});

  final _Timing timing;
  final int maximum;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        children: [
          Text(
            timing.label,
            style: const TextStyle(
              color: _ink,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Text(
            '${timing.low}–${timing.high} s',
            style: const TextStyle(color: _ink, fontSize: 14),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 72,
            child: Text(
              '${timing.seconds} s',
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: _ink,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 6),
      SizedBox(
        height: 21,
        width: double.infinity,
        child: CustomPaint(
          painter: _IntervalBar(timing: timing, maximum: maximum),
        ),
      ),
    ],
  );
}

class _IntervalBar extends CustomPainter {
  const _IntervalBar({required this.timing, required this.maximum});

  final _Timing timing;
  final int maximum;

  @override
  void paint(Canvas canvas, Size size) {
    final track = Rect.fromLTWH(0, 3, size.width, size.height - 6);
    const radius = Radius.circular(4);
    canvas.drawRRect(
      RRect.fromRectAndRadius(track, radius),
      Paint()..color = const Color(0xFFDADFD2),
    );
    double x(int value) => size.width * value / maximum;
    final bar = Rect.fromLTRB(
      track.left,
      track.top,
      x(timing.seconds),
      track.bottom,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(bar, radius),
      Paint()..color = _green,
    );
    final whisker = Paint()
      ..color = _ink
      ..strokeWidth = 1.6;
    final baseline = size.height / 2;
    final low = x(timing.low);
    final high = x(timing.high);
    canvas.drawLine(Offset(low, baseline), Offset(high, baseline), whisker);
    for (final end in [low, high]) {
      canvas.drawLine(Offset(end, 0), Offset(end, size.height), whisker);
    }
  }

  @override
  bool shouldRepaint(_IntervalBar previous) =>
      previous.timing != timing || previous.maximum != maximum;
}
