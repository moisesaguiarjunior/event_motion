import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:event_motion_example/src/workflow_document.dart';

const _headingsSchema = {
  'type': 'object',
  'additionalProperties': false,
  'required': ['title'],
  'properties': {
    'title': {'type': 'string', 'minLength': 1, 'maxLength': 36},
    'subtitle': {'type': 'string', 'minLength': 1, 'maxLength': 72},
  },
};

Future<void> main(List<String> args) async {
  if (args.length < 2 || args.length > 3) {
    stderr.writeln(
      'Usage: author_workflow.dart brief.txt output-directory [event-log.json]',
    );
    exitCode = 2;
    return;
  }
  final output = File('${args[1]}/workflow.json');
  try {
    if (output.existsSync()) {
      throw FileSystemException(
        'The workflow already exists. Use a new output directory or render this file.',
        output.path,
      );
    }
    final brief = File(args[0]).readAsStringSync().trim();
    if (brief.isEmpty) throw const FormatException('The brief is empty.');
    final directory = Platform.script.resolve('../');
    final Map<String, Object?>? log;
    if (args.length == 3) {
      final text = File(args[2]).readAsStringSync();
      WorkflowDocument.parse(text);
      log = jsonDecode(text) as Map<String, Object?>;
    } else {
      log = null;
    }
    final schema = log != null
        ? _headingsSchema
        : jsonDecode(
                File.fromUri(
                  directory.resolve('spec/workflow.v1.schema.json'),
                ).readAsStringSync(),
              )
              as Map<String, Object?>;
    final example = log == null
        ? File.fromUri(
            directory.resolve('fixtures/agent_pipeline.json'),
          ).readAsStringSync()
        : null;
    final stopwatch = Stopwatch()..start();
    final (document, attempts) = await _author(brief, schema, example, log);
    output.parent.createSync(recursive: true);
    output.createSync(exclusive: true);
    output.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(document)}\n',
    );
    stdout.writeln(
      'Saved ${output.path} after $attempts attempt(s) in ${stopwatch.elapsedMilliseconds} ms.',
    );
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  } on IOException catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  } on TimeoutException catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}

Future<(Map<String, Object?>, int)> _author(
  String brief,
  Map<String, Object?> schema,
  String? example,
  Map<String, Object?>? log,
) async {
  final env = Platform.environment;
  final endpoint = Uri.parse(
    env['EVENT_MOTION_OLLAMA_URL'] ?? 'http://127.0.0.1:11434/api/chat',
  );
  final model = env['EVENT_MOTION_MODEL'] ?? 'qwen3.5:4b';
  final instructions = log == null
      ? '''Create an agent_pipeline JSON composition for the supplied brief.
      Keep text short and use the brief's language. Treat an illustrative process as a simulation.
      Set locale to pt-BR for Portuguese output and en for English output.
      Prefer vertical with 2–4 nodes unless the brief calls for four nodes in a diamond.
      Set version to 1 and include all required fields. Events must be chronological.
      Use only declared node IDs. Omit optional fields when unused. Every from field
      must have a matching directed link. Keep events and cover at least 100 ms
      inside the clip. Do not make up measured results or execution evidence.
      Example composition:
      $example'''
      : '''Write short editorial headings for an agent_pipeline panel using the brief's language.
      Return only title and, if helpful, subtitle. Use the supplied workflow as context.
      The original nodes, links, timed events and data will be kept verbatim.''';
  final messages = <Map<String, String>>[
    {
      'role': 'system',
      'content':
          '$instructions\nReturn JSON matching this schema: ${jsonEncode(schema)}',
    },
    {
      'role': 'user',
      'content': log == null
          ? brief
          : '$brief\n\nWorkflow context:\n${jsonEncode(log)}',
    },
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
        final result = log == null ? decoded : _replaceHeadings(log, decoded);
        WorkflowDocument.fromJson(result);
        return (result, attempt);
      } on FormatException catch (error) {
        if (attempt == 3) {
          throw FormatException(
            'Ollama returned invalid workflow JSON after $attempt attempts. ${error.message}',
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

Map<String, Object?> _replaceHeadings(
  Map<String, Object?> log,
  Map<String, Object?> headings,
) {
  for (final key in headings.keys) {
    if (key != 'title' && key != 'subtitle') {
      throw FormatException('Unexpected heading field $key.');
    }
  }
  return {...log}
    ..remove('subtitle')
    ..addAll({
      'title': headings['title'],
      if (headings.containsKey('subtitle')) 'subtitle': headings['subtitle'],
    });
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
