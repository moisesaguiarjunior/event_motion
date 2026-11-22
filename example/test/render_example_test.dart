import 'dart:io';

import 'package:alchemist/alchemist.dart' show loadFonts;
import 'package:event_motion_example/agent_pipeline.dart' as pipeline;
import 'package:event_motion_example/card_sequence.dart' as sequence;
import 'package:event_motion_example/comparison.dart' as comparison;
import 'package:event_motion_example/hybrid.dart' as hybrid;
import 'package:event_motion_example/src/card_document.dart';
import 'package:event_motion_example/src/workflow_spec.dart';
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
  for (final (name, build) in [
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
    final formats = name == 'comparison' ? 'PNG' : 'MP4 and PNG';
    testWidgets('exports $name as $formats', skip: !_render, (tester) async {
      final outputName = name == 'agent_pipeline' && workflow != null
          ? 'workflow'
          : name == 'comparison' && material != null
          ? 'comparison-$material'
          : name;
      await _export(
        tester,
        build(),
        outputName,
        imageOnly: name == 'comparison',
      );
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
