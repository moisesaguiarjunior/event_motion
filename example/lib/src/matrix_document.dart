import 'dart:convert';

import 'editorial_fields.dart';

typedef MatrixRow = ({
  String date,
  String change,
  String cloud,
  String operator,
  String? operatorCloud,
  List<String> sourceIds,
});
typedef MatrixHeroStat = ({String value, String caption});

final class MatrixDocument {
  MatrixDocument._(
    this.title,
    this.columns,
    this.rows,
    this.footer,
    this.sources,
    this.heroStat,
  );

  final String title;
  final List<String> columns;
  final List<MatrixRow> rows;
  final String footer;
  final Map<String, String> sources;
  final MatrixHeroStat? heroStat;

  factory MatrixDocument.parse(String source) {
    const root = r'$';
    final document = editorialObject(
      jsonDecode(source),
      root,
      const {'version', 'title', 'columns', 'rows', 'footer', 'sources'},
      optional: const {'hero_stat'},
    );
    if (document['version'] != 1) {
      throw FormatException('$root.version: expected 1');
    }
    final sources = <String, String>{};
    final rawSources = editorialList(
      document['sources'],
      '$root.sources',
      1,
      7,
    );
    for (final (index, raw) in rawSources.indexed) {
      final path = '$root.sources[$index]';
      final source = editorialObject(raw, path, const {'id', 'label'});
      final id = editorialCopy(source['id'], '$path.id', 12);
      if (!_sourceId.hasMatch(id) || sources.containsKey(id)) {
        throw FormatException('$path.id: expected a unique source ID');
      }
      sources[id] = editorialCopy(source['label'], '$path.label', 30);
    }

    final rows = <MatrixRow>[];
    final rawRows = editorialList(document['rows'], '$root.rows', 2, 4);
    for (final (index, raw) in rawRows.indexed) {
      final path = '$root.rows[$index]';
      final row = editorialObject(
        raw,
        path,
        const {'date', 'change', 'cloud', 'operator', 'source_ids'},
        optional: const {'operator_cloud'},
      );
      final date = editorialCopy(row['date'], '$path.date', 10);
      final parsed = DateTime.tryParse(date);
      if (parsed == null || parsed.toIso8601String().split('T').first != date) {
        throw FormatException(
          '$path.date: expected a calendar date (YYYY-MM-DD)',
        );
      }
      if (rows.isNotEmpty && date.compareTo(rows.last.date) < 0) {
        throw FormatException(
          '$path.date: rows must be in chronological order',
        );
      }
      final citations = <String>{};
      final rawCitations = editorialList(
        row['source_ids'],
        '$path.source_ids',
        1,
        3,
      );
      for (final (index, rawId) in rawCitations.indexed) {
        if (rawId is! String ||
            !sources.containsKey(rawId) ||
            !citations.add(rawId)) {
          throw FormatException(
            '$path.source_ids[$index]: unknown or repeated source ID',
          );
        }
      }
      final operator = editorialCopy(row['operator'], '$path.operator', 96);
      final operatorCloud = row.containsKey('operator_cloud')
          ? editorialCopy(row['operator_cloud'], '$path.operator_cloud', 48)
          : null;
      if (operatorCloud != null &&
          (operator + operatorCloud).runes.length > 96) {
        throw FormatException(
          '$path.operator_cloud: both operator notes must fit within 96 characters',
        );
      }
      rows.add((
        date: date,
        change: editorialCopy(row['change'], '$path.change', 52),
        cloud: editorialCopy(row['cloud'], '$path.cloud', 96),
        operator: operator,
        operatorCloud: operatorCloud,
        sourceIds: List.unmodifiable(citations),
      ));
    }

    final columns = editorialList(document['columns'], '$root.columns', 4, 4);
    MatrixHeroStat? heroStat;
    if (document.containsKey('hero_stat')) {
      const path = '$root.hero_stat';
      final hero = editorialObject(document['hero_stat'], path, const {
        'value',
        'caption',
      });
      final caption = editorialCopy(hero['caption'], '$path.caption', 150);
      for (final citation in _citation.allMatches(caption)) {
        if (!sources.containsKey(citation[1])) {
          throw const FormatException(
            '$path.caption: expected source IDs from the footer',
          );
        }
      }
      heroStat = (
        value: editorialCopy(hero['value'], '$path.value', 16),
        caption: caption,
      );
    }
    return MatrixDocument._(
      editorialCopy(document['title'], '$root.title', 62),
      List.unmodifiable([
        for (final (index, value) in columns.indexed)
          editorialCopy(value, '$root.columns[$index]', index == 0 ? 10 : 23),
      ]),
      List.unmodifiable(rows),
      editorialCopy(document['footer'], '$root.footer', 110),
      Map.unmodifiable(sources),
      heroStat,
    );
  }
}

final _sourceId = RegExp(r'^[a-zA-Z0-9_-]+$');
final _citation = RegExp(r'\[([a-zA-Z0-9_-]+)\]');
