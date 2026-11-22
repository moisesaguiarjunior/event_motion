import 'dart:io';

import 'package:event_motion_example/src/card_document.dart';

void main(List<String> args) {
  if (args.length != 1) {
    stderr.writeln('Usage: validate_cards.dart cards.json');
    exitCode = 2;
    return;
  }
  try {
    CardDocument.parse(File(args.single).readAsStringSync());
  } on FormatException catch (error) {
    stderr.writeln(error.message);
    exitCode = 1;
  } on FileSystemException catch (error) {
    stderr.writeln(error);
    exitCode = 1;
  }
}
