import 'package:event_motion/event_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final diagram = MotionDiagram(
    nodes: const [
      MotionNode('draft', 'Draft', Offset(0, 0.5)),
      MotionNode('review', 'Review', Offset(1, 0.5)),
    ],
    links: const [MotionLink('draft', 'review')],
  );

  testWidgets(
    'the graph and feed follow the same frame when the caller seeks',
    (tester) async {
      final timeline = MotionTimeline(const [
        MotionEvent(
          at: Duration(seconds: 1),
          node: 'review',
          from: 'draft',
          status: MotionStatus.active,
          message: 'Review started',
        ),
      ]);

      Future<void> showAt(Duration elapsed) {
        final frame = timeline.at(elapsed);
        return tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Column(
              children: [
                SizedBox(
                  width: 350,
                  height: 150,
                  child: MotionGraph(diagram: diagram, frame: frame),
                ),
                MotionEventFeed(frame: frame),
              ],
            ),
          ),
        );
      }

      await showAt(const Duration(seconds: 1));
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Review started'), findsOneWidget);

      await showAt(Duration.zero);
      expect(find.text('Ready'), findsNWidgets(2));
      expect(find.text('Review started'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );

  test('rejects an edge whose target does not exist', () {
    expect(
      () => MotionDiagram(
        nodes: diagram.nodes,
        links: const [MotionLink('draft', 'missing')],
      ),
      throwsArgumentError,
    );
  });
}
