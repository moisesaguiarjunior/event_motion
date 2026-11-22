import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:event_motion_example/src/catalog_document.dart';
import 'package:event_motion_example/src/ollama_json.dart';

Future<void> main(List<String> args) async {
  if (args.length != 2) {
    stderr.writeln('Usage: author_catalog.dart brief.txt output-directory');
    exitCode = 2;
    return;
  }
  final output = File('${args[1]}/catalog.json');
  try {
    if (output.existsSync()) {
      throw FileSystemException(
        'The catalog already exists. Choose a new output directory or render the existing file.',
        output.path,
      );
    }
    final brief = File(args[0]).readAsStringSync().trim();
    if (brief.isEmpty) throw const FormatException('The brief is empty.');
    final schema =
        jsonDecode(
              File.fromUri(
                Platform.script.resolve('../spec/catalog.v1.schema.json'),
              ).readAsStringSync(),
            )
            as Map<String, Object?>;
    final watch = Stopwatch()..start();
    final (result, attempts) = await authorJson(
      brief: brief,
      instructions:
          '''Write a compact editorial catalog for the supplied brief, in the brief's language.
Use version 1. Prefer exactly eight tiles unless the brief asks for a different number (eight to twelve).
Use a distinct short lowercase ID for each tile. Each tile has a short title, one explanatory note,
and one diagram type: flow (steps), bars (comparison), curve (change) or orbit (relationships).
Set order to the exact tile IDs in the desired reading order and include each ID once.
Use a single line per field. Keep tile titles to 22 characters and notes to 43 characters.
Aim for at most five words per note. Give a complete action that matches the tile title.
For example, a tile called "Fontes confiáveis" could say "Confira os estudos originais."
Only include a palette or a tile accent when the brief calls for one.
Use footer for a scope note of up to 110 characters and sources for up to seven
source labels of up to 36 characters each, including the bracketed IDs used in
the tile notes. Include these optional fields only when the brief supports them.
The diagrams are illustrative. Use supplied facts for copy and avoid invented measurements.''',
      schema: schema,
      validate: (draft) {
        CatalogDocument.fromJson(draft);
        return draft;
      },
    );
    output.parent.createSync(recursive: true);
    output.createSync(exclusive: true);
    output.writeAsStringSync(
      '${const JsonEncoder.withIndent('  ').convert(result)}\n',
    );
    stdout.writeln(
      'Saved ${output.path} after $attempts attempt(s) in ${watch.elapsedMilliseconds} ms.',
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
