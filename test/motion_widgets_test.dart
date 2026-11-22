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
    'status, pulse and feed follow the same frame when the caller seeks',
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

      final links = find.descendant(
        of: find.byType(MotionGraph),
        matching: find.byType(CustomPaint),
      );

      await showAt(const Duration(milliseconds: 1325));
      expect(find.text('Running'), findsOneWidget);
      expect(find.text('Review started'), findsOneWidget);
      expect(links, paints..circle(x: 175, y: 75, radius: 4));

      await showAt(const Duration(milliseconds: 1650));
      expect(links, paintsExactlyCountTimes(#drawCircle, 0));

      await showAt(Duration.zero);
      expect(find.text('Ready'), findsNWidgets(2));
      expect(find.text('Review started'), findsNothing);
      expect(links, paintsExactlyCountTimes(#drawCircle, 0));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('reordering a diagram keeps custom card state with its node', (
    tester,
  ) async {
    final frame = MotionTimeline(const []).at(Duration.zero);

    Future<void> show(Iterable<MotionNode> nodes) => tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Center(
          child: SizedBox(
            width: 350,
            height: 150,
            child: MotionGraph(
              diagram: MotionDiagram(nodes: nodes),
              frame: frame,
              nodeBuilder: (_, node, _) => _TapCard(node.label),
            ),
          ),
        ),
      ),
    );

    await show(diagram.nodes);
    await tester.tap(find.text('Draft: 0'));
    await tester.pump();
    expect(find.text('Draft: 1'), findsOneWidget);

    await show(diagram.nodes.reversed);
    expect(find.text('Draft: 1'), findsOneWidget);
    expect(find.text('Review: 0'), findsOneWidget);
  });

  test('rejects an edge whose target does not exist', () {
    expect(
      () => MotionDiagram(
        nodes: diagram.nodes,
        links: const [MotionLink('draft', 'missing')],
      ),
      throwsArgumentError,
    );
  });

  testWidgets(
    'the default card uses its requested size and localized caption',
    (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Center(
            child: SizedBox(
              width: 350,
              height: 150,
              child: MotionGraph(
                diagram: MotionDiagram(nodes: [diagram.nodes.first]),
                frame: MotionTimeline(const []).at(Duration.zero),
                cardSize: const Size(180, 46),
                statusLabel: (_) => 'Aguardando',
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byKey(const ValueKey('draft'))),
        const Size(180, 46),
      );
      expect(find.text('Aguardando'), findsOneWidget);
    },
  );
}

class _TapCard extends StatefulWidget {
  const _TapCard(this.label);

  final String label;

  @override
  State<_TapCard> createState() => _TapCardState();
}

class _TapCardState extends State<_TapCard> {
  int _taps = 0;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => setState(() => _taps++),
    child: Center(child: Text('${widget.label}: $_taps')),
  );
}
