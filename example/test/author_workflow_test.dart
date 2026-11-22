import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'the author repairs invalid headings and preserves the event document',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'event-motion-author-test-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requests = <Map<String, dynamic>>[];
      server.listen((request) async {
        final payload = await utf8.decoder.bind(request).join();
        requests.add(jsonDecode(payload) as Map<String, dynamic>);
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'message': {
              'content': jsonEncode(
                requests.length == 1
                    ? {'title': 'A' * 37}
                    : {'title': 'A verified editorial draft'},
              ),
            },
          }),
        );
        await request.response.close();
      });
      final brief = File('${root.path}/brief.txt')
        ..writeAsStringSync('Write a short heading for this log.');
      const source = 'fixtures/agent_pipeline.json';
      final result = await Process.run(
        'dart',
        ['bin/author_workflow.dart', brief.path, '${root.path}/out', source],
        environment: {
          'EVENT_MOTION_OLLAMA_URL': 'http://127.0.0.1:${server.port}/api/chat',
        },
      );
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(requests, hasLength(2));
      expect(jsonEncode(requests.last['messages']), contains(r'$.title'));
      final authored =
          jsonDecode(File('${root.path}/out/workflow.json').readAsStringSync())
              as Map<String, dynamic>;
      final original =
          jsonDecode(File(source).readAsStringSync()) as Map<String, dynamic>;
      expect(authored.remove('title'), 'A verified editorial draft');
      original.remove('title');
      original.remove('subtitle');
      expect(authored, original);
    },
  );
}
