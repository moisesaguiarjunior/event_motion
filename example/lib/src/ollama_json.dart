import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Requests structured local model output and repairs cross-field validation errors.
Future<(Map<String, Object?>, int)> authorJson({
  required String brief,
  required String instructions,
  required Map<String, Object?> schema,
  required Map<String, Object?> Function(Map<String, Object?>) validate,
}) async {
  final env = Platform.environment;
  final endpoint = Uri.parse(
    env['EVENT_MOTION_OLLAMA_URL'] ?? 'http://127.0.0.1:11434/api/chat',
  );
  final model = env['EVENT_MOTION_MODEL'] ?? 'qwen3.5:4b';
  final messages = <Map<String, String>>[
    {
      'role': 'system',
      'content':
          '$instructions\nReturn JSON matching this schema: ${jsonEncode(schema)}',
    },
    {'role': 'user', 'content': brief},
  ];

  final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
  try {
    for (var attempt = 1; attempt <= 3; attempt++) {
      final reply = await _chat(client, endpoint, model, messages, schema);
      try {
        final decoded = jsonDecode(reply);
        if (decoded is! Map<String, Object?>) {
          throw const FormatException('Expected a JSON object.');
        }
        return (validate(decoded), attempt);
      } on FormatException catch (error) {
        if (attempt == 3) {
          throw FormatException(
            'Ollama returned invalid document JSON after $attempt attempts. ${error.message}',
          );
        }
        stderr.writeln('Repairing attempt $attempt. ${error.message}');
        messages.addAll([
          {'role': 'assistant', 'content': reply},
          {
            'role': 'user',
            'content':
                'Correct this validation error and return the complete requested JSON. ${error.message}',
          },
        ]);
      }
    }
    throw StateError('Unreachable authoring state.');
  } finally {
    client.close(force: true);
  }
}

Future<String> _chat(
  HttpClient client,
  Uri endpoint,
  String model,
  List<Map<String, String>> messages,
  Map<String, Object?> schema,
) async {
  // Adapt Fluvie's Ollama structured chat request to this template and a plain Dart host.
  final request = await client.postUrl(endpoint);
  request.headers.contentType = ContentType.json;
  request.write(
    jsonEncode({
      'model': model,
      'stream': false,
      'think': false,
      'messages': messages,
      'format': schema,
      'options': {'temperature': 0, 'num_ctx': 8192, 'num_predict': 2048},
    }),
  );
  const timeout = Duration(minutes: 3);
  final response = await request.close().timeout(timeout);
  final body = await response.transform(utf8.decoder).join().timeout(timeout);
  if (response.statusCode != HttpStatus.ok) {
    throw HttpException(
      'Ollama returned HTTP ${response.statusCode}. $body',
      uri: endpoint,
    );
  }
  final decoded = jsonDecode(body);
  if (decoded case {
    'message': {'content': final String text},
  } when text.isNotEmpty) {
    return text;
  }
  throw const FormatException('Ollama returned no message content.');
}
