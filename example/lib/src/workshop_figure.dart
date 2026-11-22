import 'dart:math' as math;

import 'package:flutter/widgets.dart';
import 'package:handcrafted_flutter/handcrafted_flutter.dart';

import 'team_document.dart';

Color workshopColor(WorkshopFigure figure) => switch (figure) {
  WorkshopFigure.lantern => const Color(0xFFDDAA53),
  WorkshopFigure.fold => const Color(0xFF789CC8),
  WorkshopFigure.seed => const Color(0xFF86AA72),
  WorkshopFigure.ticket => const Color(0xFFCF7969),
  WorkshopFigure.seal => const Color(0xFFA98BC1),
};

Color workshopMemberColor(WorkshopMember member) =>
    member.color == null ? workshopColor(member.figure) : Color(member.color!);

final _outlines = {
  for (final figure in WorkshopFigure.values)
    figure: (Size size) => _shape(figure, size),
};

/// A cut-paper character shared by the still poster and the timed dashboard.
class WorkshopCharacter extends StatelessWidget {
  const WorkshopCharacter({
    super.key,
    required this.figure,
    required this.color,
    this.blink = 0,
  });

  final WorkshopFigure figure;
  final Color color;
  final double blink;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _Shadow(figure, color),
      child: CraftSurface(
        color: color,
        material: switch (figure) {
          WorkshopFigure.lantern || WorkshopFigure.fold => CraftMaterial.paper,
          WorkshopFigure.seed => CraftMaterial.felt,
          WorkshopFigure.ticket => CraftMaterial.linen,
          WorkshopFigure.seal => CraftMaterial.cotton,
        },
        strength: 0.52,
        seed: 41 + figure.index * 11,
        outline: _outlines[figure],
        child: CustomPaint(
          size: Size.infinite,
          painter: _Features(figure, color, blink),
        ),
      ),
    );
  }
}

Path _shape(WorkshopFigure figure, Size size) {
  final p = Path();
  switch (figure) {
    case WorkshopFigure.lantern:
      p
        ..moveTo(.15, .43)
        ..lineTo(.32, .24)
        ..lineTo(.34, .13)
        ..quadraticBezierTo(.36, .07, .43, .075)
        ..lineTo(.57, .075)
        ..quadraticBezierTo(.64, .07, .66, .13)
        ..lineTo(.68, .24)
        ..lineTo(.85, .43)
        ..quadraticBezierTo(.89, .49, .88, .57)
        ..lineTo(.84, .79)
        ..quadraticBezierTo(.82, .87, .73, .89)
        ..lineTo(.27, .89)
        ..quadraticBezierTo(.18, .87, .16, .79)
        ..lineTo(.12, .57)
        ..quadraticBezierTo(.11, .49, .15, .43)
        ..close();
    case WorkshopFigure.fold:
      p
        ..moveTo(.16, .24)
        ..quadraticBezierTo(.15, .20, .20, .18)
        ..lineTo(.61, .09)
        ..quadraticBezierTo(.65, .08, .69, .12)
        ..lineTo(.88, .33)
        ..quadraticBezierTo(.91, .36, .90, .41)
        ..lineTo(.78, .84)
        ..quadraticBezierTo(.77, .90, .70, .90)
        ..lineTo(.26, .86)
        ..quadraticBezierTo(.21, .86, .20, .79)
        ..close();
    case WorkshopFigure.seed:
      p
        ..moveTo(.81, .13)
        ..cubicTo(.48, .08, .16, .30, .13, .62)
        ..cubicTo(.09, .84, .28, .94, .50, .90)
        ..cubicTo(.84, .84, .91, .50, .81, .13)
        ..close();
    case WorkshopFigure.ticket:
      p
        ..moveTo(.19, .20)
        ..lineTo(.81, .20)
        ..quadraticBezierTo(.89, .20, .89, .28)
        ..lineTo(.89, .43)
        ..cubicTo(.77, .42, .77, .61, .89, .60)
        ..lineTo(.89, .72)
        ..quadraticBezierTo(.89, .80, .81, .80)
        ..lineTo(.19, .80)
        ..quadraticBezierTo(.11, .80, .11, .72)
        ..lineTo(.11, .60)
        ..cubicTo(.23, .61, .23, .42, .11, .43)
        ..lineTo(.11, .28)
        ..quadraticBezierTo(.11, .20, .19, .20)
        ..close();
    case WorkshopFigure.seal:
      for (var i = 0; i <= 144; i++) {
        final angle = math.pi * i / 72;
        final radius = .369 + .027 * math.cos(9 * angle);
        final x = .50 + radius * math.cos(angle);
        final y = .50 + radius * math.sin(angle);
        if (i == 0) {
          p.moveTo(x, y);
        } else {
          p.lineTo(x, y);
        }
      }
      p.close();
  }
  return p.transform(
    Matrix4.diagonal3Values(size.width, size.height, 1).storage,
  );
}

class _Shadow extends CustomPainter {
  const _Shadow(this.figure, this.color);

  final WorkshopFigure figure;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final outline = _shape(figure, size).shift(Offset(0, size.height * .043));
    canvas.drawShadow(
      outline,
      const Color(0x770E221F),
      size.height * .041,
      false,
    );
    final edge = Color.lerp(color, const Color(0xFF142C2A), .29)!;
    canvas.drawPath(outline, Paint()..color = edge);
  }

  @override
  bool shouldRepaint(_Shadow previous) =>
      previous.figure != figure || previous.color != color;
}

class _Features extends CustomPainter {
  const _Features(this.figure, this.color, this.blink);

  final WorkshopFigure figure;
  final Color color;
  final double blink;

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width, size.height);
    final ink = Paint()
      ..color = color.computeLuminance() < .16
          ? const Color(0xFFFCF3E1)
          : const Color(0xFF1A3530)
      ..strokeWidth = .017
      ..strokeCap = StrokeCap.round;
    final facet = Paint()..color = const Color(0x47FFF4DB);
    final seam = Paint()
      ..color = Color.lerp(color, const Color(0xFF172F29), .38)!
      ..strokeWidth = .012
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    switch (figure) {
      case WorkshopFigure.lantern:
        canvas.drawPath(
          Path()
            ..moveTo(.13, .44)
            ..lineTo(.32, .24)
            ..lineTo(.68, .24)
            ..lineTo(.87, .44)
            ..close(),
          facet,
        );
        canvas.drawLine(const Offset(.31, .27), const Offset(.69, .27), seam);
        canvas.drawLine(
          const Offset(.42, .16),
          const Offset(.58, .16),
          ink..strokeWidth = .022,
        );
      case WorkshopFigure.fold:
        canvas.drawPath(
          Path()
            ..moveTo(.61, .09)
            ..lineTo(.89, .34)
            ..lineTo(.59, .43)
            ..close(),
          facet,
        );
        canvas.drawPath(
          Path()
            ..moveTo(.60, .12)
            ..lineTo(.59, .43)
            ..lineTo(.89, .34),
          seam,
        );
      case WorkshopFigure.seed:
        canvas.drawPath(
          Path()
            ..moveTo(.80, .14)
            ..quadraticBezierTo(.63, .40, .48, .48)
            ..quadraticBezierTo(.26, .59, .20, .76)
            ..quadraticBezierTo(.22, .49, .51, .41)
            ..close(),
          facet,
        );
      case WorkshopFigure.ticket:
        for (final y in [.30, .38, .46, .54, .62, .70]) {
          canvas.drawLine(Offset(.27, y), Offset(.27, y + .027), seam);
        }
        canvas.drawCircle(const Offset(.73, .33), .046, facet);
      case WorkshopFigure.seal:
        canvas.drawCircle(const Offset(.50, .50), .301, seam);
        canvas.drawCircle(
          const Offset(.50, .50),
          .263,
          Paint()..color = const Color(0x36FFF4DB),
        );
    }

    final faceY = switch (figure) {
      WorkshopFigure.lantern => .59,
      WorkshopFigure.fold => .59,
      WorkshopFigure.seed => .63,
      WorkshopFigure.ticket || WorkshopFigure.seal => .49,
    };
    final faceX = figure == WorkshopFigure.ticket ? .55 : .51;
    final eyeHeight = .072 - .052 * blink;
    for (final x in [faceX - .085, faceX + .085]) {
      canvas.drawOval(
        Rect.fromCenter(
          center: Offset(x, faceY),
          width: .031,
          height: eyeHeight,
        ),
        ink,
      );
    }
    canvas.drawPath(
      Path()
        ..moveTo(faceX - .046, faceY + .075)
        ..quadraticBezierTo(faceX, faceY + .133, faceX + .050, faceY + .073),
      ink
        ..strokeWidth = .018
        ..style = PaintingStyle.stroke,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Features previous) =>
      previous.figure != figure ||
      previous.color != color ||
      previous.blink != blink;
}
