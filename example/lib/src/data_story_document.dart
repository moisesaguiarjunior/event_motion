import 'dart:math' as math;

import 'editorial_fields.dart';

typedef ReferenceLine = ({double value, String label});
typedef ChartAxis = ({
  double minimum,
  double maximum,
  String suffix,
  bool explicitBounds,
  List<ReferenceLine> referenceLines,
});
typedef ChartSubtotal = ({int startIndex, int endIndex, String label});

/// Chart options shared by preflight validation and the renderer.
final class DataStoryChart {
  DataStoryChart._(
    this.kind, {
    this.axis,
    this.subtotal,
    this.sliceGroups = const [],
    this.valuePrefix = '',
    this.approximateIndices = const {},
  });

  final String kind;
  final ChartAxis? axis;
  final ChartSubtotal? subtotal;
  final List<String?> sliceGroups;
  final String valuePrefix;
  final Set<int> approximateIndices;

  bool get isCompactExport => kind == 'paired_dot' || kind == 'stacked_bar';

  factory DataStoryChart.parse(Map<String, Object?> data) {
    const root = r'$';
    final kind = data.containsKey('chart_kind') ? data['chart_kind'] : 'line';
    if (kind is! String ||
        !const {
          'line',
          'paired_dot',
          'composition',
          'stacked_bar',
        }.contains(kind)) {
      throw const FormatException(
        '$root.chart_kind: expected line, paired_dot, composition or stacked_bar',
      );
    }
    final isShareChart = kind == 'composition' || kind == 'stacked_bar';
    final labelsPath = '$root.labels';
    final labels = editorialList(data['labels'], labelsPath, 2, 7);
    final labelLimit = isShareChart ? 38 : (kind == 'paired_dot' ? 24 : 9);
    final names = <String>{};
    for (final (index, label) in labels.indexed) {
      final path = '$labelsPath[$index]';
      if (!names.add(editorialCopy(label, path, labelLimit))) {
        throw FormatException('$path: expected a distinct label');
      }
    }

    final count = switch (kind) {
      'paired_dot' => (2, 2),
      'line' => (1, 3),
      _ => (1, 1),
    };
    final series = editorialList(
      data['series'],
      '$root.series',
      count.$1,
      count.$2,
    );
    final values = <double>[];
    for (final (index, raw) in series.indexed) {
      final path = '$root.series[$index]';
      final item = editorialObject(raw, path, const {'name', 'values'});
      editorialCopy(item['name'], '$path.name', 23);
      final points = editorialList(
        item['values'],
        '$path.values',
        labels.length,
        labels.length,
      );
      for (final (point, value) in points.indexed) {
        final number = _number(value, '$path.values[$point]');
        if (isShareChart && number <= 0) {
          throw FormatException(
            '$path.values[$point]: expected a positive share',
          );
        }
        values.add(number);
      }
    }

    const axisFields = {'y_min', 'y_max', 'axis_suffix', 'reference_lines'};
    const stackFields = {'subtotal', 'value_prefix', 'approximate_indices'};
    final allowed = switch (kind) {
      'composition' => const {'slice_groups'},
      'stacked_bar' => stackFields,
      _ => axisFields,
    };
    for (final field in {...axisFields, ...stackFields, 'slice_groups'}) {
      if (data.containsKey(field) && !allowed.contains(field)) {
        throw FormatException('$root.$field: unsupported for $kind');
      }
    }

    if (!isShareChart) {
      return DataStoryChart._(kind, axis: _axis(data, values));
    }
    if ((values.reduce((a, b) => a + b) - 100).abs() > 1e-8) {
      throw const FormatException(
        '$root.series[0].values: expected positive shares totaling 100',
      );
    }
    return DataStoryChart._(
      kind,
      sliceGroups: data.containsKey('slice_groups')
          ? _sliceGroups(data['slice_groups'], labels.length)
          : const [],
      subtotal: data.containsKey('subtotal')
          ? _subtotal(data['subtotal'], labels.length)
          : null,
      valuePrefix: data.containsKey('value_prefix')
          ? editorialCopy(data['value_prefix'], '$root.value_prefix', 4)
          : '',
      approximateIndices: data.containsKey('approximate_indices')
          ? _approximateIndices(data['approximate_indices'], labels.length)
          : const {},
    );
  }
}

double _number(Object? value, String path) {
  if (value is! num || !value.isFinite || value.abs() > 1e12) {
    throw FormatException(
      '$path: expected a finite number between -1e12 and 1e12',
    );
  }
  return value.toDouble();
}

ChartAxis _axis(Map<String, Object?> data, List<double> values) {
  const root = r'$';
  final references = <ReferenceLine>[];
  if (data.containsKey('reference_lines')) {
    final entries = editorialList(
      data['reference_lines'],
      '$root.reference_lines',
      0,
      3,
    );
    final referenceValues = <double>{};
    for (final (index, entry) in entries.indexed) {
      final path = '$root.reference_lines[$index]';
      final line = editorialObject(entry, path, const {'value', 'label'});
      final value = _number(line['value'], '$path.value');
      if (!referenceValues.add(value)) {
        throw FormatException(
          '$path.value: expected a distinct reference value',
        );
      }
      references.add((
        value: value,
        label: editorialCopy(line['label'], '$path.label', 32),
      ));
    }
  }
  final valuesOnAxis = [...values, ...references.map((line) => line.value)];
  final lower = valuesOnAxis.reduce(math.min);
  final upper = valuesOnAxis.reduce(math.max);
  final hasMinimum = data.containsKey('y_min');
  final hasMaximum = data.containsKey('y_max');
  final minimum = hasMinimum
      ? _number(data['y_min'], '$root.y_min')
      : math.min(0.0, lower);
  var maximum = hasMaximum
      ? _number(data['y_max'], '$root.y_max')
      : math.max(0.0, upper);
  if (maximum - minimum < .0001 && !hasMaximum && !hasMinimum) {
    maximum = minimum + .0001;
  }
  if (minimum > lower) {
    throw const FormatException(
      '$root.y_min: expected a bound at or below every value and reference',
    );
  }
  if (maximum < upper || maximum <= minimum) {
    throw const FormatException(
      '$root.y_max: expected a bound above y_min and at or above every value and reference',
    );
  }
  return (
    minimum: minimum,
    maximum: maximum,
    explicitBounds: hasMinimum || hasMaximum,
    suffix: data.containsKey('axis_suffix')
        ? editorialCopy(data['axis_suffix'], '$root.axis_suffix', 5)
        : '',
    referenceLines: List.unmodifiable(references),
  );
}

List<String?> _sliceGroups(Object? input, int count) {
  const path = r'$.slice_groups';
  final entries = editorialList(input, path, count, count);
  final counts = <String, int>{};
  final groups = <String?>[];
  for (final (index, entry) in entries.indexed) {
    final name = entry == null
        ? null
        : editorialCopy(entry, '$path[$index]', 24);
    groups.add(name);
    if (name != null) {
      counts.update(name, (size) => size + 1, ifAbsent: () => 1);
    }
  }
  if (counts.values.any((size) => size < 2 || size > 3)) {
    throw const FormatException(
      '$path: expected each named group to contain two or three slices',
    );
  }
  return List.unmodifiable(groups);
}

ChartSubtotal _subtotal(Object? input, int count) {
  const path = r'$.subtotal';
  final entry = editorialObject(input, path, const {
    'start_index',
    'end_index',
    'label',
  });
  final start = entry['start_index'];
  final end = entry['end_index'];
  if (start is! int || start < 0 || start >= count - 1) {
    throw const FormatException(
      '$path.start_index: expected an index before the last slice',
    );
  }
  if (end is! int || end <= start || end >= count) {
    throw const FormatException(
      '$path.end_index: expected a later slice index within the bar',
    );
  }
  return (
    startIndex: start,
    endIndex: end,
    label: editorialCopy(entry['label'], '$path.label', 60),
  );
}

Set<int> _approximateIndices(Object? input, int count) {
  const path = r'$.approximate_indices';
  final entries = editorialList(input, path, 0, count);
  final indices = <int>{};
  for (final (index, entry) in entries.indexed) {
    if (entry is! int || entry < 0 || entry >= count || !indices.add(entry)) {
      throw FormatException('$path[$index]: expected a unique slice index');
    }
  }
  return Set.unmodifiable(indices);
}
