import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:event_motion_example/src/ollama_json.dart';
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
  return authorJson(
    brief: log == null
        ? brief
        : '$brief\n\nWorkflow context:\n${jsonEncode(log)}',
    instructions: instructions,
    schema: schema,
    validate: (draft) {
      final result = log == null ? draft : _replaceHeadings(log, draft);
      WorkflowDocument.fromJson(result);
      return result;
    },
  );
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
