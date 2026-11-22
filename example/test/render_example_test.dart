import 'dart:async';
import 'dart:io';

import 'package:alchemist/alchemist.dart' show loadFonts;
import 'package:event_motion_example/agent_pipeline.dart' as pipeline;
import 'package:event_motion_example/card_sequence.dart' as sequence;
import 'package:event_motion_example/cha_de_estrelas.dart' as cha;
import 'package:event_motion_example/comparison.dart' as comparison;
import 'package:event_motion_example/data_story.dart' as data_story;
import 'package:event_motion_example/editorial_catalog.dart' as editorial;
import 'package:event_motion_example/editorial_illustration.dart'
    as illustration;
import 'package:event_motion_example/editorial_matrix.dart' as matrix;
import 'package:event_motion_example/hybrid.dart' as hybrid;
import 'package:event_motion_example/jardim_sonho.dart' as jardim;
import 'package:event_motion_example/src/card_document.dart';
import 'package:event_motion_example/src/catalog_document.dart';
import 'package:event_motion_example/src/illustration_artwork.dart';
import 'package:event_motion_example/src/illustration_document.dart';
import 'package:event_motion_example/src/matrix_document.dart';
import 'package:event_motion_example/src/team_document.dart';
import 'package:event_motion_example/src/workflow_spec.dart';
import 'package:event_motion_example/workshop_team.dart' as workshop;
import 'package:fluvie/fluvie.dart' show Video;
import 'package:fluvie/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:handcrafted_flutter/handcrafted_flutter.dart'
    show CraftMaterial;

const _render = bool.fromEnvironment('RENDER_EXAMPLE');

void main() {
  if (_render) setUpAll(loadFonts);

  final workflow = Platform.environment['EVENT_MOTION_WORKFLOW'];
  final audio = Platform.environment['EVENT_MOTION_AUDIO'];
  final material = Platform.environment['EVENT_MOTION_MATERIAL'];
  final cards =
      Platform.environment['EVENT_MOTION_CARDS'] ?? 'fixtures/cards.json';
  final clip = Platform.environment['EVENT_MOTION_HYBRID_CLIP'];
  final editorialInput = Platform.environment['EVENT_MOTION_EDITORIAL'];
  String input(String fallback) =>
      File(editorialInput ?? 'fixtures/$fallback.json').readAsStringSync();
  for (final (name, build) in <(String, FutureOr<Video> Function())>[
    ('jardim_sonho', () => jardim.build()),
    ('cha_de_estrelas', () => cha.build()),
    (
      'agent_pipeline',
      () => pipeline.build(
        WorkflowSpec.parse(
          File(workflow ?? 'fixtures/agent_pipeline.json').readAsStringSync(),
        ),
      ),
    ),
    (
      'card_sequence',
      () => sequence.build(CardDocument.parse(File(cards).readAsStringSync())),
    ),
    (
      'activation',
      () => pipeline.build(
        WorkflowSpec.parse(File('fixtures/activation.json').readAsStringSync()),
        fullSize: true,
        audio: audio,
      ),
    ),
    (
      'comparison',
      () => comparison.build(
        material: material == null
            ? null
            : CraftMaterial.values.byName(material),
      ),
    ),
    (
      'editorial_catalog',
      () => editorial.build(CatalogDocument.parse(input('editorial_catalog'))),
    ),
    (
      'editorial_matrix',
      () => matrix.build(MatrixDocument.parse(input('editorial_matrix'))),
    ),
    for (final animated in [false, true])
      (
        animated ? 'editorial_illustration_video' : 'editorial_illustration',
        () async {
          final file = File(
            editorialInput ?? 'fixtures/editorial_illustration.json',
          );
          final document = IllustrationDocument.parse(file.readAsStringSync());
          final artwork = await loadIllustrationArtwork(document, file.parent);
          for (final image in artwork.values) {
            addTearDown(image.dispose);
          }
          return illustration.build(
            document,
            animated: animated,
            artwork: artwork,
          );
        },
      ),
    (
      'data_story',
      () => data_story.build(input('data_story'), animated: false),
    ),
    (
      'data_story_video',
      () => data_story.build(input('data_story'), animated: true),
    ),
    (
      'character_poster',
      () => workshop.buildPoster(TeamDocument.parse(input('workshop_team'))),
    ),
    (
      'character_dashboard',
      () => workshop.buildDashboard(TeamDocument.parse(input('workshop_team'))),
    ),
    if (clip != null)
      (
        'hybrid',
        () => hybrid.build(
          CardDocument.parse(File(cards).readAsStringSync()),
          clip,
          int.parse(Platform.environment['EVENT_MOTION_HYBRID_FRAMES']!),
          overlay: Platform.environment['EVENT_MOTION_HYBRID_ALPHA'] == '1',
        ),
      ),
  ]) {
    final imageOnly = const {
      'comparison',
      'character_poster',
      'data_story',
      'editorial_illustration',
      'editorial_matrix',
    }.contains(name);
    final formats = imageOnly ? 'PNG' : 'MP4 and PNG';
    testWidgets('exports $name as $formats', skip: !_render, (tester) async {
      final outputName = name == 'agent_pipeline' && workflow != null
          ? 'workflow'
          : name == 'comparison' && material != null
          ? 'comparison-$material'
          : name;
      final video = await tester.runAsync(() async => await build());
      await _export(tester, video!, outputName, imageOnly: imageOnly);
    });
  }
}

Future<void> _export(
  WidgetTester tester,
  Video video,
  String name, {
  required bool imageOnly,
}) async {
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final asset = switch (name) {
    'jardim_sonho' => 'assets/jardim_sonho.png',
    'cha_de_estrelas' => 'assets/cha_de_estrelas.png',
    _ => null,
  };
  if (asset != null) {
    await tester.pumpWidget(
      const Directionality(textDirection: TextDirection.ltr, child: SizedBox()),
    );
    final context = tester.element(find.byType(SizedBox));
    await tester.runAsync(() => precacheImage(AssetImage(asset), context));
  }
  final output = Directory.systemTemp.createTempSync('event-motion-render-');
  addTearDown(() => output.deleteSync(recursive: true));
  final manifest = await renderVideo(
    video: video,
    outDir: output,
    posterTime: video.poster,
    defaultFontFamily: 'packages/fluvie/JetBrains Mono',
    setViewSize: (width, height) {
      tester.view.physicalSize = Size(width.toDouble(), height.toDouble());
      tester.view.devicePixelRatio = 1;
    },
    pumpWidget: tester.pumpWidget,
    pumpFrame: tester.pump,
    runAsync: tester.runAsync,
  );

  await tester.runAsync(() async {
    if (!imageOnly) await _encode(output, manifest.ffmpegArgs);
    await _encode(output, manifest.posterArgs!);
    final customOutput = switch (name) {
      'workflow' => Platform.environment['EVENT_MOTION_WORKFLOW_OUT'],
      'hybrid' => Platform.environment['EVENT_MOTION_HYBRID_OUT'],
      'editorial_catalog' ||
      'editorial_illustration' ||
      'editorial_illustration_video' ||
      'editorial_matrix' ||
      'character_poster' ||
      'character_dashboard' ||
      'data_story' ||
      'data_story_video' => Platform.environment['EVENT_MOTION_EDITORIAL_OUT'],
      _ => null,
    };
    final destination = Directory(customOutput ?? 'build/$name')
      ..createSync(recursive: true);
    if (name == 'hybrid') {
      final capture = File('${output.path}/${manifest.framesFileName}');
      File(
        '${destination.path}/capture-bytes.txt',
      ).writeAsStringSync('${capture.lengthSync()}');
    }
    final poster = File('${output.path}/${manifest.posterFileName}');
    expect(poster.lengthSync(), greaterThan(0));
    if (!imageOnly) {
      final movie = File('${output.path}/${manifest.outputFileName}');
      expect(movie.lengthSync(), greaterThan(0));
      movie.copySync('${destination.path}/$name.mp4');
    }
    poster.copySync('${destination.path}/$name.png');
  });
}

Future<void> _encode(Directory output, List<String> args) async {
  final result = await Process.run(
    'ffmpeg',
    args,
    workingDirectory: output.path,
  );
  expect(result.exitCode, 0, reason: result.stderr.toString());
}
