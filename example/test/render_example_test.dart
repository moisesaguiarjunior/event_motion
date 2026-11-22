import 'dart:io';

import 'package:alchemist/alchemist.dart' show loadFonts;
import 'package:event_motion_example/agent_pipeline.dart' as pipeline;
import 'package:fluvie/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _render = bool.fromEnvironment('RENDER_EXAMPLE');

void main() {
  testWidgets('exports the example as MP4 and PNG', skip: !_render, (
    tester,
  ) async {
    await loadFonts();
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final output = Directory.systemTemp.createTempSync('event-motion-render-');
    addTearDown(() => output.deleteSync(recursive: true));
    final video = pipeline.build();

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
      await _encode(output, manifest.ffmpegArgs);
      await _encode(output, manifest.posterArgs!);
      final destination = Directory('build/agent_pipeline')
        ..createSync(recursive: true);
      final movie = File('${output.path}/${manifest.outputFileName}');
      final poster = File('${output.path}/${manifest.posterFileName}');
      expect(movie.lengthSync(), greaterThan(0));
      expect(poster.lengthSync(), greaterThan(0));
      movie.copySync('${destination.path}/agent_pipeline.mp4');
      poster.copySync('${destination.path}/agent_pipeline.png');
    });
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
