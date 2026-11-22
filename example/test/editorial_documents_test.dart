import 'dart:convert';
import 'dart:io';

import 'package:event_motion_example/src/catalog_document.dart';
import 'package:event_motion_example/src/team_document.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _fixture(String name) =>
    jsonDecode(File('fixtures/$name.json').readAsStringSync())
        as Map<String, dynamic>;

Matcher _errorAt(String field) => isA<FormatException>().having(
  (error) => error.message,
  'field',
  startsWith(field),
);

void main() {
  test('a twelve-tile catalog keeps layout order separate from playback', () {
    final input = _fixture('editorial_catalog');
    final tiles = input['tiles'] as List<dynamic>;
    for (var index = 8; index < 12; index++) {
      tiles.add({...tiles.first as Map<String, dynamic>, 'id': 'tile-$index'});
    }
    final ids = tiles.map((tile) => tile['id'] as String).toList();
    input['order'] = ids.reversed.toList();

    final document = CatalogDocument.fromJson(input);

    expect(document.tiles.map((tile) => tile.id), ids);
    expect(document.order, ids.reversed);
    expect(
      document.tiles.map((tile) => tile.diagram).toSet(),
      DiagramKind.values.toSet(),
    );
  });

  test('a catalog rejects invalid fields before the renderer runs', () {
    final input = _fixture('editorial_catalog');
    final tiles = input['tiles'] as List<dynamic>;
    final first = tiles.first as Map<String, dynamic>;
    final second = tiles[1] as Map<String, dynamic>;
    final firstId = first['id'];
    first['id'] = second['id'];
    expect(
      () => CatalogDocument.fromJson(input),
      throwsA(_errorAt(r'$.tiles[1].id')),
    );
    first['id'] = firstId;
    first['diagram'] = 'pie';
    expect(
      () => CatalogDocument.fromJson(input),
      throwsA(_errorAt(r'$.tiles[0].diagram')),
    );
    first['diagram'] = 'flow';
    first['note'] = 'á' * 44;
    expect(
      () => CatalogDocument.fromJson(input),
      throwsA(_errorAt(r'$.tiles[0].note')),
    );
    first['note'] = 'Uma etapa breve.';
    (input['order'] as List<dynamic>)[0] = 'missing';
    expect(
      () => CatalogDocument.fromJson(input),
      throwsA(_errorAt(r'$.order[0]')),
    );
  });

  test(
    'the same team has distinct characters and a fixed activation order',
    () {
      final input = _fixture('workshop_team');
      final members = input['members'] as List<dynamic>;
      final lead = input['lead'] as Map<String, dynamic>;
      TeamDocument parse() => TeamDocument.parse(jsonEncode(input));
      final document = parse();
      expect(
        document.members.map((member) => member.id),
        members.map((member) => member['id']),
      );
      expect({
        document.lead.figure,
        ...document.members.map((member) => member.figure),
      }, WorkshopFigure.values.toSet());

      final first = members.first as Map<String, dynamic>;
      final figure = first['figure'];
      first['figure'] = lead['figure'];
      expect(parse, throwsA(_errorAt(r'$.members[0].figure')));
      first['figure'] = 'unknown';
      expect(parse, throwsA(_errorAt(r'$.members[0].figure')));
      first['figure'] = figure;
      first['id'] = lead['id'];
      expect(parse, throwsA(_errorAt(r'$.members[0].id')));
    },
  );
}
