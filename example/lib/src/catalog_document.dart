import 'dart:convert';

import 'editorial_fields.dart';

enum DiagramKind { flow, bars, curve, orbit }

typedef CatalogTile = ({
  String id,
  String title,
  String note,
  DiagramKind diagram,
});

/// Validated copy and traversal order for the animated editorial grid.
final class CatalogDocument {
  CatalogDocument._(
    this.title,
    this.subtitle,
    List<CatalogTile> tiles,
    List<String> order,
  ) : tiles = List.unmodifiable(tiles),
      order = List.unmodifiable(order);

  final String title;
  final String subtitle;
  final List<CatalogTile> tiles;
  final List<String> order;

  factory CatalogDocument.parse(String source) =>
      CatalogDocument.fromJson(jsonDecode(source));

  factory CatalogDocument.fromJson(Object? value) {
    const root = r'$';
    final document = editorialObject(value, root, const {
      'version',
      'title',
      'subtitle',
      'tiles',
      'order',
    });
    if (document['version'] != 1) {
      throw FormatException('$root.version: expected 1');
    }
    final title = editorialCopy(document['title'], '$root.title', 40);
    final subtitle = editorialCopy(document['subtitle'], '$root.subtitle', 88);
    final input = editorialList(document['tiles'], '$root.tiles', 8, 12);
    final tiles = <CatalogTile>[];
    final ids = <String>{};
    for (final (index, raw) in input.indexed) {
      final path = '$root.tiles[$index]';
      final tile = editorialObject(raw, path, const {
        'id',
        'title',
        'note',
        'diagram',
      });
      final id = editorialId(tile['id'], '$path.id');
      if (!ids.add(id)) throw FormatException('$path.id: duplicate tile $id');
      final diagram = DiagramKind.values
          .where((kind) => kind.name == tile['diagram'])
          .firstOrNull;
      if (diagram == null) {
        throw FormatException(
          '$path.diagram: expected flow, bars, curve or orbit',
        );
      }
      tiles.add((
        id: id,
        title: editorialCopy(tile['title'], '$path.title', 22),
        note: editorialCopy(tile['note'], '$path.note', 43),
        diagram: diagram,
      ));
    }
    final sequence = editorialList(
      document['order'],
      '$root.order',
      input.length,
      input.length,
    );
    final order = <String>[];
    for (final (index, raw) in sequence.indexed) {
      final path = '$root.order[$index]';
      final id = editorialId(raw, path);
      if (!ids.remove(id)) {
        throw FormatException('$path: unknown or repeated tile $id');
      }
      order.add(id);
    }
    return CatalogDocument._(title, subtitle, tiles, order);
  }
}
