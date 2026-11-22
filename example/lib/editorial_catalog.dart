import 'dart:math' as math;

import 'package:event_motion/event_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:fluvie/fluvie.dart' as video;
import 'package:handcrafted_flutter/handcrafted_flutter.dart';

import 'src/catalog_document.dart';
import 'src/motion_clock.dart';

typedef _Colors = ({
  Color paper,
  Color ink,
  Color accent,
  Color rule,
  Color tile,
  Color focus,
  List<Color> diagrams,
});

const _palettes = <CatalogPalette, _Colors>{
  CatalogPalette.paper: (
    paper: Color(0xFFF2EBD9),
    ink: Color(0xFF1B322B),
    accent: Color(0xFF1E624E),
    rule: Color(0xFFD2C6AE),
    tile: Color(0xFFFBF7EB),
    focus: Color(0xFFFFFCF2),
    diagrams: [
      Color(0xFF26634F),
      Color(0xFF8E4D2D),
      Color(0xFF3D5488),
      Color(0xFF72538C),
    ],
  ),
  CatalogPalette.blueprint: (
    paper: Color(0xFFE3EAF5),
    ink: Color(0xFF162941),
    accent: Color(0xFF245D92),
    rule: Color(0xFFBBCBE0),
    tile: Color(0xFFF5F9FF),
    focus: Color(0xFFFAFCFF),
    diagrams: [
      Color(0xFF245D92),
      Color(0xFF934236),
      Color(0xFF29685D),
      Color(0xFF67478E),
    ],
  ),
  CatalogPalette.rose: (
    paper: Color(0xFFF5E7E3),
    ink: Color(0xFF3D2637),
    accent: Color(0xFF8B3A63),
    rule: Color(0xFFDBC3CA),
    tile: Color(0xFFFFF6F1),
    focus: Color(0xFFFFFAF8),
    diagrams: [
      Color(0xFF8B3A63),
      Color(0xFF985120),
      Color(0xFF2F6372),
      Color(0xFF62518B),
    ],
  ),
};
const _slot = Duration(milliseconds: 750);
const _start = Duration(milliseconds: 500);

video.Video build(CatalogDocument document) {
  final colors = _palettes[document.palette]!;
  final timeline = MotionTimeline([
    for (final (index, id) in document.order.indexed) ...[
      MotionEvent(
        at: _start + _slot * index,
        node: id,
        status: MotionStatus.active,
      ),
      MotionEvent(
        at: _start + _slot * (index + 1),
        node: id,
        status: MotionStatus.complete,
      ),
    ],
  ]);
  final duration =
      _start + _slot * document.order.length + const Duration(seconds: 1);
  final frames = duration.inMilliseconds * 24 ~/ 1000;
  return video.Video(
    width: 1080,
    height: 1350,
    fps: 24,
    poster: video.Time.frames(frames - 8),
    scenes: [
      video.Scene(
        duration: video.Time.frames(frames),
        children: [
          Positioned.fill(
            child: FittedBox(
              child: SizedBox(
                width: 480,
                height: 600,
                child: CraftSurface(
                  material: CraftMaterial.paper,
                  color: colors.paper,
                  strength: 0.43,
                  seed: 38,
                  child: atMotionTime(
                    timeline,
                    (frame) => _Catalog(document, frame, colors),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _Catalog extends StatelessWidget {
  const _Catalog(this.document, this.frame, this.colors);

  final CatalogDocument document;
  final MotionFrame frame;
  final _Colors colors;

  @override
  Widget build(BuildContext context) {
    final tiles = document.tiles;
    final dense = tiles.length > 8;
    final hasFooter = document.footer != null || document.sources.isNotEmpty;
    final columns = dense ? 3 : 2;
    final rows = (tiles.length + columns - 1) ~/ columns;
    final done = document.order
        .where((id) => frame.statusOf(id) == MotionStatus.complete)
        .length;
    final active = tiles
        .where((tile) => frame.statusOf(tile.id) == MotionStatus.active)
        .firstOrNull;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        28,
        hasFooter ? 10 : (dense ? 23 : 28),
        28,
        hasFooter ? 10 : 23,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasFooter) ...[
            Container(
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
            SizedBox(height: dense ? 10 : 13),
          ],
          Text(
            document.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.ink,
              fontFamily: 'Roboto',
              fontSize: dense ? 33 : 37,
              height: 1.03,
              fontWeight: FontWeight.w800,
              letterSpacing: -1.6,
            ),
          ),
          SizedBox(height: hasFooter ? 5 : 8),
          Text(
            document.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.ink,
              fontFamily: 'Roboto',
              fontSize: 16,
              height: 1.2,
            ),
          ),
          SizedBox(height: hasFooter ? 8 : (dense ? 13 : 18)),
          for (var row = 0; row < rows; row++) ...[
            if (row > 0) const SizedBox(height: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var column = 0; column < columns; column++) ...[
                    if (column > 0) const SizedBox(width: 8),
                    Expanded(
                      child: row * columns + column < tiles.length
                          ? _Tile(
                              tile: tiles[row * columns + column],
                              frame: frame,
                              dense: dense,
                              colors: colors,
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
          SizedBox(height: hasFooter ? 8 : 13),
          Container(height: 1, color: colors.rule),
          SizedBox(height: hasFooter ? 5 : 10),
          if (hasFooter)
            _CatalogFooter(document, colors)
          else
            Row(
              children: [
                Expanded(
                  child: Text(
                    active == null
                        ? '$done de ${tiles.length} etapas'
                        : 'Em foco · ${active.title}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: colors.ink,
                      fontFamily: 'Roboto',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                for (var index = 0; index < tiles.length; index++)
                  Container(
                    width: 7,
                    height: 3,
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      color: index < done ? colors.accent : colors.rule,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _CatalogFooter extends StatelessWidget {
  const _CatalogFooter(this.document, this.colors);

  final CatalogDocument document;
  final _Colors colors;

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      color: colors.ink,
      fontFamily: 'Inter',
      fontSize: 13,
      height: 1.1,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        Widget fitBlock(Widget child, double maxHeight) => ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: SizedBox(width: constraints.maxWidth, child: child),
          ),
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (document.footer case final note?)
              fitBlock(
                Text(note, style: style.copyWith(fontWeight: FontWeight.w600)),
                30,
              ),
            if (document.footer != null && document.sources.isNotEmpty)
              const SizedBox(height: 4),
            if (document.sources.isNotEmpty)
              fitBlock(
                Wrap(
                  spacing: 8,
                  runSpacing: 2,
                  children: [
                    for (final label in document.sources)
                      Text(label, style: style.copyWith(fontSize: 12)),
                  ],
                ),
                54,
              ),
          ],
        );
      },
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.tile,
    required this.frame,
    required this.dense,
    required this.colors,
  });

  final CatalogTile tile;
  final MotionFrame frame;
  final bool dense;
  final _Colors colors;

  @override
  Widget build(BuildContext context) {
    final event = frame.latestFor(tile.id);
    final active = event?.status == MotionStatus.active;
    final progress = active
        ? 0.18 +
              0.82 *
                  Curves.easeOutCubic.transform(
                    frame.progressSince(
                      event!.at,
                      const Duration(milliseconds: 560),
                    ),
                  )
        : 1.0;
    final color = tile.accent == null
        ? colors.diagrams[tile.diagram.index]
        : Color(tile.accent!);
    final titleColor = tile.accent == null ? color : colors.ink;
    return DecoratedBox(
      key: ValueKey(tile.id),
      decoration: BoxDecoration(
        color: active
            ? Color.alphaBlend(color.withValues(alpha: 0.12), colors.focus)
            : colors.tile,
        border: Border.all(
          color: active ? color : colors.rule,
          width: active ? 1.6 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          if (active)
            BoxShadow(
              color: color.withValues(alpha: 0.16),
              blurRadius: 9,
              offset: const Offset(0, 3),
            ),
        ],
      ),
      child: Padding(
        padding: dense
            ? const EdgeInsets.fromLTRB(8, 6, 8, 5)
            : const EdgeInsets.fromLTRB(10, 7, 10, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tile.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: titleColor,
                fontFamily: 'Roboto',
                fontSize: dense ? 14.5 : 17,
                height: dense ? 1.02 : 1.08,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: dense ? 2 : 3),
            Text(
              tile.note,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.ink,
                fontFamily: 'Roboto',
                fontSize: dense ? 11.5 : 12.6,
                height: dense ? 1.03 : 1.1,
              ),
            ),
            SizedBox(height: dense ? 2 : 4),
            Expanded(
              child: CustomPaint(
                size: Size.infinite,
                painter: _Diagram(tile.diagram, color, progress, active),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Diagram extends CustomPainter {
  const _Diagram(this.kind, this.color, this.progress, this.active);

  final DiagramKind kind;
  final Color color;
  final double progress;
  final bool active;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final line = Paint()
      ..color = color
      ..strokeWidth = 1.65
      ..strokeCap = StrokeCap.round;
    final pale = Paint()..color = color.withValues(alpha: 0.16);
    final w = size.width;
    final h = size.height;
    Offset at(double x, double y) => Offset(w * x, h * y);
    switch (kind) {
      case DiagramKind.flow:
        canvas.drawLine(at(0.16, 0.52), at(0.84, 0.52), pale..strokeWidth = 2);
        for (final x in [0.16, 0.50, 0.84]) {
          final box = RRect.fromRectAndRadius(
            Rect.fromCenter(
              center: at(x, 0.52),
              width: w * 0.17,
              height: h * 0.42,
            ),
            const Radius.circular(4),
          );
          canvas.drawRRect(box, pale);
          canvas.drawRRect(box, line..style = PaintingStyle.stroke);
        }
        canvas.drawCircle(
          at(0.16 + 0.68 * progress, 0.52),
          math.min(3.6, h * 0.14),
          line..style = PaintingStyle.fill,
        );
      case DiagramKind.bars:
        const values = [0.36, 0.62, 0.47, 0.82, 0.66];
        canvas.drawLine(at(0.10, 0.88), at(0.90, 0.88), pale..strokeWidth = 2);
        for (final (index, value) in values.indexed) {
          final x = 0.18 + 0.16 * index;
          final bar = Rect.fromPoints(
            at(x - 0.041, 0.88 - value * progress * 0.78),
            at(x + 0.041, 0.88),
          );
          final paint = Paint()
            ..color = color.withValues(alpha: index == 3 ? 1 : 0.55);
          canvas.drawRRect(
            RRect.fromRectAndRadius(bar, const Radius.circular(2)),
            paint,
          );
        }
      case DiagramKind.curve:
        final path = Path()
          ..moveTo(w * 0.08, h * 0.78)
          ..cubicTo(w * 0.22, h * 0.87, w * 0.34, h * 0.24, w * 0.48, h * 0.51)
          ..cubicTo(w * 0.65, h * 0.83, w * 0.74, h * 0.17, w * 0.91, h * 0.22);
        final metric = path.computeMetrics().first;
        canvas.drawPath(
          path,
          pale
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2,
        );
        canvas.drawPath(
          metric.extractPath(0, metric.length * progress),
          line..style = PaintingStyle.stroke,
        );
        final head = metric
            .getTangentForOffset(metric.length * progress)!
            .position;
        canvas.drawCircle(
          head,
          math.min(3, h * 0.13),
          line..style = PaintingStyle.fill,
        );
      case DiagramKind.orbit:
        final center = at(0.5, 0.5);
        final rx = w * 0.34;
        final ry = h * 0.34;
        canvas.drawOval(
          Rect.fromCenter(center: center, width: 2 * rx, height: 2 * ry),
          line..style = PaintingStyle.stroke,
        );
        final angle = math.pi * (active ? 2 * progress : 0.18);
        final head =
            center + Offset(rx * math.cos(angle), ry * math.sin(angle));
        canvas.drawCircle(center, math.min(5.5, h * 0.19), pale);
        canvas.drawCircle(
          head,
          math.min(3.4, h * 0.15),
          line..style = PaintingStyle.fill,
        );
    }
  }

  @override
  bool shouldRepaint(_Diagram previous) =>
      previous.kind != kind ||
      previous.color != color ||
      previous.progress != progress ||
      previous.active != active;
}
