import 'package:event_motion/event_motion.dart';
import 'package:flutter/widgets.dart';
import 'package:fluvie/fluvie.dart' as video;

import 'workflow_document.dart';

Widget atMotionTime(
  MotionTimeline timeline,
  Widget Function(MotionFrame) build,
) {
  // The example pins the Fluvie revision that exports this frame clock.
  // ignore: experimental_member_use
  return video.FrameBuilder((clock) {
    final localFrame = clock.frame - clock.scope.startFrame;
    return build(timeline.at(motionTimeAtFrame(localFrame, clock.fps)));
  });
}
