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

typedef _Colors = ({
  Color base,
  Color accent,
  Color stage,
  Color border,
  Color feed,
  Color inactive,
  Color note,
  Color grid,
  Color poster,
  Color idleBar,
  Color badge,
  Color badgeBorder,
});

const _palettes = <WorkshopPalette, _Colors>{
  WorkshopPalette.forest: (
    base: Color(0xFF112A29),
    accent: Color(0xFFA1D4B9),
    stage: Color(0xFF1A3734),
    border: Color(0xFF416761),
    feed: Color(0xFF183633),
    inactive: Color(0xFF537973),
    note: Color(0xFF102C29),
    grid: Color(0x355EA094),
    poster: Color(0xFF275B50),
    idleBar: Color(0xFF365753),
    badge: Color(0xFF254640),
    badgeBorder: Color(0xFF537268),
  ),
  WorkshopPalette.midnight: (
    base: Color(0xFF151D38),
    accent: Color(0xFFA7CFF8),
    stage: Color(0xFF222D4D),
    border: Color(0xFF51678E),
    feed: Color(0xFF202C48),
    inactive: Color(0xFF627AA6),
    note: Color(0xFF151F3B),
    grid: Color(0x3595BCF3),
    poster: Color(0xFF222D4D),
    idleBar: Color(0xFF51678E),
    badge: Color(0xFF202C48),
    badgeBorder: Color(0xFF51678E),
  ),
  WorkshopPalette.aubergine: (
    base: Color(0xFF2E2133),
    accent: Color(0xFFF0B9CA),
    stage: Color(0xFF402B44),
    border: Color(0xFF78566F),
    feed: Color(0xFF3B293F),
    inactive: Color(0xFF916F8A),
    note: Color(0xFF322336),
    grid: Color(0x35D398C6),
    poster: Color(0xFF402B44),
    idleBar: Color(0xFF78566F),
    badge: Color(0xFF3B293F),
    badgeBorder: Color(0xFF78566F),
  ),
};

class _Pacing {
  const _Pacing(this.fast, this.groups);

  final bool fast;
  final int groups;
  Duration get opening => Duration(milliseconds: fast ? 320 : 700);
  Duration get step => Duration(milliseconds: fast ? 980 : 1150);
  Duration get finish => opening + step * groups;
  Duration get end => finish + Duration(milliseconds: fast ? 1720 : 2700);
}

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
  final pacing = _Pacing(
    document.pace == WorkshopPace.fast,
    document.groups.length,
  );
  final timeline = MotionTimeline([
    MotionEvent(
      at: Duration.zero,
      node: document.lead.id,
      status: MotionStatus.active,
      message: document.lead.note,
    ),
    for (final (index, group) in document.groups.indexed) ...[
      for (final member in group)
        MotionEvent(
          at: pacing.opening + pacing.step * index,
          node: member.id,
          from: document.lead.id,
          status: MotionStatus.active,
          message: '${member.role} entrou em cena',
        ),
      for (final member in group)
        MotionEvent(
          at: pacing.opening + pacing.step * (index + 1),
          node: member.id,
          status: MotionStatus.complete,
          message: member.note,
        ),
    ],
    MotionEvent(
      at: pacing.finish,
      node: document.lead.id,
      status: MotionStatus.complete,
      message: document.summary,
    ),
  ]);
  final poster = !pacing.fast && pacing.groups == 4
      ? const video.Time.frames(86)
      : video.Time.ms((pacing.opening + pacing.step ~/ 2).inMilliseconds);
  return _video(
    video.Time.frames((pacing.end.inMilliseconds * 24 / 1000).round()),
    poster,
    atMotionTime(timeline, (frame) => _Dashboard(document, frame, pacing)),
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
  const _Heading(this.title, this.subtitle, {this.darkAccent});

  final String title;
  final String subtitle;
  final Color? darkAccent;

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
          color: darkAccent == null ? _ink : _cream,
          fontFamily: 'Roboto',
          fontSize: darkAccent == null ? 43 : 36,
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
          color: darkAccent ?? _ink,
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
        _Heading(document.title, document.subtitle),
        const SizedBox(height: 25),
        Expanded(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _palettes[document.palette]!.poster,
                        _palettes[document.palette]!.base,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: _Portrait(
                    document.lead,
                    raised: true,
                    accent: _palettes[document.palette]!.accent,
                  ),
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
  const _Portrait(this.member, {required this.raised, this.accent});

  final WorkshopMember member;
  final bool raised;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    final color = workshopMemberColor(member);
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
                    child: WorkshopCharacter(
                      figure: member.figure,
                      color: color,
                    ),
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
                style: TextStyle(
                  color: accent,
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
  const _Dashboard(this.document, this.frame, this.pacing);

  final TeamDocument document;
  final MotionFrame frame;
  final _Pacing pacing;
  _Colors get colors => _palettes[document.palette]!;

  @override
  Widget build(BuildContext context) {
    final completed = document.members
        .where((member) => frame.statusOf(member.id) == MotionStatus.complete)
        .length;
    final summary = Curves.easeOut.transform(
      frame.progressSince(
        pacing.finish,
        Duration(milliseconds: pacing.fast ? 300 : 460),
      ),
    );
    return ColoredBox(
      color: colors.base,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(28, 31, 28, 26),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Heading(
              document.title,
              document.subtitle,
              darkAccent: colors.accent,
            ),
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
                      color: index < completed ? colors.accent : colors.idleBar,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                const SizedBox(width: 10),
                Text(
                  '$completed / ${document.members.length}',
                  style: TextStyle(color: colors.accent, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.stage,
                  border: Border.all(color: colors.border),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    // Leave room for one callout per side of the lead.
                    final notes = <int>{};
                    final sides = <int>{};
                    for (final (index, member) in document.members.indexed) {
                      if (frame.statusOf(member.id) == MotionStatus.active &&
                          sides.add(index % 2)) {
                        notes.add(index);
                      }
                    }
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        CustomPaint(
                          painter: _Routes(document, frame, pacing, notes),
                        ),
                        for (final index in notes)
                          _note(document.members[index], index, size),
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
                        color: colors.feed,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(13, 10, 13, 7),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Atividade recente',
                              style: TextStyle(
                                color: colors.accent,
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
                          color: colors.accent,
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
        cue.at + Duration(milliseconds: pacing.fast ? 130 : 210),
        Duration(milliseconds: pacing.fast ? 140 : 230),
      ),
    );
    const width = 150.0;
    const height = 37.0;
    final center = _at(_points[index], size);
    final above = index >= 2;
    final color = workshopMemberColor(member);
    return Positioned(
      left: center.dx - width / 2,
      top: above ? center.dy - 43 - height : center.dy + 63,
      width: width,
      height: height,
      child: Opacity(
        opacity: opacity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.note,
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
    final wave = math.sin(time * (pacing.fast ? 7.2 : 4.3) + index * 1.65);
    var lift = 0.0;
    if (pacing.fast && active && !lead) {
      final start = frame.latestOn(document.lead.id, member.id)!.at;
      final arrival = frame.progressSince(
        start,
        const Duration(milliseconds: 430),
      );
      lift = math.sin(math.pi * arrival) * (1 - arrival);
    }
    final blinkPhase = (time + index * .34) % 2.7;
    final blink = (1 - (blinkPhase - .1).abs() / .1).clamp(0.0, 1.0);
    final diameter = lead ? 91.0 : 69.0;
    final center = _at(anchor, size);
    final color = workshopMemberColor(member);
    final badgeText = active && color.computeLuminance() >= .16 ? _ink : _cream;
    return Positioned(
      key: ValueKey(member.id),
      width: 112,
      left: center.dx - 56,
      top: center.dy - diameter / 2,
      child: Column(
        children: [
          Transform.translate(
            offset: Offset(0, wave * (active ? 3.7 : 1.3) - lift * 12),
            child: Transform.rotate(
              angle: wave * (active ? .126 : .051),
              child: Transform.scale(
                scale: 1 + lift * .22,
                child: SizedBox.square(
                  dimension: diameter,
                  child: WorkshopCharacter(
                    figure: member.figure,
                    color: color,
                    blink: blink,
                  ),
                ),
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              color: active ? color : colors.badge,
              border: Border.all(color: active ? color : colors.badgeBorder),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              child: Text(
                member.role,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: badgeText,
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
  const _Routes(this.document, this.frame, this.pacing, this.notes);

  final TeamDocument document;
  final MotionFrame frame;
  final _Pacing pacing;
  final Set<int> notes;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final colors = _palettes[document.palette]!;
    final grid = Paint()..color = colors.grid;
    for (double x = 12; x < size.width; x += 13) {
      for (double y = 12; y < size.height; y += 13) {
        canvas.drawCircle(Offset(x, y), .65, grid);
      }
    }
    final origin = _at(_center, size);
    for (final (index, member) in document.members.indexed) {
      final finish = _at(_points[index], size);
      final color = workshopMemberColor(member);
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
        ..color = cue == null ? colors.inactive : color.withValues(alpha: .62)
        ..style = PaintingStyle.stroke
        ..strokeWidth = active ? 2.6 : 1.35;
      canvas.drawPath(path, wire);
      if (!active || cue == null) continue;
      if (notes.contains(index)) {
        final connector = Paint()
          ..color = color.withValues(alpha: .73)
          ..strokeWidth = 1;
        canvas.drawLine(
          finish + Offset(0, index < 2 ? 51 : -34),
          finish + Offset(0, index < 2 ? 63 : -43),
          connector,
        );
      }
      final progress = frame.progressSince(cue.at, pacing.step);
      final segment = path.computeMetrics().first;
      final head = segment
          .getTangentForOffset(segment.length * progress)!
          .position;
      if (pacing.fast) {
        final tail = segment.extractPath(
          segment.length * math.max(0.0, progress - .24),
          segment.length * progress,
        );
        canvas.drawPath(
          tail,
          Paint()
            ..color = color.withValues(alpha: .48)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 5
            ..strokeCap = StrokeCap.round,
        );
      }
      canvas.drawCircle(head, 8, Paint()..color = color.withValues(alpha: .24));
      canvas.drawCircle(head, 4.2, Paint()..color = color);
    }
  }

  @override
  bool shouldRepaint(_Routes previous) =>
      previous.document != document || previous.frame != frame;
}
