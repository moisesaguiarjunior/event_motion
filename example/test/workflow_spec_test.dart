import 'dart:convert';
import 'dart:io';

import 'package:event_motion/event_motion.dart';
import 'package:event_motion_example/src/workflow_spec.dart';
import 'package:flutter_test/flutter_test.dart';

final _fixture = File('fixtures/agent_pipeline.json').readAsStringSync();

void main() {
  test(
    'the checked-in workflow resolves the diagram and coincident events',
    () {
      final spec = WorkflowSpec.parse(_fixture);
      expect((spec.frameCount, spec.coverFrame), (96, 60));
      expect(spec.diagram.nodes[1].position, const Offset(0, 0.44));
      final frame = spec.timeline.at(const Duration(milliseconds: 500));
      expect(frame.statusOf('brief'), MotionStatus.complete);
      expect(
        frame.latestOn('brief', 'research')?.message,
        'Gathering source notes',
      );
    },
  );

  test(
    'a short vertical workflow admits an event on the final sampled frame',
    () {
      final spec = WorkflowSpec.fromJson(<String, Object?>{
        'version': 1,
        'template': 'agent_pipeline',
        'title': 'Revisão local',
        'layout': 'vertical',
        'durationMs': 1000,
        'coverMs': 958,
        'nodes': [
          {'id': 'review', 'label': 'Revisão'},
        ],
        'links': [],
        'events': [
          {'atMs': 958, 'node': 'review', 'status': 'complete'},
        ],
      });

      expect(spec.subtitle, isNull);
      expect(spec.diagram.nodes.single.position, const Offset(0.5, 0.5));
      expect((spec.frameCount, spec.coverFrame), (24, 23));
      expect(
        spec.timeline.at(const Duration(milliseconds: 958)).statusOf('review'),
        MotionStatus.complete,
      );
    },
  );

  void rejects(
    String description,
    String path,
    void Function(Map<String, dynamic>) edit,
  ) {
    test(description, () {
      final value = jsonDecode(_fixture) as Map<String, dynamic>;
      edit(value);
      expect(
        () => WorkflowSpec.fromJson(value),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            startsWith('$path: '),
          ),
        ),
      );
    });
  }

  rejects(
    'rejects an unsupported version',
    r'$.version',
    (spec) => spec['version'] = 2,
  );
  rejects(
    'rejects unknown event fields',
    r'$.events[0].time',
    (spec) => spec['events'][0]['time'] = 0,
  );
  rejects(
    'requires four nodes for the diamond layout',
    r'$.nodes',
    (spec) => spec['nodes'].removeLast(),
  );
  rejects(
    'rejects an ambiguous node ID',
    r'$.nodes[1].id',
    (spec) => spec['nodes'][1]['id'] = 'brief',
  );
  rejects(
    'rejects a missing node reference',
    r'$.links[0].to',
    (spec) => spec['links'][0]['to'] = 'missing',
  );
  rejects(
    'rejects an undeclared event link',
    r'$.events[2].from',
    (spec) => spec['events'][2]['from'] = 'compose',
  );
  rejects(
    'rejects an event preceding the one before it',
    r'$.events[3].atMs',
    (spec) => spec['events'][3]['atMs'] = 499,
  );
  rejects(
    'rejects a cover that rounds past the end',
    r'$.coverMs',
    (spec) => spec['coverMs'] = 3999,
  );
  rejects(
    'rejects an event after the final sampled frame',
    r'$.events[8].atMs',
    (spec) => spec['events'][8]['atMs'] = 3959,
  );
  rejects(
    'rejects control characters in copy',
    r'$.title',
    (spec) => spec['title'] = 'Invalid\nTitle',
  );
}
