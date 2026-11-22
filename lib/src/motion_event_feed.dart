import 'package:flutter/widgets.dart';

import 'motion_timeline.dart';

/// Recent messages from a [MotionFrame], newest first.
class MotionEventFeed extends StatelessWidget {
  const MotionEventFeed({
    super.key,
    required this.frame,
    this.maxItems = 3,
    this.empty = const SizedBox.shrink(),
    this.style,
  }) : assert(maxItems > 0);

  final MotionFrame frame;
  final int maxItems;
  final Widget empty;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final messages = frame.events.reversed
        .map((event) => event.message?.trim() ?? '')
        .where((message) => message.isNotEmpty)
        .take(maxItems);
    if (messages.isEmpty) return empty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final message in messages)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              message,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
      ],
    );
  }
}
