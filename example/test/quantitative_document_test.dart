import 'dart:convert';
import 'dart:io';
import 'package:event_motion_example/src/quantitative_document.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:event_motion_example/src/matrix_document.dart';

void main() {
  test('matrix rows note is optional and limited to 60 characters', () {
    final d =
        jsonDecode(
              File(
                'fixtures/editorial_matrix_rows_note.json',
              ).readAsStringSync(),
            )
            as Map<String, dynamic>;
    expect(
      MatrixDocument.parse(jsonEncode(d)).rowsNote,
      contains('Historical'),
    );
    d['rows_note'] = 'x' * 61;
    expect(() => MatrixDocument.parse(jsonEncode(d)), throwsFormatException);
    d.remove('rows_note');
    expect(MatrixDocument.parse(jsonEncode(d)).rowsNote, isNull);
  });
  Map<String, dynamic> fixture([String name = 'quantitative_chart']) =>
      jsonDecode(File('fixtures/$name.json').readAsStringSync())
          as Map<String, dynamic>;
  void reject(Map d) => expect(
    () => QuantitativeDocument.parse(jsonEncode(d)),
    throwsFormatException,
  );
  test('both quantitative forms validate through the renderer contract', () {
    expect(QuantitativeDocument.parse(jsonEncode(fixture())).intervals, isTrue);
    expect(
      QuantitativeDocument.parse(
        jsonEncode(fixture('quantitative_chart_panels')),
      ).intervals,
      isFalse,
    );
  });
  test(
    'signed endpoints have exact output coordinates and only one crosses zero',
    () {
      final rows = fixture()['rows'] as List;
      expect(rows.where((r) => r['lower'] <= 0 && r['upper'] >= 0).length, 1);
      double px(num n) =>
          QuantitativeDocument.position(n.toDouble(), -10, 65, 38, 352) * 2.5;
      expect(px(2.40) - px(0), closeTo(28.16, .0001));
      expect(px(-3.18), closeTo(175.0213333, .0001));
      expect(px(59.35), closeTo(908.7066667, .0001));
    },
  );
  test('rejects unordered, clipped, nonfinite and unreferenced intervals', () {
    var d = fixture();
    d['rows'][0]['lower'] = 40;
    reject(d);
    d = fixture();
    d['axis']['max'] = 40;
    reject(d);
    d = fixture();
    d['rows'][0]['estimate'] = 'NaN';
    reject(d);
    d = fixture();
    d['rows'][0]['source_ids'] = ['missing'];
    reject(d);
    d = fixture();
    d['context'] = 'Unsupported source [missing]';
    reject(d);
    d = fixture();
    d['axis']['min'] = 0;
    reject(d);
  });
  test(
    'independent bar axes reject clipping, negative values and shared axes',
    () {
      var d = fixture('quantitative_chart_panels');
      d['panels'][1]['maximum'] = 100;
      reject(d);
      d = fixture('quantitative_chart_panels');
      d['panels'][0]['bars'][0]['value'] = -1;
      reject(d);
      d = fixture('quantitative_chart_panels');
      d['axis'] = {};
      reject(d);
    },
  );
}
