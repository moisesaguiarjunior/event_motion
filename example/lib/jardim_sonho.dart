import 'dart:math' as math;
import 'package:flutter/widgets.dart';
import 'package:fluvie/fluvie.dart' as video;
import 'package:handcrafted_flutter/handcrafted_flutter.dart';

const _cream = Color(0xFFF5E1BD);
const _pink = Color(0xFFE5A29E);
const _ink = Color(0xFF493A3C);

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
            final p = t * math.pi * 2;
            return ClipRect(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: 480,
                  height: 600,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Transform.translate(
                          offset: Offset(3 * math.sin(p), 1.5 * math.cos(p)),
                          child: Transform.scale(
                            scale: 1.025,
                            child: Image.asset(
                              'assets/jardim_sonho.png',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: CustomPaint(painter: _Atmosphere(p)),
                      ),
                      Positioned(
                        left: 121,
                        top: 320 + 2 * math.sin(p * 2),
                        child: _Bunny(p: p),
                      ),
                      Positioned(
                        left: 285 + 8 * math.sin(p),
                        top: 337 + 7 * math.cos(p * 2),
                        child: _Moth(p: p),
                      ),
                      Positioned.fill(
                        child: CustomPaint(painter: _Foreground(p)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ],
    ),
  ],
);

Path _oval(Size s) => Path()..addOval(Rect.fromLTWH(0, 0, s.width, s.height));

Widget _fabric(
  double w,
  double h,
  Color color, {
  CraftMaterial material = CraftMaterial.felt,
  Widget? child,
  int seed = 3,
}) => SizedBox(
  width: w,
  height: h,
  child: CraftSurface(
    material: material,
    color: color,
    seed: seed,
    strength: .75,
    outline: _oval,
    child: child ?? const SizedBox.expand(),
  ),
);

class _Bunny extends StatelessWidget {
  const _Bunny({required this.p});
  final double p;
  @override
  Widget build(BuildContext context) {
    // A short closed blink once per cycle; head, ears and body move independently.
    final blink = math.max(0.0, 1 - ((p - math.pi * 1.20).abs() / .16));
    return SizedBox(
      width: 175,
      height: 205,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: 22,
            top: 28,
            child: Transform.rotate(
              angle: -.35 + .08 * math.sin(p * 2),
              alignment: Alignment.bottomCenter,
              child: _fabric(
                39,
                100,
                _cream,
                child: Center(child: _fabric(20, 77, _pink, seed: 16)),
              ),
            ),
          ),
          Positioned(
            left: 72,
            top: 24,
            child: Transform.rotate(
              angle: .30 + .10 * math.sin(p * 2 + 1),
              alignment: Alignment.bottomCenter,
              child: _fabric(
                36,
                96,
                _cream,
                child: Center(child: _fabric(18, 73, _pink, seed: 19)),
              ),
            ),
          ),
          Positioned(
            left: 31,
            top: 116,
            child: Transform.scale(
              scaleY: 1 + .025 * math.sin(p * 2),
              alignment: Alignment.bottomCenter,
              child: _fabric(
                106,
                87,
                _cream,
                seed: 21,
                child: Center(
                  child: _fabric(60, 65, const Color(0xFFEBD5AF), seed: 22),
                ),
              ),
            ),
          ),
          Positioned(
            left: 23,
            top: 171,
            child: _fabric(42, 25, _cream, seed: 23),
          ),
          Positioned(
            left: 103,
            top: 173,
            child: _fabric(42, 25, _cream, seed: 24),
          ),
          Positioned(
            left: 23,
            top: 65,
            child: Transform.rotate(
              angle: .035 * math.sin(p),
              child: _fabric(
                126,
                104,
                _cream,
                seed: 25,
                child: CustomPaint(painter: _Face(blink)),
              ),
            ),
          ),
          Positioned(
            left: 45,
            top: 154,
            child: Transform.rotate(
              angle: .035 * math.sin(p),
              child: SizedBox(
                width: 82,
                height: 17,
                child: CraftSurface(
                  material: CraftMaterial.cotton,
                  color: const Color(0xFFAD6873),
                  strength: .65,
                  seed: 33,
                  outline: _scarfCollar,
                  child: CustomPaint(painter: _Scarf()),
                ),
              ),
            ),
          ),
          Positioned(
            left: 96,
            top: 168,
            child: Transform.rotate(
              angle: -.13 + .09 * math.sin(p),
              alignment: Alignment.topCenter,
              child: SizedBox(
                width: 23,
                height: 30,
                child: CraftSurface(
                  material: CraftMaterial.cotton,
                  color: const Color(0xFFBD7D86),
                  strength: .65,
                  seed: 34,
                  outline: _scarfTail,
                  child: CustomPaint(painter: _Fringe()),
                ),
              ),
            ),
          ),
          Positioned(
            left: 92,
            top: 161,
            child: _fabric(
              20,
              13,
              const Color(0xFFC98B91),
              material: CraftMaterial.cotton,
              seed: 35,
            ),
          ),
          Positioned(
            left: 42,
            top: 164,
            child: Transform.rotate(
              angle: -.3 + .08 * math.sin(p * 2),
              child: _fabric(22, 30, _cream, seed: 38),
            ),
          ),
          Positioned(
            left: 117,
            top: 158,
            child: Transform.rotate(
              alignment: Alignment.topCenter,
              angle: -.65 + .18 * math.sin(p),
              child: _fabric(21, 32, _cream, seed: 39),
            ),
          ),
        ],
      ),
    );
  }
}

class _Face extends CustomPainter {
  _Face(this.blink);
  final double blink;
  @override
  void paint(Canvas c, Size s) {
    final ink = Paint()..color = _ink;
    for (final x in [.34, .68]) {
      final center = Offset(s.width * x, s.height * .49);
      c.drawOval(
        Rect.fromCenter(center: center, width: 8, height: 11 * (1 - blink) + 1),
        ink,
      );
      if (blink < .5) {
        c.drawCircle(
          center + const Offset(-1.5, -2),
          1.4,
          Paint()..color = const Color(0xFFFFF5E6),
        );
      }
      c.drawOval(
        Rect.fromCenter(
          center: Offset(s.width * (x == .34 ? .18 : .82), s.height * .64),
          width: 17,
          height: 8,
        ),
        Paint()..color = _pink.withValues(alpha: .55),
      );
    }
    c.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * .51, s.height * .62),
        width: 8,
        height: 6,
      ),
      Paint()..color = const Color(0xFFC97979),
    );
    final mouth = Path()
      ..moveTo(s.width * .51, s.height * .66)
      ..quadraticBezierTo(
        s.width * .51,
        s.height * .73,
        s.width * .46,
        s.height * .72,
      )
      ..moveTo(s.width * .51, s.height * .66)
      ..quadraticBezierTo(
        s.width * .52,
        s.height * .73,
        s.width * .57,
        s.height * .72,
      );
    c.drawPath(
      mouth,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_Face old) => old.blink != blink;
}

class _Scarf extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final path = Path()
      ..moveTo(8, s.height * .65)
      ..lineTo(s.width - 8, s.height * .65);
    paintCraftStitch(
      c,
      path,
      thread: const Color(0xFFFFD2B0),
      pitch: 8,
      width: 1,
    );
  }

  @override
  bool shouldRepaint(_Scarf old) => false;
}

class _Moth extends StatelessWidget {
  const _Moth({required this.p});
  final double p;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 90,
    height: 88,
    child: Stack(
      children: [
        Positioned(
          left: 1,
          top: 25,
          child: Transform.rotate(
            angle: -.55 + .25 * math.sin(p * 3),
            alignment: Alignment.centerRight,
            child: _fabric(
              39,
              51,
              const Color(0xFFE2BD80),
              material: CraftMaterial.paper,
              seed: 51,
              child: const CustomPaint(painter: _Wing()),
            ),
          ),
        ),
        Positioned(
          left: 51,
          top: 25,
          child: Transform.rotate(
            angle: .55 - .25 * math.sin(p * 3),
            alignment: Alignment.centerLeft,
            child: _fabric(
              39,
              51,
              const Color(0xFFE2BD80),
              material: CraftMaterial.paper,
              seed: 52,
              child: const CustomPaint(painter: _Wing()),
            ),
          ),
        ),
        Positioned(
          left: 28,
          top: 21,
          child: _fabric(
            35,
            54,
            const Color(0xFFE9B856),
            seed: 53,
            child: const CustomPaint(painter: _MothFace()),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _Antennae(p))),
      ],
    ),
  );
}

class _Wing extends CustomPainter {
  const _Wing();
  @override
  void paint(Canvas c, Size s) {
    c.drawOval(
      Rect.fromCenter(
        center: Offset(s.width * .5, s.height * .5),
        width: s.width * .42,
        height: s.height * .38,
      ),
      Paint()..color = const Color(0xFFF8DF9E),
    );
    final seam = Path()
      ..moveTo(s.width * .25, s.height * .75)
      ..quadraticBezierTo(
        s.width * .5,
        s.height * .9,
        s.width * .75,
        s.height * .75,
      );
    paintCraftStitch(
      c,
      seam,
      thread: const Color(0xFFAF8054),
      pitch: 5,
      width: .8,
    );
  }

  @override
  bool shouldRepaint(_Wing old) => false;
}

class _MothFace extends CustomPainter {
  const _MothFace();
  @override
  void paint(Canvas c, Size s) {
    final paint = Paint()..color = _ink;
    c.drawCircle(Offset(s.width * .34, s.height * .35), 2.2, paint);
    c.drawCircle(Offset(s.width * .66, s.height * .35), 2.2, paint);
    final smile = Path()
      ..moveTo(s.width * .43, s.height * .46)
      ..quadraticBezierTo(
        s.width * .5,
        s.height * .54,
        s.width * .57,
        s.height * .46,
      );
    c.drawPath(
      smile,
      Paint()
        ..color = _ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_MothFace old) => false;
}

class _Antennae extends CustomPainter {
  _Antennae(this.p);
  final double p;
  @override
  void paint(Canvas c, Size s) {
    final line = Paint()
      ..color = const Color(0xFF8B623D)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    for (final sign in [-1, 1]) {
      final path = Path()
        ..moveTo(45, 25)
        ..quadraticBezierTo(
          45 + sign * 5,
          5,
          45 + sign * (13 + 2 * math.sin(p)),
          9,
        );
      c.drawPath(path, line);
    }
  }

  @override
  bool shouldRepaint(_Antennae old) => old.p != p;
}

class _Atmosphere extends CustomPainter {
  _Atmosphere(this.p);
  final double p;
  @override
  void paint(Canvas c, Size s) {
    for (final ground in [
      const Rect.fromLTWH(139, 508, 134, 13),
      const Rect.fromLTWH(288, 440, 80, 12),
    ]) {
      c.drawOval(
        ground,
        Paint()
          ..color = const Color(0x60312F25)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }
    // Translucent drifting cloud bands provide a separate moving background layer.
    for (var i = 0; i < 3; i++) {
      final x = 80.0 + i * 165 + 14 * math.sin(p + i);
      final y = 225.0 + i * 20;
      c.drawOval(
        Rect.fromCenter(center: Offset(x, y), width: 165, height: 22),
        Paint()
          ..color = const Color(0x165E94BD)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 14),
      );
    }
    final r = math.Random(931);
    for (var i = 0; i < 45; i++) {
      final x = 20 + r.nextDouble() * 440,
          y = 30 + r.nextDouble() * 500,
          phase = r.nextDouble() * 6.28;
      final pos = Offset(
        x + 5 * math.sin(p + phase),
        y + 6 * math.cos(p + phase),
      );
      final a = .25 + .5 * (.5 + .5 * math.sin(p * 2 + phase));
      c.drawCircle(
        pos,
        5,
        Paint()
          ..color = const Color(0xFFFFD77C).withValues(alpha: a * .22)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5),
      );
      c.drawCircle(
        pos,
        1.3,
        Paint()..color = const Color(0xFFFFDF91).withValues(alpha: a),
      );
    }
  }

  @override
  bool shouldRepaint(_Atmosphere old) => old.p != p;
}

class _Foreground extends CustomPainter {
  _Foreground(this.p);
  final double p;
  @override
  void paint(Canvas c, Size s) {
    // Moving foreground grasses overlap the characters and add depth.
    for (var i = 0; i < 7; i++) {
      final x = 32 + i * 68.0;
      final sway = 5 * math.sin(p + i * .8);
      final y = 560.0 + (i % 3) * 10;
      final stem = Path()
        ..moveTo(x, 610)
        ..quadraticBezierTo(x + sway, y + 15, x + sway * 1.6, y);
      c.drawPath(
        stem,
        Paint()
          ..color = const Color(0xFF607C52)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      final center = Offset(x + sway * 1.6, y);
      for (var j = 0; j < 5; j++) {
        final a = j * math.pi * 2 / 5;
        final petal = Path()
          ..addOval(
            Rect.fromCenter(
              center: center + Offset(math.cos(a) * 5, math.sin(a) * 5),
              width: 8,
              height: 9,
            ),
          );
        paintWatercolorSpread(
          c,
          petal,
          pigment: const Color(0xFFC8A5BC),
          paper: const Color(0xFFF2D7D2),
          progress: 1,
          seed: 100 + i * 5 + j,
          opacity: .85,
        );
      }
      c.drawCircle(center, 2.5, Paint()..color = const Color(0xFFEFC374));
    }
    final r = math.Random(51);
    for (var i = 0; i < 24; i++) {
      final x = i * 23.0 - 20,
          h = 20 + r.nextDouble() * 34,
          sway = 5 * math.sin(p + i * .7);
      final path = Path()
        ..moveTo(x, 600)
        ..quadraticBezierTo(x + sway, 600 - h * .6, x + sway * 1.6, 600 - h);
      c.drawPath(
        path,
        Paint()
          ..color = const Color(0xAA344D36)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.6
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_Foreground old) => old.p != p;
}

Path _scarfCollar(Size s) => Path()
  ..moveTo(0, 3)
  ..quadraticBezierTo(s.width * .5, 10, s.width, 0)
  ..lineTo(s.width - 2, s.height - 5)
  ..quadraticBezierTo(s.width * .5, s.height + 3, 2, s.height - 3)
  ..close();
Path _scarfTail(Size s) => Path()
  ..moveTo(3, 0)
  ..lineTo(s.width - 2, 0)
  ..quadraticBezierTo(s.width - 7, s.height * .5, s.width, s.height - 4)
  ..quadraticBezierTo(s.width * .5, s.height + 1, 0, s.height - 3)
  ..quadraticBezierTo(5, s.height * .5, 3, 0)
  ..close();

class _Fringe extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    for (var i = 0; i < 5; i++) {
      final x = 3 + i * 4.0;
      c.drawLine(
        Offset(x, s.height - 9),
        Offset(x + 1, s.height - 2),
        Paint()
          ..color = const Color(0xFFE9B7B5)
          ..strokeWidth = 1.3
          ..strokeCap = StrokeCap.round,
      );
    }
  }

  @override
  bool shouldRepaint(_Fringe old) => false;
}
