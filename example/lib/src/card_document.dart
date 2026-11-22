import 'dart:convert';

typedef CardEntry = ({
  String id,
  String title,
  String caption,
  String color,
  int atMs,
});

/// Shared inputs for the Flutter and HyperFrames examples.
final class CardDocument {
  CardDocument._(
    this.title,
    this.subtitle,
    this.durationMs,
    this.mosaicMs,
    this.coverMs,
    List<CardEntry> cards,
  ) : cards = List.unmodifiable(cards);

  final String title;
  final String subtitle;
  final int durationMs;
  final int mosaicMs;
  final int coverMs;
  final List<CardEntry> cards;

  factory CardDocument.parse(String source) {
    final raw = jsonDecode(source);
    if (raw is! Map<String, Object?>) {
      throw const FormatException('Expected a card document object.');
    }
    final title = _copy(raw['title'], 'title', 20);
    final subtitle = _copy(raw['subtitle'], 'subtitle', 42);
    final duration = _milliseconds(raw['durationMs'], 'durationMs');
    final mosaic = _milliseconds(raw['mosaicMs'], 'mosaicMs');
    final cover = _milliseconds(raw['coverMs'], 'coverMs');
    if (duration > 30000 || cover < mosaic + 620 || cover + 42 >= duration) {
      throw const FormatException(
        'Cover must follow the mosaic and fit inside a clip of at most 30 seconds.',
      );
    }
    final values = raw['cards'];
    const kinds = ['outline', 'layout', 'motion', 'export'];
    if (values is! List<Object?> || values.length != kinds.length) {
      throw const FormatException(
        'Expected the four card slots outline, layout, motion and export.',
      );
    }
    final cards = <CardEntry>[];
    for (final (index, value) in values.indexed) {
      if (value is! Map<String, Object?> || value['id'] != kinds[index]) {
        throw FormatException('cards[$index].id must be ${kinds[index]}.');
      }
      final at = _milliseconds(value['atMs'], 'cards[$index].atMs');
      if (at + 790 > mosaic ||
          (index == 0 ? at != 0 : at < cards.last.atMs + 790)) {
        throw FormatException(
          'cards[$index].atMs needs a complete preview window before the next cue.',
        );
      }
      final color = value['color'];
      if (color is! String || !RegExp(r'^#[0-9a-fA-F]{6}$').hasMatch(color)) {
        throw FormatException(
          'cards[$index].color must be a six-digit hex color.',
        );
      }
      cards.add((
        id: kinds[index],
        atMs: at,
        title: _copy(value['title'], 'cards[$index].title', 11),
        caption: _copy(value['caption'], 'cards[$index].caption', 38),
        color: color,
      ));
    }
    return CardDocument._(title, subtitle, duration, mosaic, cover, cards);
  }
}

String _copy(Object? value, String path, int max) {
  if (value is! String ||
      value.trim().isEmpty ||
      value.runes.length > max ||
      RegExp(r'[\u0000-\u001f\u007f]').hasMatch(value)) {
    throw FormatException(
      '$path must be nonblank single-line text of up to $max characters.',
    );
  }
  return value;
}

int _milliseconds(Object? value, String path) {
  if (value is! int || value < 0 || value > 30000) {
    throw FormatException('$path must be an integer between 0 and 30000.');
  }
  return value;
}
