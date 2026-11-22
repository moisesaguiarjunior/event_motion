import 'dart:convert';
import 'dart:math' as math;

import 'package:event_motion/event_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:fluvie/fluvie.dart' as video;

import 'src/data_story_document.dart';
import 'src/motion_clock.dart';

part 'src/data_story_charts.dart';

const _ink = Color(0xFF182A23);
const _paper = Color(0xFFF4F1E7);
const _panel = Color(0xFFFFFDF8);
const _rule = Color(0xFFD6D9CD);
const _colors = [Color(0xFF087656), Color(0xFFB54C2D), Color(0xFF3F5793)];

typedef _Series = ({String name, List<num> values});
typedef _Detail = ({String label, String title, String note, String source});

video.Video build(String input, {required bool animated}) {
  final data = jsonDecode(input) as Map<String, dynamic>;
  final chart = DataStoryChart.parse(data);
  final frames = animated ? 192 : 1;
  return video.Video(
    width: chart.isCompactExport ? 1080 : 1440,
    height: chart.isCompactExport ? 1350 : 1800,
    fps: 24,
    poster: video.Time.frames(frames - 1),
    scenes: [
      video.Scene(
        duration: video.Time.frames(frames),
        children: [
          Positioned.fill(
            child: FittedBox(
              child: SizedBox(
                width: 480,
                height: 600,
                child: atMotionTime(MotionTimeline(const []), (frame) {
                  double reveal(int at, int duration) => animated
                      ? Curves.easeOutCubic.transform(
                          frame.progressSince(
                            Duration(milliseconds: at),
                            Duration(milliseconds: duration),
                          ),
                        )
                      : 1;
                  return _Story(
                    data,
                    chart,
                    animated: animated,
                    chart: reveal(480, 1450),
                    evidence: reveal(2450, 420),
                    timeline: reveal(4150, 420),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _Story extends StatelessWidget {
  const _Story(
    this.data,
    this.options, {
    required this.animated,
    required this.chart,
    required this.evidence,
    required this.timeline,
  });

  final Map<String, dynamic> data;
  final DataStoryChart options;
  final bool animated;
  final double chart;
  final double evidence;
  final double timeline;

  List<_Detail> _details(String key) => [
    for (final item in data[key] as List<dynamic>)
      (
        label: item['label'] as String,
        title: item['title'] as String,
        note: item['note'] as String,
        source: item['source'] as String,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final cards = _details('evidence');
    final dates = _details('timeline');
    final series = <_Series>[
      for (final item in data['series'] as List<dynamic>)
        (
          name: item['name'] as String,
          values: (item['values'] as List<dynamic>).cast<num>(),
        ),
    ];
    final annotation = data['annotation'] as Map<String, dynamic>;
    final labels = (data['labels'] as List<dynamic>).cast<String>();
    return ColoredBox(
      color: _paper,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Container(width: 37, height: 4, color: _colors.first),
            ),
            const SizedBox(height: 9),
            _text(data['title'] as String, 30, bold: true, lines: 2),
            const SizedBox(height: 6),
            _text(data['subtitle'] as String, 13, lines: 2),
            const SizedBox(height: 11),
            Expanded(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _panel,
                  border: Border.all(color: _rule),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(11, 9, 11, 7),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _text(
                        data['chart_title'] as String,
                        15,
                        bold: true,
                        lines: 2,
                      ),
                      const SizedBox(height: 3),
                      _text('${data['unit']}  ·  ${data['chart_source']}', 9.5),
                      const SizedBox(height: 3),
                      if (options.kind == 'paired_dot')
                        _PairedLegend(series)
                      else if (options.kind == 'line')
                        Wrap(
                          spacing: 12,
                          children: [
                            for (final (index, item) in series.indexed)
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 10,
                                    height: 2,
                                    color: _colors[index],
                                  ),
                                  const SizedBox(width: 3),
                                  _text(
                                    item.name,
                                    10,
                                    bold: true,
                                    color: _colors[index],
                                  ),
                                ],
                              ),
                          ],
                        ),
                      Expanded(
                        child: switch (options.kind) {
                          'composition' => _Composition(
                            labels: labels,
                            values: series.single.values,
                            animated: animated,
                            sliceGroups: options.sliceGroups,
                          ),
                          'stacked_bar' => Opacity(
                            opacity: chart,
                            child: CustomPaint(
                              painter: _StackedBar(
                                labels,
                                series.single.values,
                                options,
                              ),
                            ),
                          ),
                          'paired_dot' => CustomPaint(
                            painter: _PairedDots(
                              labels,
                              series,
                              options.axis!,
                              chart,
                            ),
                          ),
                          _ => CustomPaint(
                            painter: _Plot(
                              labels: labels,
                              series: series,
                              progress: chart,
                              annotation: annotation,
                              axis: options.axis!,
                            ),
                          ),
                        },
                      ),
                      Opacity(
                        opacity: chart,
                        child: _text(
                          annotation['note'] as String,
                          10,
                          bold: true,
                          lines: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (cards.isNotEmpty || dates.isNotEmpty) ...[
              const SizedBox(height: 9),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (cards.isNotEmpty)
                    Expanded(
                      child: Opacity(
                        opacity: evidence,
                        child: _Details(
                          data['evidence_title'] as String,
                          cards,
                        ),
                      ),
                    ),
                  if (cards.isNotEmpty && dates.isNotEmpty)
                    const SizedBox(width: 10),
                  if (dates.isNotEmpty)
                    Expanded(
                      child: Opacity(
                        opacity: timeline,
                        child: _Details(
                          data['timeline_title'] as String,
                          dates,
                        ),
                      ),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            _text(
              (data['sources'] as List<dynamic>).join('  ·  '),
              8.5,
              lines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

Text _text(
  String text,
  double size, {
  bool bold = false,
  int lines = 1,
  Color color = _ink,
}) => Text(
  text,
  maxLines: lines,
  overflow: TextOverflow.ellipsis,
  style: TextStyle(
    fontFamily: 'Roboto',
    fontSize: size,
    height: 1.13,
    fontWeight: bold ? FontWeight.w800 : FontWeight.w400,
    color: color,
  ),
);

class _Details extends StatelessWidget {
  const _Details(this.title, this.details);

  final String title;
  final List<_Detail> details;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _text(title, 12, bold: true),
      const SizedBox(height: 4),
      for (final (index, detail) in details.indexed) ...[
        if (index > 0) const SizedBox(height: 3),
        Container(
          height: 43,
          padding: const EdgeInsets.fromLTRB(7, 4, 7, 4),
          decoration: const BoxDecoration(
            color: _panel,
            border: Border(top: BorderSide(color: _rule, width: 2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _text(detail.label, 11.5, bold: true, color: _colors.first),
                  const SizedBox(width: 6),
                  Expanded(child: _text(detail.title, 10.5, bold: true)),
                ],
              ),
              _text('${detail.note}  ${detail.source}', 9.3, lines: 2),
            ],
          ),
        ),
      ],
    ],
  );
}

class _Composition extends StatelessWidget {
  const _Composition({
    required this.labels,
    required this.values,
    required this.animated,
    required this.sliceGroups,
  });

  final List<String> labels;
  final List<num> values;
  final bool animated;
  final List<String?> sliceGroups;

  @override
  Widget build(BuildContext context) {
    const fallback = video.FluvieTokens.fallback();
    final (colors, groups) = _sliceColors(sliceGroups);
    final tokens = colors.isEmpty
        ? fallback
        : fallback.copyWith(palette: video.ChartPalette(colors));
    final parts = Map<String, num>.fromIterables(labels, values);
    return Column(
      children: [
        Expanded(
          child: video.FluvieTokensScope(
            tokens: tokens,
            child: video.Chart.donut(
              data: parts,
              reveal: video.Time.frames(animated ? 46 : 0),
            ),
          ),
        ),
        for (final (index, label) in labels.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 5),
            child: Row(
              children: [
                Container(
                  width: 11,
                  height: 11,
                  color: tokens.palette.colorAt(index),
                ),
                const SizedBox(width: 8),
                Expanded(child: _text(label, 13, lines: 2)),
                const SizedBox(width: 8),
                _text('${values[index]}%', 14, bold: true),
              ],
            ),
          ),
        if (groups.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Wrap(
              spacing: 12,
              runSpacing: 3,
              children: [
                for (final group in groups.entries)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      for (final color in group.value)
                        SizedBox(
                          width: 7,
                          height: 8,
                          child: ColoredBox(color: color),
                        ),
                      const SizedBox(width: 5),
                      _text(group.key, 10, bold: true),
                    ],
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Plot extends CustomPainter {
  const _Plot({
    required this.labels,
    required this.series,
    required this.progress,
    required this.annotation,
    required this.axis,
  });

  final List<String> labels;
  final List<_Series> series;
  final double progress;
  final Map<String, dynamic> annotation;
  final ChartAxis axis;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.height <= 32 || size.width <= 80) return;
    final low = axis.minimum;
    final span = axis.maximum - low;
    final plot = Rect.fromLTRB(35, 7, size.width - 21, size.height - 18);
    Offset point(int index, num value) => Offset(
      plot.left + plot.width * index / (labels.length - 1),
      plot.bottom - plot.height * (value - low) / span,
    );
    final ticks = plot.height < 76
        ? 2
        : axis.explicitBounds && span == span.round() && span >= 2 && span <= 6
        ? span.round()
        : 4;
    String axisLabel(double value) =>
        '${axis.explicitBounds ? _shortNumber(value) : _number(value)}${axis.suffix}';
    for (var tick = 0; tick <= ticks; tick++) {
      final value = low + span * tick / ticks;
      final y = point(0, value).dy;
      canvas.drawLine(
        Offset(plot.left, y),
        Offset(plot.right, y),
        Paint()..color = _rule,
      );
      _label(
        canvas,
        axisLabel(value),
        Offset(plot.left - 5, y),
        rightAligned: true,
      );
    }
    for (final (index, label) in labels.indexed) {
      _label(canvas, label, Offset(point(index, low).dx, plot.bottom + 9));
    }
    final references = axis.referenceLines.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    var labelY = plot.top;
    for (final reference in references) {
      final y = point(0, reference.value).dy;
      _dash(canvas, Offset(plot.left, y), Offset(plot.right, y));
      labelY = math.max(labelY, y - 7);
      _chartText(
        canvas,
        reference.label,
        Offset(plot.right - 3, labelY),
        alignment: 1,
        size: 9,
        paper: _panel,
      );
      labelY += 12;
    }
    if (progress == 0) return;
    canvas.save();
    canvas.clipRect(
      Rect.fromLTRB(
        0,
        0,
        plot.left + (plot.width + 6) * progress,
        plot.bottom + 5,
      ),
    );
    for (final (index, item) in series.indexed) {
      final points = [
        for (final (x, value) in item.values.indexed) point(x, value),
      ];
      final line = Path()..addPolygon(points, false);
      final color = _colors[index];
      canvas.drawPath(
        line,
        Paint()
          ..color = color
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2,
      );
      for (final dot in points) {
        canvas.drawCircle(dot, 2.9, Paint()..color = color);
      }
    }
    final seriesIndex = annotation['series_index'] as int;
    final labelIndex = annotation['label_index'] as int;
    final value = series[seriesIndex].values[labelIndex];
    final marked = point(labelIndex, value);
    canvas.drawCircle(
      marked,
      5,
      Paint()
        ..color = _colors[seriesIndex]
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    _label(
      canvas,
      axisLabel(value.toDouble()),
      marked +
          Offset(
            labelIndex == labels.length - 1 ? -14 : 14,
            marked.dy < 17 ? 12 : -9,
          ),
    );
    canvas.restore();
  }

  String _number(double value) => value
      .toStringAsFixed(value % 1 == 0 ? 0 : 2)
      .replaceFirst(RegExp(r'(\.\d*?[1-9])0+$'), r'$1');

  void _label(
    Canvas canvas,
    String content,
    Offset anchor, {
    bool rightAligned = false,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: content,
        style: const TextStyle(
          color: _ink,
          fontFamily: 'Roboto',
          fontSize: 8.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      anchor -
          Offset(painter.width * (rightAligned ? 1 : .5), painter.height / 2),
    );
    painter.dispose();
  }

  @override
  bool shouldRepaint(_Plot oldDelegate) =>
      progress != oldDelegate.progress ||
      labels != oldDelegate.labels ||
      series != oldDelegate.series ||
      annotation != oldDelegate.annotation ||
      axis != oldDelegate.axis;
}
