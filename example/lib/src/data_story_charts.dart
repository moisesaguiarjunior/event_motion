part of '../data_story.dart';

const _plannedDot = Color(0xFF495B70);
const _reportedDot = Color(0xFF08786B);
const _referenceInk = Color(0xFF698277);

String _shortNumber(num value) {
  if (value == 0) return '0';
  final text = value.toStringAsPrecision(10);
  final parts = text.split('e');
  var mantissa = parts.first;
  if (mantissa.contains('.')) {
    mantissa = mantissa
        .replaceFirst(RegExp(r'0+$'), '')
        .replaceFirst(RegExp(r'\.$'), '');
  }
  return parts.length == 1 ? mantissa : '${mantissa}e${parts.last}';
}

void _chartText(
  Canvas canvas,
  String content,
  Offset anchor, {
  double size = 12,
  double alignment = .5,
  double maxWidth = double.infinity,
  Color color = _ink,
  Color? paper,
  bool bold = false,
  bool verticalCenter = true,
}) {
  final painter = TextPainter(
    text: TextSpan(
      text: content,
      style: TextStyle(
        color: color,
        fontFamily: 'Roboto',
        fontSize: size,
        height: 1.13,
        fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
      ),
    ),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout(maxWidth: maxWidth);
  final topLeft =
      anchor -
      Offset(
        painter.width * alignment,
        verticalCenter ? painter.height / 2 : 0,
      );
  if (paper != null) {
    canvas.drawRect(
      (topLeft & painter.size).inflate(2),
      Paint()..color = paper,
    );
  }
  painter.paint(canvas, topLeft);
  painter.dispose();
}

void _dash(Canvas canvas, Offset start, Offset end) {
  final delta = end - start;
  final length = delta.distance;
  final paint = Paint()
    ..color = _referenceInk
    ..strokeWidth = 1.1;
  for (var offset = 0.0; offset < length; offset += 8) {
    canvas.drawLine(
      start + delta * (offset / length),
      start + delta * (math.min(offset + 4, length) / length),
      paint,
    );
  }
}

class _PairedLegend extends StatelessWidget {
  const _PairedLegend(this.series);

  final List<_Series> series;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 15,
    runSpacing: 3,
    children: [
      for (final (index, item) in series.indexed)
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index == 0 ? _panel : _reportedDot,
                border: index == 0
                    ? Border.all(color: _plannedDot, width: 2)
                    : null,
              ),
            ),
            const SizedBox(width: 5),
            _text(
              item.name,
              12,
              bold: true,
              color: index == 0 ? _plannedDot : _reportedDot,
            ),
          ],
        ),
    ],
  );
}

class _PairedDots extends CustomPainter {
  const _PairedDots(this.labels, this.series, this.axis, this.progress);

  final List<String> labels;
  final List<_Series> series;
  final ChartAxis axis;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height < 100 || size.width < 180) return;
    final top = 20.0 + axis.referenceLines.length * 13;
    final plot = Rect.fromLTRB(103, top, size.width - 26, size.height - 21);
    final rowHeight = plot.height / labels.length;
    final labelOffset = math.min(15.0, rowHeight * .34);
    final valueSize = rowHeight < 38 ? 9.5 : 11.0;
    final span = axis.maximum - axis.minimum;
    final intervals = span == span.round() && span >= 2 && span <= 6
        ? span.round()
        : 4;
    double x(num value) =>
        plot.left + plot.width * (value - axis.minimum) / span;
    String label(num value) => '${_shortNumber(value)}${axis.suffix}';

    for (var tick = 0; tick <= intervals; tick++) {
      final value = axis.minimum + span * tick / intervals;
      final at = x(value);
      canvas.drawLine(
        Offset(at, plot.top),
        Offset(at, plot.bottom),
        Paint()..color = _rule,
      );
      _chartText(canvas, label(value), Offset(at, plot.bottom + 12), size: 11);
    }
    for (final (index, reference) in axis.referenceLines.indexed) {
      final at = x(reference.value);
      final y = 16.0 + 13 * index;
      _dash(canvas, Offset(at, y + 7), Offset(at, plot.bottom));
      final anchor = at.clamp(45.0, size.width - 45);
      _chartText(
        canvas,
        reference.label,
        Offset(anchor, y),
        maxWidth: math.min(
          size.width - 12,
          2 * math.min(anchor, size.width - anchor),
        ),
        color: _referenceInk,
        size: 10,
        paper: _panel,
        bold: true,
      );
    }
    for (final (index, name) in labels.indexed) {
      final y = plot.top + rowHeight * (index + .5);
      _chartText(
        canvas,
        name,
        Offset(7, y),
        alignment: 0,
        maxWidth: 81,
        size: 12,
        bold: true,
      );
      if (progress == 0) continue;
      final firstValue = series.first.values[index];
      final secondValue = series.last.values[index];
      final first = Offset(x(firstValue), y);
      final second = Offset(x(secondValue), y);
      final displayed = Offset.lerp(first, second, progress)!;
      final open = Paint()
        ..color = _plannedDot
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      final fill = Paint()..color = _reportedDot;
      canvas.drawLine(
        first,
        displayed,
        Paint()
          ..color = _referenceInk
          ..strokeWidth = 2,
      );
      canvas.drawCircle(first, 6, Paint()..color = _panel);
      canvas.drawCircle(first, 6, open);
      canvas.drawCircle(displayed, 3.7, fill);
      if (progress < .97) continue;
      _chartText(
        canvas,
        label(firstValue),
        first.translate(0, -labelOffset),
        size: valueSize,
        bold: true,
        color: _plannedDot,
        paper: _panel,
      );
      _chartText(
        canvas,
        label(secondValue),
        second.translate(0, labelOffset),
        size: valueSize,
        bold: true,
        color: _reportedDot,
        paper: _panel,
      );
    }
  }

  @override
  bool shouldRepaint(_PairedDots old) =>
      labels != old.labels ||
      series != old.series ||
      axis != old.axis ||
      progress != old.progress;
}

class _StackedBar extends CustomPainter {
  const _StackedBar(this.labels, this.values, this.options);

  final List<String> labels;
  final List<num> values;
  final DataStoryChart options;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 120 || size.height < 100) return;
    const palette = video.FluvieTokens.fallback();
    final left = 4.0;
    final width = size.width - left * 2;
    final barTop = math.min(size.height * .28, 105.0);
    final barBottom = barTop + 36;
    final labelY = barBottom + (size.height < 220 ? 31 : 49);
    final slotWidth = width / labels.length;
    String shareLabel(num value, bool approximate) {
      final prefix = options.valuePrefix;
      final number = _shortNumber(value);
      final qualifier = approximate ? '~' : '';
      return prefix.isEmpty ? '$qualifier$number%' : '$qualifier$prefix$number';
    }

    final stops = <double>[left];
    final total = values.fold<num>(0, (sum, value) => sum + value);
    for (final value in values) {
      stops.add(stops.last + width * value / total);
    }
    stops[stops.length - 1] = left + width;
    for (final (index, label) in labels.indexed) {
      final color = palette.palette.colorAt(index);
      final x0 = stops[index];
      final x1 = stops[index + 1];
      final center = (x0 + x1) / 2;
      final anchor = left + (index + .5) * slotWidth;
      canvas.drawRect(
        Rect.fromLTRB(x0, barTop, x1, barBottom),
        Paint()..color = color,
      );
      final connector = Path()
        ..moveTo(center, barBottom)
        ..lineTo(center, barBottom + 5)
        ..lineTo(anchor, labelY - 6)
        ..lineTo(anchor, labelY - 2);
      canvas.drawPath(
        connector,
        Paint()
          ..color = _referenceInk
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.3,
      );
      _chartText(
        canvas,
        shareLabel(values[index], options.approximateIndices.contains(index)),
        Offset(anchor, labelY),
        size: 16,
        bold: true,
        verticalCenter: false,
      );
      _chartText(
        canvas,
        label,
        Offset(anchor, labelY + 20),
        maxWidth: slotWidth - 6,
        size: labels.length > 4 ? 10 : 12,
        verticalCenter: false,
      );
    }
    if (options.subtotal case final subtotal?) {
      final x0 = stops[subtotal.startIndex];
      final x1 = stops[subtotal.endIndex + 1];
      final y = barTop - 8;
      final bracket = Path()
        ..moveTo(x0, y + 5)
        ..lineTo(x0, y)
        ..lineTo(x1, y)
        ..lineTo(x1, y + 5);
      canvas.drawPath(
        bracket,
        Paint()
          ..color = _ink
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.4,
      );
      final center = (x0 + x1) / 2;
      final labelAnchor = center.clamp(size.width * .23, size.width * .77);
      final subtotalValue = values
          .getRange(subtotal.startIndex, subtotal.endIndex + 1)
          .reduce((a, b) => a + b);
      final approximate = options.approximateIndices.any(
        (index) => index >= subtotal.startIndex && index <= subtotal.endIndex,
      );
      _chartText(
        canvas,
        '${shareLabel(subtotalValue, approximate)} ${subtotal.label}',
        Offset(labelAnchor, y - 11),
        maxWidth: 2 * math.min(labelAnchor, size.width - labelAnchor) - 4,
        size: 13,
        bold: true,
      );
    }
  }

  @override
  bool shouldRepaint(_StackedBar old) =>
      labels != old.labels || values != old.values || options != old.options;
}

(List<Color>, Map<String, List<Color>>) _sliceColors(List<String?> categories) {
  if (categories.every((group) => group == null)) return (const [], const {});
  const families = [
    [Color(0xFF472D05), Color(0xFFAE7B1B), Color(0xFFFFF1C6)],
    [Color(0xFF073B38), Color(0xFF358E85), Color(0xFFDBFFF6)],
    [Color(0xFF331B59), Color(0xFF8C6DCD), Color(0xFFF4ECFF)],
    [Color(0xFF4F1C24), Color(0xFFB26E78), Color(0xFFFFEBEF)],
    [Color(0xFF172D56), Color(0xFF6685BB), Color(0xFFF0F6FF)],
    [Color(0xFF302E13), Color(0xFF89844F), Color(0xFFF5F3D4)],
    [Color(0xFF392219), Color(0xFFAA785E), Color(0xFFFFEFE8)],
  ];
  final familyByGroup = <String, List<Color>>{};
  final groupSwatches = <String, List<Color>>{};
  final colors = <Color>[];
  var nextFamily = 0;
  for (final group in categories) {
    if (group == null) {
      colors.add(families[nextFamily++][1]);
      continue;
    }
    final family = familyByGroup.putIfAbsent(
      group,
      () => families[nextFamily++],
    );
    final swatches = groupSwatches.putIfAbsent(group, () => []);
    final color = family[swatches.length];
    swatches.add(color);
    colors.add(color);
  }
  return (colors, groupSwatches);
}
