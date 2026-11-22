import 'package:flutter/widgets.dart';
import 'package:fluvie/fluvie.dart' as video;

import 'src/card_document.dart';

const _paper = Color(0xFFF4EFE6);
const _ink = Color(0xFF202C2F);
const _leadFrames = 18;

/// Starts an external render 750 ms into a Flutter-owned composition.
video.Video build(
  CardDocument cards,
  String clip,
  int clipFrames, {
  required bool overlay,
}) => video.Video(
  width: 1080,
  height: 1350,
  fps: 24,
  poster: video.Time.frames(_leadFrames + (cards.coverMs / 1000 * 24).round()),
  scenes: [
    video.Scene(
      duration: const video.Time.frames(_leadFrames),
      background: video.Background.color(_ink),
      children: [
        Center(
          child: Text(
            cards.title,
            style: const TextStyle(
              color: _paper,
              fontSize: 72,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    ),
    video.Scene(
      duration: video.Time.frames(clipFrames),
      background: video.Background.color(_paper),
      children: [
        if (overlay)
          Positioned.fill(
            child: FittedBox(
              child: SizedBox(
                width: 480,
                height: 600,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(30, 41, 30, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cards.title,
                        style: const TextStyle(
                          color: _ink,
                          fontSize: 35,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        cards.subtitle,
                        style: const TextStyle(color: _ink, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: video.Clip.file(
            clip,
            fit: BoxFit.fill,
            audio: overlay
                ? const video.ClipAudio.muted()
                : const video.ClipAudio.included(),
          ),
        ),
      ],
    ),
  ],
);
