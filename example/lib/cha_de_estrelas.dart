import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:fluvie/fluvie.dart' as video;
import 'package:handcrafted_flutter/handcrafted_flutter.dart';

/// A storybook illustration with a slow camera and independently animated light.
video.Video build() => video.Video(
  width: 720,
  height: 900,
  fps: 24,
  poster: const video.Time.frames(96),
  scenes: [
    video.Scene(
      duration: const video.Time.frames(240),
      children: [
        Positioned.fill(
          // ignore: experimental_member_use
          child: video.FrameBuilder((clock) {
            final t = (clock.frame - clock.scope.startFrame) / 240;
            final eased = .5 - .5 * math.cos(t * 2 * math.pi);
            return ClipRect(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Transform.scale(
                    scale: 1.025 + .035 * eased,
                    child: Image.asset(
                      'assets/cha_de_estrelas.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                  CustomPaint(painter: _LightPainter(t)),
                ],
              ),
            );
          }),
        ),
      ],
    ),
  ],
);

class _LightPainter extends CustomPainter {
  _LightPainter(this.t);
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 720, size.height / 900);
    final rng = math.Random(130);
    // Fireflies follow small closed paths, at different rates and depths.
    for (var i = 0; i < 42; i++) {
      final x = 28 + rng.nextDouble() * 664;
      final y = 180 + rng.nextDouble() * 640;
      final phase = rng.nextDouble() * 2 * math.pi;
      final a = t * 2 * math.pi * (i % 2 + 1) + phase;
      final r = 1 + rng.nextDouble() * 2.1;
      final pos = Offset(x + 7 * math.sin(a), y + 10 * math.cos(a));
      final alpha = (.25 + .48 * (.5 + .5 * math.sin(a))).clamp(0.0, 1.0);
      canvas.drawCircle(
        pos,
        r * 4,
        Paint()
          ..color = const Color(0xFFFFCE77).withValues(alpha: alpha * .18)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 7),
      );
      canvas.drawCircle(
        pos,
        r,
        Paint()..color = const Color(0xFFFFE5A0).withValues(alpha: alpha),
      );
    }
    // Handcrafted thread stitches form a tiny, almost hidden constellation.
    final seam = Path()
      ..moveTo(489, 223)
      ..quadraticBezierTo(527, 202, 558, 164);
    canvas.saveLayer(
      const Rect.fromLTWH(470, 145, 110, 95),
      Paint()..color = const Color(0x44FFFFFF),
    );
    paintCraftStitch(
      canvas,
      seam,
      thread: const Color(0xFFFFD889),
      pitch: 12,
      width: 1,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_LightPainter oldDelegate) => oldDelegate.t != t;
}
