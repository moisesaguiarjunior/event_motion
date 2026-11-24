import 'dart:convert';
import 'editorial_fields.dart';

/// One scale for uncertainty estimates, or independent zero-based bar panels.
final class QuantitativeDocument {
  QuantitativeDocument._(this.data);
  final Map<String, Object?> data;
  bool get intervals => data['kind'] == 'intervals';

  static double number(Object? raw, String path) {
    if (raw is! num || !raw.isFinite || raw.abs() > 1e12) {
      throw FormatException('$path: expected finite number within ±1e12');
    }
    return raw.toDouble();
  }

  /// Coordinates used both by the painter and acceptance checks.
  static double position(
    double value,
    double low,
    double high,
    double start,
    double width,
  ) => start + (value - low) / (high - low) * width;

  factory QuantitativeDocument.parse(String input) {
    final d = editorialObject(
      jsonDecode(input),
      r'$',
      const {
        'kind',
        'title',
        'subtitle',
        'hero',
        'context',
        'footnote',
        'sources',
      },
      optional: const {'axis', 'rows', 'panels', 'alt_text'},
    );
    for (final (key, limit) in [
      ('title', 64),
      ('subtitle', 110),
      ('context', 170),
      ('footnote', 240),
    ]) {
      editorialCopy(d[key], '\$.$key', limit);
    }
    if (d.containsKey('alt_text')) {
      editorialCopy(d['alt_text'], r'$.alt_text', 1400);
    }
    final sources = editorialList(d['sources'], r'$.sources', 1, 4);
    final ids = <String>{};
    for (final (i, raw) in sources.indexed) {
      final s = editorialObject(raw, '\$.sources[$i]', const {'id', 'label'});
      final id = editorialCopy(s['id'], '\$.sources[$i].id', 20);
      if (!RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(id) || !ids.add(id)) {
        throw const FormatException(
          r'$.sources: expected distinct citation IDs',
        );
      }
      editorialCopy(s['label'], '\$.sources[$i].label', 80);
    }
    void checkInline(Object? value) {
      if (value is String) {
        for (final match in RegExp(r'\[([A-Za-z0-9_-]+)\]').allMatches(value)) {
          if (!ids.contains(match[1])) {
            throw const FormatException(
              r'$: inline citation missing from source key',
            );
          }
        }
      } else if (value is Map) {
        for (final entry in value.entries) {
          if (entry.key != 'sources' && entry.key != 'alt_text') {
            checkInline(entry.value);
          }
        }
      } else if (value is List) {
        for (final entry in value) {
          checkInline(entry);
        }
      }
    }

    checkInline(d);
    void citations(Object? raw, String path) {
      final entries = editorialList(raw, path, 1, 4);
      if (entries.toSet().length != entries.length ||
          entries.any((id) => !ids.contains(id))) {
        throw FormatException('$path: expected unique IDs from source key');
      }
    }

    final hero = editorialObject(d['hero'], r'$.hero', const {
      'value',
      'caption',
      'source_ids',
    });
    editorialCopy(hero['value'], r'$.hero.value', 28);
    editorialCopy(hero['caption'], r'$.hero.caption', 200);
    citations(hero['source_ids'], r'$.hero.source_ids');
    if (d['kind'] == 'intervals') {
      if (d.containsKey('panels')) {
        throw const FormatException(r'$.panels: unsupported for intervals');
      }
      final a = editorialObject(d['axis'], r'$.axis', const {
        'min',
        'max',
        'suffix',
      });
      final low = number(a['min'], r'$.axis.min');
      final high = number(a['max'], r'$.axis.max');
      if (low >= 0 || high <= 0 || high - low < .0001) {
        throw const FormatException(
          r'$.axis: expected signed range containing zero',
        );
      }
      editorialCopy(a['suffix'], r'$.axis.suffix', 5);
      final rows = editorialList(d['rows'], r'$.rows', 2, 4);
      final names = <String>{};
      for (final (i, raw) in rows.indexed) {
        final p = '\$.rows[$i]';
        final r = editorialObject(raw, p, const {
          'label',
          'estimate',
          'lower',
          'upper',
          'note',
          'source_ids',
        });
        if (!names.add(editorialCopy(r['label'], '$p.label', 46))) {
          throw FormatException('$p.label: duplicate');
        }
        editorialCopy(r['note'], '$p.note', 56);
        citations(r['source_ids'], '$p.source_ids');
        final l = number(r['lower'], '$p.lower');
        final e = number(r['estimate'], '$p.estimate');
        final u = number(r['upper'], '$p.upper');
        if (l < low || l > e || e > u || u > high) {
          throw FormatException(
            '$p: expected axis.min ≤ lower ≤ estimate ≤ upper ≤ axis.max',
          );
        }
      }
    } else if (d['kind'] == 'bar_panels') {
      if (d.containsKey('axis') || d.containsKey('rows')) {
        throw const FormatException(r'$: bar panels have independent axes');
      }
      for (final (i, raw) in editorialList(
        d['panels'],
        r'$.panels',
        2,
        2,
      ).indexed) {
        final p = '\$.panels[$i]';
        final panel = editorialObject(raw, p, const {
          'title',
          'unit',
          'maximum',
          'note',
          'bars',
          'source_ids',
        });
        editorialCopy(panel['title'], '$p.title', 52);
        editorialCopy(panel['unit'], '$p.unit', 48);
        editorialCopy(panel['note'], '$p.note', 125);
        citations(panel['source_ids'], '$p.source_ids');
        final maximum = number(panel['maximum'], '$p.maximum');
        if (maximum <= 0) {
          throw FormatException('$p.maximum: expected positive scale');
        }
        final names = <String>{};
        for (final (j, entry) in editorialList(
          panel['bars'],
          '$p.bars',
          2,
          4,
        ).indexed) {
          final b = '$p.bars[$j]';
          final bar = editorialObject(
            entry,
            b,
            const {'label', 'value'},
            optional: const {'annotation'},
          );
          if (!names.add(editorialCopy(bar['label'], '$b.label', 16))) {
            throw FormatException('$b.label: duplicate');
          }
          final v = number(bar['value'], '$b.value');
          if (v < 0 || v > maximum) {
            throw FormatException('$b.value: expected 0 ≤ value ≤ maximum');
          }
          if (bar.containsKey('annotation')) {
            editorialCopy(bar['annotation'], '$b.annotation', 32);
          }
        }
      }
    } else {
      throw const FormatException(r'$.kind: expected intervals or bar_panels');
    }
    return QuantitativeDocument._(d);
  }
}
