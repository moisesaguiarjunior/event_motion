import 'dart:math' as math;

import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/widgets.dart';

import 'motion_timeline.dart';

/// A card whose center is positioned between zero and one on both axes.
final class MotionNode {
  const MotionNode(this.id, this.label, this.position);

  final String id;
  final String label;
  final Offset position;
}

/// A directed connection from one node ID to another.
final class MotionLink {
  const MotionLink(this.from, this.to);

  final String from;
  final String to;
}

/// A reusable layout and its declared connections.
final class MotionDiagram {
  MotionDiagram({
    required Iterable<MotionNode> nodes,
    Iterable<MotionLink> links = const [],
  }) : nodes = List.unmodifiable(nodes),
       links = List.unmodifiable(links) {
    final ids = <String>{};
    for (final node in this.nodes) {
      if (node.id.trim().isEmpty ||
          node.label.trim().isEmpty ||
          !ids.add(node.id)) {
        throw ArgumentError('Nodes need a unique ID and a label.');
      }
      final Offset(:dx, :dy) = node.position;
      if (!dx.isFinite ||
          !dy.isFinite ||
          dx < 0 ||
          dx > 1 ||
          dy < 0 ||
          dy > 1) {
        throw ArgumentError.value(
          node.position,
          node.id,
          'Coordinates must be between 0 and 1.',
        );
      }
    }
    final pairs = <(String, String)>{};
    for (final link in this.links) {
      if (link.from == link.to ||
          !ids.contains(link.from) ||
          !ids.contains(link.to) ||
          !pairs.add((link.from, link.to))) {
        throw ArgumentError(
          'Connections must be unique and join two distinct diagram nodes.',
        );
      }
    }
  }

  final List<MotionNode> nodes;
  final List<MotionLink> links;
}

/// Draws a diagram at a resolved [MotionFrame] within a finite Flutter box.
/// An event with a `from` ID pulses over its matching directed connection.
class MotionGraph extends StatelessWidget {
  const MotionGraph({
    super.key,
    required this.diagram,
    required this.frame,
    this.accent = const Color(0xFF4DE2BA),
    this.pulseDuration = const Duration(milliseconds: 650),
    this.nodeBuilder,
  }) : assert(pulseDuration > Duration.zero);

  final MotionDiagram diagram;
  final MotionFrame frame;
  final Color accent;
  final Duration pulseDuration;

  /// Supplies a card inside the same bounds used by the default card.
  final Widget Function(
    BuildContext context,
    MotionNode node,
    MotionStatus status,
  )?
  nodeBuilder;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (!constraints.hasBoundedWidth || !constraints.hasBoundedHeight) {
        throw FlutterError(
          'MotionGraph needs a finite width and height. Wrap it in a SizedBox.',
        );
      }
      final size = constraints.biggest;
      if (size.isEmpty) return const SizedBox.shrink();
      final card = Size(
        math.min(156, size.width * 0.29),
        math.min(64, size.height * 0.27),
      );
      final centers = {
        for (final node in diagram.nodes)
          node.id: Offset(
            card.width / 2 + node.position.dx * (size.width - card.width),
            card.height / 2 + node.position.dy * (size.height - card.height),
          ),
      };

      return Stack(
        fit: StackFit.expand,
        children: [
          CustomPaint(
            painter: _LinksPainter(
              diagram,
              frame,
              centers,
              card,
              accent,
              pulseDuration,
            ),
          ),
          for (final node in diagram.nodes)
            Positioned.fromRect(
              rect: Rect.fromCenter(
                center: centers[node.id]!,
                width: card.width,
                height: card.height,
              ),
              child: _buildNode(context, node),
            ),
        ],
      );
    },
  );

  Widget _buildNode(BuildContext context, MotionNode node) {
    final status = frame.statusOf(node.id);
    return nodeBuilder?.call(context, node, status) ??
        _NodeCard(label: node.label, status: status, accent: accent);
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.label,
    required this.status,
    required this.accent,
  });

  final String label;
  final MotionStatus status;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final (caption, color) = switch (status) {
      MotionStatus.idle => ('Ready', const Color(0xFF99A8BF)),
      MotionStatus.active => ('Running', accent),
      MotionStatus.complete => ('Done', accent),
      MotionStatus.failed => ('Failed', const Color(0xFFFF847D)),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: status == MotionStatus.active
            ? const Color(0xFF193840)
            : const Color(0xFF18263A),
        border: Border.all(
          color: color.withValues(
            alpha: status == MotionStatus.active ? 1 : 0.4,
          ),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(color: Color(0xFFF1F6FF), fontSize: 16),
              ),
              Text(caption, style: TextStyle(color: color, fontSize: 12)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LinksPainter extends CustomPainter {
  const _LinksPainter(
    this.diagram,
    this.frame,
    this.centers,
    this.card,
    this.accent,
    this.duration,
  );

  final MotionDiagram diagram;
  final MotionFrame frame;
  final Map<String, Offset> centers;
  final Size card;
  final Color accent;
  final Duration duration;

  @override
  void paint(Canvas canvas, Size size) {
    final wire = Paint()..strokeWidth = 2;
    final trail = Paint()
      ..color = accent
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    for (final link in diagram.links) {
      final from = centers[link.from]!;
      final to = centers[link.to]!;
      final delta = to - from;
      final span = math.max(
        delta.dx.abs() / card.width,
        delta.dy.abs() / card.height,
      );
      if (span <= 1) continue;

      final inset = delta / (2 * span);
      final start = from + inset;
      final end = to - inset;
      final event = frame.latestOn(link.from, link.to);
      wire.color = event == null
          ? const Color(0xFF405370)
          : accent.withValues(alpha: 0.48);
      canvas.drawLine(start, end, wire);
      if (event == null) continue;

      final progress = frame.progressSince(event.at, duration);
      if (progress >= 1) continue;
      final head = Offset.lerp(start, end, progress)!;
      final tail = Offset.lerp(start, end, math.max(0, progress - 0.22))!;
      canvas.drawLine(tail, head, trail);
      canvas.drawCircle(head, 4, trail);
    }
  }

  @override
  bool shouldRepaint(_LinksPainter oldDelegate) =>
      diagram != oldDelegate.diagram ||
      frame != oldDelegate.frame ||
      card != oldDelegate.card ||
      accent != oldDelegate.accent ||
      duration != oldDelegate.duration ||
      !mapEquals(centers, oldDelegate.centers);
}
