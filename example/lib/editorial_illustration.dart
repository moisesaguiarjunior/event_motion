import 'dart:ui' as ui;

import 'package:event_motion/event_motion.dart';
import 'package:fluvie/fluvie.dart' as video;
import 'package:flutter/material.dart';

import 'src/illustration_document.dart';
import 'src/motion_clock.dart';

const _paper = Color(0xFFF6F4EE);
const _ink = Color(0xFF18292F);
const _muted = Color(0xFF485B62);
const _rule = Color(0xFF899B9E);
const _teal = Color(0xFF0D5351);
const _white = Color(0xFFFFFDF9);

video.Video build(
  IllustrationDocument document, {
  required bool animated,
  Map<String, ui.Image> artwork = const {},
}) {
  if (!artwork.keys.toSet().containsAll(document.assetNames)) {
    throw ArgumentError(
      'Load every referenced illustration asset before rendering.',
    );
  }
  final frames = animated ? 120 : 1;
  return video.Video(
    width: 1080,
    height: 1350,
    fps: 24,
    poster: video.Time.frames(frames - 1),
    scenes: [
      video.Scene(
        duration: video.Time.frames(frames),
        children: [
          Positioned.fill(
            child: FittedBox(
              child: SizedBox(
                width: 480,
                height: 600,
                child: atMotionTime(MotionTimeline(const []), (frame) {
                  double reveal(int at) => animated
                      ? Curves.easeOutCubic.transform(
                          frame.progressSince(
                            Duration(milliseconds: at),
                            const Duration(milliseconds: 350),
                          ),
                        )
                      : 1;
                  return _Composition(
                    document,
                    artwork: artwork,
                    channel: reveal(400),
                    destinations: reveal(1100),
                    note: reveal(2050),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    ],
  );
}

class _Composition extends StatelessWidget {
  const _Composition(
    this.document, {
    required this.artwork,
    required this.channel,
    required this.destinations,
    required this.note,
  });

  final IllustrationDocument document;
  final Map<String, ui.Image> artwork;
  final double channel;
  final double destinations;
  final double note;

  @override
  Widget build(BuildContext context) => ColoredBox(
    color: _paper,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(24, 23, 24, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Align(
            alignment: Alignment.centerLeft,
            child: SizedBox(
              width: 42,
              height: 4,
              child: ColoredBox(color: _teal),
            ),
          ),
          const SizedBox(height: 11),
          _fitCopy(
            document.title,
            79,
            size: 37,
            weight: FontWeight.w800,
            height: 1.02,
          ),
          const SizedBox(height: 4),
          _fitCopy(document.subtitle, 42, size: 17, color: _muted),
          const SizedBox(height: 13),
          _centeredCard(
            _Card(
              document.origin,
              color: _teal,
              artwork: artwork[document.origin.asset],
            ),
            height: 56,
          ),
          Opacity(
            opacity: channel,
            child: const SizedBox(
              height: 24,
              child: CustomPaint(painter: _Routes(1)),
            ),
          ),
          Opacity(
            opacity: channel,
            child: _centeredCard(
              _Card(
                document.channel,
                color: _white,
                highlighted: true,
                artwork: artwork[document.channel.asset],
              ),
              height: 66,
            ),
          ),
          Opacity(
            opacity: destinations,
            child: SizedBox(
              height: 39,
              child: CustomPaint(
                painter: _Routes(document.destinations.length),
              ),
            ),
          ),
          Opacity(
            opacity: destinations,
            child: SizedBox(
              height: 101,
              child: Row(
                children: [
                  for (final (index, item)
                      in document.destinations.indexed) ...[
                    if (index > 0) const SizedBox(width: 14),
                    Expanded(
                      child: _Card(
                        item,
                        artwork: artwork[item.asset],
                        color: index == 0 ? _teal : const Color(0xFF8A462D),
                        vertical: true,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 15),
          if (document.annotation case final annotation?)
            Opacity(
              opacity: note,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFE5EBE5),
                  border: Border(left: BorderSide(color: _teal, width: 3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  child: _fitCopy(
                    '${annotation.text} ${annotation.sourceIds.map((id) => '[$id]').join(' ')}',
                    45,
                    size: 16,
                    weight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          const Spacer(),
          const SizedBox(height: 1, child: ColoredBox(color: _rule)),
          const SizedBox(height: 5),
          _fitCopy(
            document.sources.entries
                .map((source) => '[${source.key}] ${source.value}')
                .join('   ·   '),
            29,
            size: 13,
            color: _muted,
          ),
        ],
      ),
    ),
  );

  Widget _centeredCard(Widget child, {required double height}) => Align(
    alignment: Alignment.center,
    child: SizedBox(width: 286, height: height, child: child),
  );
}

class _Card extends StatelessWidget {
  const _Card(
    this.card, {
    required this.color,
    this.artwork,
    this.highlighted = false,
    this.vertical = false,
  });

  final IllustrationCard card;
  final Color color;
  final ui.Image? artwork;
  final bool highlighted;
  final bool vertical;

  @override
  Widget build(BuildContext context) {
    final copyColor = highlighted ? _white : _ink;
    final secondary = highlighted ? const Color(0xFFD5E9E4) : _muted;
    final image = artwork;
    final icon = image != null
        ? RawImage(
            image: image,
            width: vertical ? 58 : 42,
            height: vertical ? 30 : 40,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          )
        : Icon(_icon(card.symbol), size: vertical ? 24 : 27, color: color);
    final title = _fitCopy(
      card.title,
      vertical ? 32 : 25,
      size: 19,
      weight: FontWeight.w800,
      color: copyColor,
    );
    final detail = _fitCopy(
      card.detail,
      vertical ? 26 : 19,
      size: 14,
      color: secondary,
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: highlighted ? _teal : _white,
        border: Border.all(color: highlighted ? _teal : _rule),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: vertical
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Align(alignment: Alignment.centerLeft, child: icon),
                  title,
                  detail,
                ],
              )
            : Row(
                children: [
                  SizedBox(
                    width: artwork == null ? 36 : 48,
                    height: artwork == null ? 36 : 40,
                    child: icon,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [title, detail],
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

IconData _icon(IllustrationSymbol symbol) => switch (symbol) {
  IllustrationSymbol.organization => Icons.business_outlined,
  IllustrationSymbol.marketplace => Icons.storefront_outlined,
  IllustrationSymbol.application => Icons.window_outlined,
  IllustrationSymbol.compute => Icons.memory_outlined,
  IllustrationSymbol.storage => Icons.storage_outlined,
  IllustrationSymbol.shield => Icons.shield_outlined,
  IllustrationSymbol.queue => Icons.view_stream_outlined,
};

class _Routes extends CustomPainter {
  const _Routes(this.count);

  final int count;

  @override
  void paint(Canvas canvas, Size size) {
    const gap = 14.0;
    final center = size.width / 2;
    final branch = size.height * .48;
    final left = (size.width - gap) / 4;
    final ends = count == 1 ? [center] : [left, size.width - left];
    final route = Paint()
      ..color = _teal
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(center, 0), Offset(center, branch), route);
    canvas.drawLine(
      Offset(ends.first, branch),
      Offset(ends.last, branch),
      route,
    );
    for (final end in ends) {
      final tip = Offset(end, size.height - 2);
      canvas.drawLine(Offset(end, branch), tip, route);
      canvas.drawLine(tip, tip + const Offset(-4, -4), route);
      canvas.drawLine(tip, tip + const Offset(4, -4), route);
    }
  }

  @override
  bool shouldRepaint(_Routes oldDelegate) => oldDelegate.count != count;
}

Widget _fitCopy(
  String text,
  double boxHeight, {
  required double size,
  Color color = _ink,
  FontWeight weight = FontWeight.w400,
  double height = 1.12,
}) => SizedBox(
  height: boxHeight,
  child: LayoutBuilder(
    builder: (context, bounds) => FittedBox(
      alignment: Alignment.centerLeft,
      fit: BoxFit.scaleDown,
      child: SizedBox(
        width: bounds.maxWidth,
        child: Text(
          text,
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: size,
            height: height,
            color: color,
            fontWeight: weight,
          ),
        ),
      ),
    ),
  ),
);
