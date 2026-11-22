import 'dart:math' as math;

import 'package:event_motion/event_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:fluvie/fluvie.dart' as video;
import 'package:handcrafted_flutter/handcrafted_flutter.dart';

import 'src/motion_clock.dart';
import 'src/team_document.dart';
import 'src/workshop_figure.dart';

const _ink = Color(0xFF17312D);
const _paper = Color(0xFFF2E7D0);
const _cream = Color(0xFFFBF3DF);
const _emerald = Color(0xFF275B50);
const _dark = Color(0xFF112A29);
const _mint = Color(0xFFA1D4B9);
const _first = Duration(milliseconds: 700);
const _handoff = Duration(milliseconds: 1150);
const _finish = Duration(milliseconds: 5300);

video.Video buildPoster(TeamDocument document) => _video(
  const video.Time.frames(1),
  const video.Time.frames(0),
  CraftSurface(
    material: CraftMaterial.paper,
    color: _paper,
    strength: .49,
    seed: 26,
    child: _Poster(document),
  ),
);

video.Video buildDashboard(TeamDocument document) {
  final timeline = MotionTimeline([
    MotionEvent(
      at: Duration.zero,
      node: document.lead.id,
      status: MotionStatus.active,
      message: document.lead.note,
    ),
    for (final (index, member) in document.members.indexed) ...[
      MotionEvent(
        at: _first + _handoff * index,
        node: member.id,
        from: document.lead.id,
        status: MotionStatus.active,
        message: '${member.role} entrou em cena',
      ),
      MotionEvent(
        at: _first + _handoff * (index + 1),
        node: member.id,
        status: MotionStatus.complete,
        message: member.note,
      ),
    ],
    MotionEvent(
      at: _finish,
      node: document.lead.id,
      status: MotionStatus.complete,
      message: document.summary,
    ),
  ]);
  return _video(
    const video.Time.seconds(8),
    const video.Time.frames(86),
    atMotionTime(timeline, (frame) => _Dashboard(document, frame)),
  );
}

video.Video _video(video.Time duration, video.Time poster, Widget page) =>
    video.Video(
      width: 1080,
      height: 1350,
      fps: 24,
      poster: poster,
      scenes: [
        video.Scene(
          duration: duration,
          children: [
            Positioned.fill(
              child: FittedBox(
                child: SizedBox(width: 480, height: 600, child: page),
              ),
            ),
          ],
        ),
      ],
    );

class _Heading extends StatelessWidget {
  const _Heading(this.title, this.subtitle, {required this.onDark});

  final String title;
  final String subtitle;
  final bool onDark;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(
        title,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: onDark ? _cream : _ink,
          fontFamily: 'Roboto',
          fontSize: onDark ? 36 : 43,
          fontWeight: FontWeight.w900,
          letterSpacing: -1.8,
          height: 1.03,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitle,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: onDark ? _mint : _ink,
          fontFamily: 'Roboto',
          fontSize: 16,
          height: 1.14,
        ),
      ),
    ],
  );
}

class _Poster extends StatelessWidget {
  const _Poster(this.document);

  final TeamDocument document;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(28, 36, 28, 29),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Heading(document.title, document.subtitle, onDark: false),
        const SizedBox(height: 25),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_emerald, _dark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _Portrait(document.lead, raised: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 1,
                child: Column(
                  children: [
                    for (var row = 0; row < 2; row++) ...[
                      if (row > 0) const SizedBox(height: 10),
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (var column = 0; column < 2; column++) ...[
                              if (column > 0) const SizedBox(width: 10),
                              Expanded(
                                child: _Portrait(
                                  document.members[row * 2 + column],
                                  raised: false,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(height: 1, color: const Color(0xFFAD9D81)),
        const SizedBox(height: 11),
        Text(
          document.summary,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _ink,
            fontFamily: 'Roboto',
            fontSize: 17,
            height: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

class _Portrait extends StatelessWidget {
  const _Portrait(this.member, {required this.raised});

  final WorkshopMember member;
  final bool raised;

  @override
  Widget build(BuildContext context) {
    final color = workshopColor(member.figure);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: raised
            ? null
            : Color.alphaBlend(color.withValues(alpha: .13), _cream),
        border: Border.all(
          color: raised ? const Color(0xFF467468) : const Color(0xFFC7BCA2),
        ),
        borderRadius: BorderRadius.circular(raised ? 16 : 12),
      ),
      child: Padding(
        padding: EdgeInsets.all(raised ? 12 : 7),
        child: Column(
          children: [
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1,
                  child: Transform.rotate(
                    angle: raised
                        ? -.075
                        : (member.figure.index.isEven ? -.11 : .085),
                    child: WorkshopCharacter(figure: member.figure),
                  ),
                ),
              ),
            ),
            Text(
              member.role,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: raised ? _cream : _ink,
                fontFamily: 'Roboto',
                fontSize: raised ? 29 : 16,
                fontWeight: FontWeight.w800,
                letterSpacing: raised ? -.5 : -.15,
              ),
            ),
            if (raised) ...[
              const SizedBox(height: 7),
              Text(
                member.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _mint,
                  fontFamily: 'Roboto',
                  fontSize: 14,
                ),
              ),
            ],
            SizedBox(height: raised ? 11 : 5),
          ],
        ),
      ),
    );
  }
}

class _Dashboard extends StatelessWidget {
  const _Dashboard(this.document, this.frame);

  final TeamDocument document;
  final MotionFrame frame;

  @override
  Widget build(BuildContext context) {
    final completed = document.members
        .where((member) => frame.statusOf(member.id) == MotionStatus.complete)
        .length;
    final summary = Curves.easeOut.transform(
      frame.progressSince(_finish, const Duration(milliseconds: 460)),
    );
    return ColoredBox(
      color: _dark,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 31, 28, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Heading(document.title, document.subtitle, onDark: true),
            const SizedBox(height: 17),
            Row(
              children: [
                const Text(
                  'Etapas concluídas',
                  style: TextStyle(
                    color: _cream,
                    fontFamily: 'Roboto',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                for (var index = 0; index < document.members.length; index++)
                  Container(
                    width: 18,
                    height: 4,
                    margin: const EdgeInsets.only(left: 4),
                    decoration: BoxDecoration(
                      color: index < completed
                          ? _mint
                          : const Color(0xFF365753),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                const SizedBox(width: 10),
                Text(
                  '$completed / ${document.members.length}',
                  style: const TextStyle(color: _mint, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: const Color(0xFF1A3734),
                  border: Border.all(color: const Color(0xFF416761)),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(painter: _Routes(document, frame)),
                        for (final (index, member) in document.members.indexed)
                          if (frame.statusOf(member.id) == MotionStatus.active)
                            _note(member, index, size),
                        for (final (index, member) in document.members.indexed)
                          _place(
                            member,
                            _points[index],
                            index,
                            size,
                            lead: false,
                          ),
                        _place(document.lead, _center, 4, size, lead: true),
                      ],
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 98,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(
                    opacity: 1 - summary,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0xFF183633),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(13, 10, 13, 7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Atividade recente',
                              style: TextStyle(
                                color: _mint,
                                fontFamily: 'Roboto',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 5),
                            MotionEventFeed(
                              frame: frame,
                              style: const TextStyle(
                                color: _cream,
                                fontFamily: 'Roboto',
                                fontSize: 13,
                                height: 1.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (summary > 0)
                    Opacity(
                      opacity: summary,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: _mint,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(15, 12, 15, 9),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                document.summary,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: _ink,
                                  fontFamily: 'Roboto',
                                  fontSize: 23,
                                  fontWeight: FontWeight.w900,
                                  height: 1.03,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '$completed etapas concluídas',
                                style: const TextStyle(
                                  color: _ink,
                                  fontFamily: 'Roboto',
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _note(WorkshopMember member, int index, Size size) {
    final cue = frame.latestOn(document.lead.id, member.id)!;
    final opacity = Curves.easeOut.transform(
      frame.progressSince(
        cue.at + const Duration(milliseconds: 210),
        const Duration(milliseconds: 230),
      ),
    );
    const width = 150.0;
    const height = 37.0;
    final center = _at(_points[index], size);
    final above = index >= 2;
    final color = workshopColor(member.figure);
    return Positioned(
      left: center.dx - width / 2,
      top: above ? center.dy - 43 - height : center.dy + 63,
      width: width,
      height: height,
      child: Opacity(
        opacity: opacity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF102C29),
            border: Border.all(color: color.withValues(alpha: .73)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Center(
              child: Text(
                member.note,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _cream,
                  fontFamily: 'Roboto',
                  fontSize: 12,
                  height: 1.08,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _place(
    WorkshopMember member,
    Offset anchor,
    int index,
    Size size, {
    required bool lead,
  }) {
    final state = frame.statusOf(member.id);
    final active = state == MotionStatus.active;
    final time = frame.elapsed.inMicroseconds / Duration.microsecondsPerSecond;
    final wave = math.sin(time * 4.3 + index * 1.65);
    final blinkPhase = (time + index * .34) % 2.7;
    final blink = (1 - (blinkPhase - .1).abs() / .1).clamp(0.0, 1.0);
    final diameter = lead ? 91.0 : 69.0;
    final center = _at(anchor, size);
    final color = workshopColor(member.figure);
    return Positioned(
      key: ValueKey(member.id),
      width: 112,
      left: center.dx - 56,
      top: center.dy - diameter / 2,
      child: Column(
        children: [
          Transform.translate(
            offset: Offset(0, wave * (active ? 3.7 : 1.3)),
            child: Transform.rotate(
              angle: wave * (active ? .126 : .051),
              child: SizedBox.square(
                dimension: diameter,
                child: WorkshopCharacter(figure: member.figure, blink: blink),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: active ? color : const Color(0xFF254640),
              border: Border.all(
                color: active ? color : const Color(0xFF537268),
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Text(
                member.role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? _ink : _cream,
                  fontFamily: 'Roboto',
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _points = [
  Offset(.22, .22),
  Offset(.78, .22),
  Offset(.22, .72),
  Offset(.78, .72),
];
const _center = Offset(.50, .43);

Offset _at(Offset anchor, Size size) =>
    Offset(anchor.dx * size.width, anchor.dy * size.height);

class _Routes extends CustomPainter {
  const _Routes(this.document, this.frame);

  final TeamDocument document;
  final MotionFrame frame;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final grid = Paint()..color = const Color(0x355EA094);
    for (double x = 12; x < size.width; x += 13) {
      for (double y = 12; y < size.height; y += 13) {
        canvas.drawCircle(Offset(x, y), .65, grid);
      }
    }
    final origin = _at(_center, size);
    for (final (index, member) in document.members.indexed) {
      final finish = _at(_points[index], size);
      final color = workshopColor(member.figure);
      final cue = frame.latestOn(document.lead.id, member.id);
      final active = frame.statusOf(member.id) == MotionStatus.active;
      final path = Path()
        ..moveTo(origin.dx, origin.dy)
        ..cubicTo(
          origin.dx + (finish.dx - origin.dx) * .20,
          finish.dy + (index < 2 ? -20 : 22),
          finish.dx,
          origin.dy + (index < 2 ? -17 : 20),
          finish.dx,
          finish.dy,
        );
      final wire = Paint()
        ..color = cue == null
            ? const Color(0xFF537973)
            : color.withValues(alpha: .62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 2.6 : 1.35;
      canvas.drawPath(path, wire);
      if (!active || cue == null) continue;
      final connector = Paint()
        ..color = color.withValues(alpha: .73)
        ..strokeWidth = 1;
      canvas.drawLine(
        finish + Offset(0, index < 2 ? 51 : -34),
        finish + Offset(0, index < 2 ? 63 : -43),
        connector,
      );
      final progress = frame.progressSince(cue.at, _handoff);
      final segment = path.computeMetrics().first;
      final head = segment
          .getTangentForOffset(segment.length * progress)!
          .position;
      canvas.drawCircle(head, 8, Paint()..color = color.withValues(alpha: .24));
      canvas.drawCircle(head, 4.2, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_Routes previous) =>
      previous.document != document || previous.frame != frame;
}
