import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'illustration_document.dart';

const _maxBytes = 4 * 1024 * 1024;
const _maxSide = 2048;
const _pngHeader = [
  137,
  80,
  78,
  71,
  13,
  10,
  26,
  10,
  0,
  0,
  0,
  13,
  73,
  72,
  68,
  82,
];

/// Decodes local sidecars before Fluvie starts capturing frames.
Future<Map<String, ui.Image>> loadIllustrationArtwork(
  IllustrationDocument document,
  Directory inputDirectory,
) async {
  final directory = '${inputDirectory.path}${Platform.pathSeparator}assets';
  final images = <String, ui.Image>{};
  try {
    for (final name in document.assetNames) {
      final path = '$directory${Platform.pathSeparator}$name';
      if (FileSystemEntity.typeSync(directory, followLinks: false) !=
              FileSystemEntityType.directory ||
          FileSystemEntity.typeSync(path, followLinks: false) !=
              FileSystemEntityType.file) {
        throw FormatException(
          'artwork $name: expected a PNG file in the assets folder beside visual.json',
        );
      }
      final file = await File(path).open();
      final Uint8List bytes;
      try {
        bytes = await file.read(_maxBytes + 1);
      } finally {
        await file.close();
      }
      if (bytes.length < 33 ||
          bytes.length > _maxBytes ||
          _pngHeader.indexed.any((part) => bytes[part.$1] != part.$2)) {
        throw FormatException('artwork $name: expected a PNG file up to 4 MiB');
      }
      final dimensions = ByteData.sublistView(bytes);
      final width = dimensions.getUint32(16);
      final height = dimensions.getUint32(20);
      if (width < 1 || width > _maxSide || height < 1 || height > _maxSide) {
        throw FormatException(
          'artwork $name: expected dimensions within 2048 × 2048',
        );
      }
      final codec = await ui.instantiateImageCodec(bytes);
      try {
        if (codec.frameCount != 1) {
          throw FormatException('artwork $name: expected a single-frame PNG');
        }
        images[name] = (await codec.getNextFrame()).image;
      } finally {
        codec.dispose();
      }
    }
    return Map.unmodifiable(images);
  } catch (_) {
    for (final image in images.values) {
      image.dispose();
    }
    rethrow;
  }
}
