import 'dart:convert';
import 'dart:io';

import 'package:alchemist/alchemist.dart' show loadFonts;
import 'package:event_motion_example/data_story.dart' as data_story;
import 'package:event_motion_example/editorial_catalog.dart' as catalog;
import 'package:event_motion_example/src/catalog_document.dart';
import 'package:event_motion_example/src/data_story_document.dart';
import 'package:event_motion_example/src/matrix_document.dart';
import 'package:event_motion_example/src/team_document.dart';
import 'package:fluvie/fluvie.dart'
    show RenderController, RenderControllerScope;
import 'package:flutter/widgets.dart';
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
  setUpAll(loadFonts);

  test(
    'data story export rejects unmatched totals and duplicate slice labels',
    () {
      final input = _fixture('data_story_composition');
      expect(
        () => data_story.build(jsonEncode(input), animated: false),
        returnsNormally,
      );
      final series =
          (input['series'] as List<dynamic>).single as Map<String, dynamic>;
      final values = series['values'] as List<dynamic>;
      final originalValue = values.last;
      values[values.length - 1] = 1;
      expect(
        () => data_story.build(jsonEncode(input), animated: false),
        throwsA(_errorAt(r'$.series[0].values')),
      );
      values[values.length - 1] = originalValue;
      final labels = input['labels'] as List<dynamic>;
      labels[1] = labels.first;
      expect(
        () => data_story.build(jsonEncode(input), animated: true),
        throwsA(_errorAt(r'$.labels[1]')),
      );
    },
  );

  test('paired dots use two series and accept a shared fixed value axis', () {
    final input = _fixture('data_story_paired_dot');
    final chart = DataStoryChart.parse(input);
    expect(chart.axis!.minimum, 0);
    expect(chart.axis!.maximum, 5);
    expect(chart.axis!.referenceLines.single, (value: 1.0, label: '1× = 2025'));
    expect(data_story.build(jsonEncode(input), animated: false).width, 1080);
    expect(
      () => DataStoryChart.parse({
        ...input,
        'series': [input['series'][0]],
      }),
      throwsA(_errorAt(r'$.series')),
    );
    expect(
      () => DataStoryChart.parse({...input, 'y_max': 4}),
      throwsA(_errorAt(r'$.y_max')),
    );
  });

  test('line charts keep their automatic range and validate references', () {
    final original = DataStoryChart.parse(_fixture('data_story'));
    expect(original.axis!.minimum, 0);
    expect(original.axis!.maximum, 480);
    expect(original.axis!.referenceLines, isEmpty);

    final fixed = _fixture('data_story_axis');
    final chart = DataStoryChart.parse(fixed);
    expect(chart.axis!.explicitBounds, isTrue);
    expect(chart.axis!.maximum, 5);
    expect(
      () => DataStoryChart.parse({
        ...fixed,
        'reference_lines': [
          {'value': 6, 'label': 'Outside the fixed range'},
        ],
      }),
      throwsA(_errorAt(r'$.y_max')),
    );
  });

  test('the stacked bar subtotal selects adjacent segment indices', () {
    final input = _fixture('data_story_stacked_bar');
    final chart = DataStoryChart.parse(input);
    expect(chart.subtotal!.startIndex, 1);
    expect(chart.subtotal!.endIndex, 2);
    expect(chart.approximateIndices, {3});
    expect(
      () => DataStoryChart.parse({
        ...input,
        'subtotal': {'start_index': 2, 'end_index': 1, 'label': 'Invalid'},
      }),
      throwsA(_errorAt(r'$.subtotal.end_index')),
    );
  });

  test('donut groups map labels to a shared named palette', () {
    final input = _fixture('data_story_grouped_donut');
    final chart = DataStoryChart.parse(input);
    expect(chart.sliceGroups, [
      null,
      'Software budgets',
      'Software budgets',
      null,
    ]);
    expect(
      () => DataStoryChart.parse({
        ...input,
        'slice_groups': [null, 'Software budgets', null, null],
      }),
      throwsA(_errorAt(r'$.slice_groups')),
    );
  });

  test('matrix headline is optional and validates its caption citations', () {
    expect(
      MatrixDocument.parse(jsonEncode(_fixture('editorial_matrix'))).heroStat,
      isNull,
    );
    final input = _fixture('editorial_matrix_hero');
    final document = MatrixDocument.parse(jsonEncode(input));
    expect(document.heroStat!.value, 'About 44%');
    expect(document.heroStat!.caption, endsWith('[SEC]'));
    expect(
      () => MatrixDocument.parse(
        jsonEncode({
          ...input,
          'hero_stat': {
            'value': '44%',
            'caption': 'Unknown evidence [missing]',
          },
        }),
      ),
      throwsA(_errorAt(r'$.hero_stat.caption')),
    );
  });

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

  test('catalogs accept an optional palette and per-tile RGB accent', () {
    final input = _fixture('editorial_catalog');
    expect(CatalogDocument.fromJson(input).palette, CatalogPalette.paper);
    input['palette'] = 'blueprint';
    final first =
        (input['tiles'] as List<dynamic>).first as Map<String, dynamic>;
    first['accent'] = '#5d356f';
    final styled = CatalogDocument.fromJson(input);
    expect(styled.palette, CatalogPalette.blueprint);
    expect(styled.tiles.first.accent, 0xff5d356f);
    expect(styled.tiles[1].accent, isNull);

    first['accent'] = '#abc';
    expect(
      () => CatalogDocument.fromJson(input),
      throwsA(_errorAt(r'$.tiles[0].accent')),
    );
    first.remove('accent');
    input['palette'] = 'unknown';
    expect(
      () => CatalogDocument.fromJson(input),
      throwsA(_errorAt(r'$.palette')),
    );
  });

  test('catalog footer and source key are independently optional', () {
    final input = _fixture('editorial_catalog');
    final original = CatalogDocument.fromJson(input);
    expect(original.footer, isNull);
    expect(original.sources, isEmpty);
    expect(
      CatalogDocument.fromJson({...input, 'footer': 'Scope note'}).footer,
      'Scope note',
    );
    final sourced = CatalogDocument.fromJson({
      ...input,
      'sources': ['[S1] example.com'],
    });
    expect(sourced.footer, isNull);
    expect(sourced.sources, ['[S1] example.com']);
    expect(
      () => CatalogDocument.fromJson({...input, 'footer': 'x' * 111}),
      throwsA(_errorAt(r'$.footer')),
    );
    expect(
      () => CatalogDocument.fromJson({
        ...input,
        'sources': ['x' * 37],
      }),
      throwsA(_errorAt(r'$.sources[0]')),
    );
    expect(
      () =>
          CatalogDocument.fromJson({...input, 'sources': List.filled(8, 'x')}),
      throwsA(_errorAt(r'$.sources')),
    );
  });

  testWidgets('a seven-source footer keeps the eight catalog cards full size', (
    tester,
  ) async {
    final input = _fixture('editorial_catalog');
    final controller = RenderController();
    addTearDown(controller.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(360, 450);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    Future<void> show(Map<String, dynamic> input) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: RenderControllerScope(
            controller: controller,
            child: catalog.build(CatalogDocument.fromJson(input)),
          ),
        ),
      );
      await tester.pump();
    }

    final cards = (input['order'] as List<dynamic>)
        .cast<String>()
        .map((id) => find.byKey(ValueKey(id)))
        .toList();
    await show(input);
    final original = cards.map(tester.getRect).toList();
    const footer =
        'Announced capabilities, not adoption, win rates, or measured time savings.';
    const sources = [
      '[S1] aws.amazon.com',
      '[S2] cloud.google.com',
      '[S3] openai.com',
      '[S4] aws.amazon.com/marketplace',
      '[S5] aws.amazon.com/whats-new',
      '[S6] docs.aws.amazon.com',
      '[S7] aws.amazon.com/blogs',
    ];
    await show({...input, 'footer': footer, 'sources': sources});
    for (final (index, card) in cards.indexed) {
      final rect = tester.getRect(card);
      expect(rect.height, greaterThanOrEqualTo(original[index].height - 0.01));
      expect(rect.width, closeTo(original[index].width, 0.01));
      expect(rect.bottom, lessThan(tester.getTopLeft(find.text(footer)).dy));
    }
    for (final source in sources) {
      final rect = tester.getRect(find.text(source));
      expect(
        rect.top,
        greaterThanOrEqualTo(tester.getRect(find.text(footer)).bottom),
      );
      expect(rect.right, lessThan(360));
      expect(rect.bottom, lessThan(450));
      expect(rect.height, greaterThanOrEqualTo(9));
    }
    controller.seek(177);
    await tester.pump();
    expect(find.text(footer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test(
    'the same team has distinct characters and a fixed activation order',
    () {
      final input = _fixture('workshop_team');
      final members = input['members'] as List<dynamic>;
      final lead = input['lead'] as Map<String, dynamic>;
      TeamDocument parse() => TeamDocument.parse(jsonEncode(input));
      final document = parse();
      expect(document.palette, WorkshopPalette.forest);
      expect(document.pace, WorkshopPace.standard);
      expect(document.groups.map((group) => group.single), document.members);
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

  test(
    'team groups cover members exactly once and keep the supplied order',
    () {
      final input = _fixture('workshop_team_fast');
      TeamDocument parse() => TeamDocument.parse(jsonEncode(input));
      final document = parse();
      expect(document.palette, WorkshopPalette.midnight);
      expect(document.pace, WorkshopPace.fast);
      expect(document.lead.color, 0xfff1b861);
      expect(document.groups.map((group) => group.map((member) => member.id)), [
        ['pauta', 'fontes'],
        ['escrita', 'revisao'],
      ]);

      input['groups'] = [
        ['pauta', 'fontes', 'escrita', 'revisao'],
      ];
      expect(parse().groups.single, document.members);
      input['groups'] = [
        ['pauta', 'fontes'],
        ['pauta', 'revisao'],
      ];
      expect(parse, throwsA(_errorAt(r'$.groups[1][0]')));
      input['groups'] = [
        ['edicao', 'pauta'],
      ];
      expect(parse, throwsA(_errorAt(r'$.groups[0][0]')));
      input['groups'] = [
        ['pauta', 'fontes'],
      ];
      expect(parse, throwsA(_errorAt(r'$.groups:')));
      input['pace'] = 'turbo';
      expect(parse, throwsA(_errorAt(r'$.pace')));
    },
  );
}
