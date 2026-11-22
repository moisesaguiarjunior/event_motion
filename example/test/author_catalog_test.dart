import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'catalog author repairs a duplicated ID in the playback order',
    () async {
      final root = Directory.systemTemp.createTempSync(
        'event-motion-catalog-test-',
      );
      addTearDown(() => root.deleteSync(recursive: true));
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
      addTearDown(() => server.close(force: true));
      final requests = <Map<String, dynamic>>[];
      final fixture =
          jsonDecode(File('fixtures/editorial_catalog.json').readAsStringSync())
              as Map<String, dynamic>;
      final order = fixture['order'] as List<dynamic>;
      final output = File('${root.path}/out/catalog.json');
      server.listen((request) async {
        requests.add(
          jsonDecode(await utf8.decoder.bind(request).join())
              as Map<String, dynamic>,
        );
        final draft = requests.length == 1
            ? {
                ...fixture,
                'order': [order[1], ...order.skip(1)],
              }
            : fixture;
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'message': {'content': jsonEncode(draft)},
          }),
        );
        await request.response.close();
      });
      final brief = File('${root.path}/brief.txt')
        ..writeAsStringSync('Uma grade editorial sobre como criar um post.');
      Future<ProcessResult> author() => Process.run(
        'dart',
        ['bin/author_catalog.dart', brief.path, output.parent.path],
        environment: {
          'EVENT_MOTION_OLLAMA_URL': 'http://127.0.0.1:${server.port}/api/chat',
        },
      );

      final result = await author();
      expect(result.exitCode, 0, reason: result.stderr.toString());
      expect(requests, hasLength(2));
      expect(jsonEncode(requests.last['messages']), contains(r'$.order[1]'));
      expect(jsonDecode(output.readAsStringSync()), fixture);
      final repeated = await author();
      expect(repeated.exitCode, 1);
      expect(requests, hasLength(2));
      expect(jsonDecode(output.readAsStringSync()), fixture);
    },
  );
}
