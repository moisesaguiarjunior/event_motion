// The preflight runs before Flutter resolves the example's dependencies.
// ignore_for_file: avoid_relative_lib_imports

import 'dart:convert';
import 'dart:io';

import '../lib/src/catalog_document.dart';
import '../lib/src/data_story_document.dart';
import '../lib/src/illustration_document.dart';
import '../lib/src/matrix_document.dart';

Future<void> main(List<String> args) async {
  if (args.length != 1 ||
      !const {
        'data_story',
        'editorial_catalog',
        'editorial_illustration',
        'editorial_matrix',
      }.contains(args.single)) {
    stderr.writeln(
      'Usage: dart bin/validate_editorial.dart TEMPLATE < visual.json',
    );
    exitCode = 64;
    return;
  }
  try {
    final input = await stdin.transform(utf8.decoder).join();
    switch (args.single) {
      case 'data_story':
        final data = jsonDecode(input);
        if (data is! Map<String, Object?>) {
          throw const FormatException(r'$: expected an object');
        }
        DataStoryChart.parse(data);
      case 'editorial_catalog':
        CatalogDocument.parse(input);
      case 'editorial_illustration':
        IllustrationDocument.parse(input);
      case 'editorial_matrix':
        MatrixDocument.parse(input);
    }
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 2;
  }
}
