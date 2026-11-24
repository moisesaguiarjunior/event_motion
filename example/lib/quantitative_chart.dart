import 'package:flutter/widgets.dart';
import 'package:fluvie/fluvie.dart' as video;
import 'src/quantitative_document.dart';

const _ink = Color(0xFF182A23);
const _muted = Color(0xFF43564D);
const _accent = Color(0xFF087656);
const _paper = Color(0xFFF4F1E7);
const _rule = Color(0xFFCCD2C7);

video.Video build(QuantitativeDocument document) => video.Video(
  width: 1080,
  height: 1350,
  fps: 24,
  poster: video.Time.frames(0),
  scenes: [
    video.Scene(
      duration: video.Time.frames(1),
      children: [
        Positioned.fill(
          child: FittedBox(
            child: SizedBox(
              width: 432,
              height: 540,
              child: CustomPaint(painter: QuantitativePainter(document)),
            ),
          ),
        ),
      ],
    ),
  ],
);

/// Geometry is numerical; labels never determine bar lengths or intervals.
class QuantitativePainter extends CustomPainter {
  QuantitativePainter(this.document);
  final QuantitativeDocument document;

  double text(
    Canvas c,
    String value,
    double x,
    double y,
    double width, {
    double size = 11,
    bool bold = false,
    Color color = _ink,
    double? maxHeight,
  }) {
    final p = TextPainter(
      text: TextSpan(
        text: value,
        style: TextStyle(
          fontFamily: 'Roboto',
          fontSize: size,
          height: 1.12,
          fontWeight: bold ? FontWeight.w700 : FontWeight.w400,
          color: color,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: width);
    if (y + p.height > 526 || (maxHeight != null && p.height > maxHeight)) {
      throw StateError('Quantitative chart text exceeds page: $value');
    }
    p.paint(c, Offset(x, y));
    final h = p.height;
    p.dispose();
    return h;
  }

  String refs(Map d) =>
      (d['source_ids'] as List).map((id) => '[$id]').join(' ');
  String signed(num n, {int decimals = 0}) =>
      '${n < 0
          ? '−'
          : n > 0
          ? '+'
          : ''}${n.abs().toStringAsFixed(decimals)}';

  @override
  void paint(Canvas c, Size size) {
    final d = document.data;
    c.drawRect(Offset.zero & size, Paint()..color = _paper);
    c.drawRect(const Rect.fromLTWH(20, 16, 35, 3), Paint()..color = _accent);
    var y = 26.0;
    y += text(c, d['title'] as String, 20, y, 392, size: 26, bold: true) + 5;
    y += text(c, d['subtitle'] as String, 20, y, 392, size: 11.5) + 10;
    final hero = d['hero'] as Map;
    y +=
        text(
          c,
          hero['value'] as String,
          20,
          y,
          392,
          size: 32,
          bold: true,
          color: _accent,
        ) +
        3;
    y +=
        text(c, '${hero['caption']} ${refs(hero)}', 20, y, 392, size: 11.2) + 6;
    y +=
        text(c, d['context'] as String, 20, y, 392, size: 10.6, color: _muted) +
        10;
    if (document.intervals) {
      y = intervals(c, d, y);
    } else {
      for (final panel in d['panels'] as List) {
        y = bars(c, panel as Map, y);
      }
    }
    y += 5;
    y +=
        text(
          c,
          d['footnote'] as String,
          20,
          y,
          392,
          size: 10.2,
          color: _muted,
        ) +
        5;
    for (final s in d['sources'] as List) {
      y += text(c, '[${s['id']}] ${s['label']}', 20, y, 392, size: 10.2) + 2;
    }
  }

  double intervals(Canvas c, Map d, double top) {
    final axis = d['axis'] as Map;
    final low = (axis['min'] as num).toDouble();
    final high = (axis['max'] as num).toDouble();
    final suffix = axis['suffix'];
    double x(num v) =>
        QuantitativeDocument.position(v.toDouble(), low, high, 38, 352);
    final rows = d['rows'] as List;
    final bottom = top + rows.length * 65;
    for (final (i, raw) in rows.indexed) {
      final r = raw as Map;
      final y = top + i * 65;
      text(c, '${r['label']} ${refs(r)}', 20, y, 392, size: 12, bold: true);
      final cy = y + 34;
      c.drawLine(
        Offset(x(0), cy - 14),
        Offset(x(0), cy + 8),
        Paint()
          ..color = _muted
          ..strokeWidth = .8,
      );
      final l = r['lower'] as num;
      final u = r['upper'] as num;
      final e = r['estimate'] as num;
      final line = Paint()
        ..color = _accent
        ..strokeWidth = 2;
      c.drawLine(Offset(x(l), cy), Offset(x(u), cy), line);
      for (final v in [l, u]) {
        c.drawLine(Offset(x(v), cy - 5), Offset(x(v), cy + 5), line);
      }
      c.drawCircle(Offset(x(e), cy), 3.5, Paint()..color = _accent);
      // Endpoint labels are below, estimate above: nearby bounds never collide.
      text(
        c,
        '${signed(e, decimals: 1)}$suffix',
        x(e) - 30,
        cy - 19,
        65,
        size: 11,
        bold: true,
      );
      text(c, '${signed(l)}$suffix', x(l) - 17, cy + 7, 52, size: 10.6);
      text(c, '${signed(u)}$suffix', x(u) - 17, cy + 7, 52, size: 10.6);
      text(c, r['note'] as String, 20, y + 53, 392, size: 10.2, color: _muted);
    }
    c.drawLine(
      Offset(38, bottom + 4),
      Offset(390, bottom + 4),
      Paint()..color = _rule,
    );
    for (final value in [low, 0.0, high]) {
      text(
        c,
        '${signed(value)}$suffix',
        x(value) - 17,
        bottom + 8,
        55,
        size: 10.4,
        bold: value == 0,
      );
    }
    return bottom + 26;
  }

  double bars(Canvas c, Map p, double top) {
    var y = top;
    y +=
        text(c, '${p['title']} ${refs(p)}', 20, y, 392, size: 12, bold: true) +
        2;
    y +=
        text(c, p['unit'] as String, 20, y, 392, size: 10.2, color: _muted) + 3;
    final bars = p['bars'] as List;
    final maximum = (p['maximum'] as num).toDouble();
    final plotTop = y + 13;
    final baseline = plotTop + 38;
    c.drawLine(
      Offset(42, baseline),
      Offset(402, baseline),
      Paint()
        ..color = _muted
        ..strokeWidth = .7,
    );
    text(c, '0', 20, baseline - 8, 20, size: 10);
    text(c, maximum.toStringAsFixed(0), 16, plotTop - 4, 26, size: 9.5);
    c.drawLine(
      Offset(42, plotTop),
      Offset(402, plotTop),
      Paint()
        ..color = _rule
        ..strokeWidth = .5,
    );
    final cell = 356 / bars.length;
    for (final (i, raw) in bars.indexed) {
      final b = raw as Map;
      final value = (b['value'] as num).toDouble();
      final x = 44 + i * cell;
      final height = value / maximum * 38;
      c.drawRect(
        Rect.fromLTWH(x + cell * .26, baseline - height, cell * .48, height),
        Paint()..color = _accent,
      );
      text(
        c,
        value.toStringAsFixed(1),
        x + cell * .18,
        baseline - height - 14,
        cell * .8,
        size: 11,
        bold: true,
      );
      text(c, b['label'] as String, x + 4, baseline + 3, cell - 6, size: 10.6);
      if (b.containsKey('annotation')) {
        // The annotation belongs to this category, below its date.
        text(
          c,
          b['annotation'] as String,
          x,
          baseline + 17,
          cell - 3,
          size: 9.7,
          bold: true,
        );
      }
    }
    final annotated = bars.any((b) => (b as Map).containsKey('annotation'));
    y = baseline + (annotated ? 42 : 20);
    y +=
        text(c, p['note'] as String, 20, y, 392, size: 10.2, color: _muted) +
        10;
    return y;
  }

  @override
  bool shouldRepaint(QuantitativePainter oldDelegate) =>
      document != oldDelegate.document;
}
