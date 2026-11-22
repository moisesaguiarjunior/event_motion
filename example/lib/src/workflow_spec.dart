import 'package:event_motion/event_motion.dart';
import 'package:flutter/widgets.dart' show Offset;

import 'workflow_document.dart';

/// Validated workflow input resolved to Flutter and Event Motion types.
final class WorkflowSpec {
  WorkflowSpec._(this.document)
    : diagram = _diagram(document),
      timeline = _timeline(document);

  static const fps = WorkflowDocument.fps;

  final WorkflowDocument document;
  final MotionDiagram diagram;
  final MotionTimeline timeline;

  String get title => document.title;
  String? get subtitle => document.subtitle;
  int get frameCount => document.frameCount;
  int get coverFrame => document.coverFrame;

  factory WorkflowSpec.parse(String source) =>
      WorkflowSpec._(WorkflowDocument.parse(source));

  factory WorkflowSpec.fromJson(Object? value) =>
      WorkflowSpec._(WorkflowDocument.fromJson(value));
}

MotionDiagram _diagram(WorkflowDocument document) {
  final nodes = document.nodes;
  const diamond = [
    Offset(0.5, 0),
    Offset(0, 0.44),
    Offset(1, 0.44),
    Offset(0.5, 0.94),
  ];
  return MotionDiagram(
    nodes: [
      for (final (index, node) in nodes.indexed)
        MotionNode(
          node.id,
          node.label,
          document.layout == 'diamond'
              ? diamond[index]
              : Offset(
                  0.5,
                  nodes.length == 1 ? 0.5 : index / (nodes.length - 1),
                ),
        ),
    ],
    links: [for (final link in document.links) MotionLink(link.from, link.to)],
  );
}

MotionTimeline _timeline(WorkflowDocument document) => MotionTimeline([
  for (final event in document.events)
    MotionEvent(
      at: Duration(milliseconds: event.atMs),
      node: event.node,
      from: event.from,
      status: MotionStatus.values.byName(event.status),
      message: event.message,
    ),
]);
