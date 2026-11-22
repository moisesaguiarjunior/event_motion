/// The state of an item at a point in the timeline.
enum MotionStatus { idle, active, complete, failed }

/// A state change, optionally associated with a connection and a feed message.
final class MotionEvent {
  const MotionEvent({
    required this.at,
    required this.node,
    required this.status,
    this.from,
    this.message,
  });

  final Duration at;
  final String node;
  final MotionStatus status;
  final String? from;
  final String? message;
}

/// Events authored in chronological order. Events at a tie keep input order.
final class MotionTimeline {
  MotionTimeline(Iterable<MotionEvent> events)
    : events = List.unmodifiable(events) {
    var previous = Duration.zero;
    for (final event in this.events) {
      if (event.at < previous) {
        throw ArgumentError(
          'Events must be in chronological order at or after zero.',
        );
      }
      final from = event.from;
      if (event.node.trim().isEmpty ||
          from != null && (from.trim().isEmpty || from == event.node)) {
        throw ArgumentError(
          'An event needs a node and, if supplied, a distinct source.',
        );
      }
      previous = event.at;
    }
  }

  final List<MotionEvent> events;

  /// Resolves the same state whether the caller seeks, replays, or runs forward.
  MotionFrame at(Duration elapsed) {
    final reached = events
        .takeWhile((event) => event.at <= elapsed)
        .toList(growable: false);
    final byNode = <String, MotionEvent>{};
    final byLink = <(String, String), MotionEvent>{};
    for (final event in reached) {
      byNode[event.node] = event;
      if (event.from case final from?) byLink[(from, event.node)] = event;
    }
    return MotionFrame._(elapsed, reached, byNode, byLink);
  }
}

/// The state and event history at one supplied time.
final class MotionFrame {
  MotionFrame._(
    this.elapsed,
    List<MotionEvent> reached,
    this._byNode,
    this._byLink,
  ) : events = List.unmodifiable(reached);

  final Duration elapsed;

  /// Reached events in chronological order.
  final List<MotionEvent> events;
  final Map<String, MotionEvent> _byNode;
  final Map<(String, String), MotionEvent> _byLink;

  MotionStatus statusOf(String node) =>
      latestFor(node)?.status ?? MotionStatus.idle;

  MotionEvent? latestFor(String node) => _byNode[node];

  MotionEvent? latestOn(String from, String to) => _byLink[(from, to)];

  /// Progress through an effect triggered by an event, clamped to zero and one.
  double progressSince(Duration start, Duration duration) {
    if (duration <= Duration.zero) {
      throw ArgumentError.value(duration, 'duration', 'Must be positive.');
    }
    return ((elapsed - start).inMicroseconds / duration.inMicroseconds).clamp(
      0.0,
      1.0,
    );
  }
}
