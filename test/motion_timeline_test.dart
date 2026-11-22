import 'package:event_motion/event_motion.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const arrival = MotionEvent(
    at: Duration(seconds: 1),
    node: 'review',
    from: 'draft',
    status: MotionStatus.active,
  );
  const secondArrival = MotionEvent(
    at: Duration(seconds: 1),
    node: 'review',
    from: 'research',
    status: MotionStatus.active,
  );
  const completion = MotionEvent(
    at: Duration(seconds: 2),
    node: 'review',
    status: MotionStatus.complete,
  );

  test(
    'seeking backward restores node and link state at exact event boundaries',
    () {
      final timeline = MotionTimeline([arrival, secondArrival, completion]);

      final completed = timeline.at(completion.at);
      expect(completed.statusOf('review'), MotionStatus.complete);

      final first = timeline.at(arrival.at);
      expect(first.statusOf('review'), MotionStatus.active);
      expect(first.latestFor('review'), same(secondArrival));
      expect(first.latestOn('draft', 'review'), same(arrival));
      expect(first.latestOn('research', 'review'), same(secondArrival));
      expect(first.events, [arrival, secondArrival]);

      final earlier = timeline.at(arrival.at - const Duration(microseconds: 1));
      expect(earlier.statusOf('review'), MotionStatus.idle);
      expect(earlier.latestOn('draft', 'review'), isNull);
    },
  );

  test('progress follows elapsed time and ends at the declared duration', () {
    final timeline = MotionTimeline([arrival]);
    const duration = Duration(milliseconds: 800);
    double progress(int ms) => timeline
        .at(Duration(milliseconds: ms))
        .progressSince(arrival.at, duration);

    expect(
      [
        progress(800),
        progress(1000),
        progress(1400),
        progress(1800),
        progress(2200),
      ],
      [0, 0, 0.5, 1, 1],
    );
    expect(() => MotionTimeline([completion, arrival]), throwsArgumentError);
  });
}
