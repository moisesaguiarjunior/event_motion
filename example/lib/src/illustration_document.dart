import 'dart:convert';

import 'editorial_fields.dart';

enum IllustrationSymbol {
  organization,
  marketplace,
  application,
  compute,
  storage,
  shield,
  queue,
}

typedef IllustrationCard = ({
  String title,
  String detail,
  IllustrationSymbol symbol,
  String? asset,
});
typedef IllustrationNote = ({String text, List<String> sourceIds});

final class IllustrationDocument {
  IllustrationDocument._({
    required this.title,
    required this.subtitle,
    required this.origin,
    required this.channel,
    required this.destinations,
    required this.annotation,
    required this.sources,
  });

  final String title;
  final String subtitle;
  final IllustrationCard origin;
  final IllustrationCard channel;
  final List<IllustrationCard> destinations;
  final IllustrationNote? annotation;
  final Map<String, String> sources;

  Set<String> get assetNames => {
    for (final card in [origin, channel, ...destinations]) ?card.asset,
  };

  factory IllustrationDocument.parse(String input) {
    const root = r'$';
    final document = editorialObject(
      jsonDecode(input),
      root,
      const {
        'version',
        'title',
        'subtitle',
        'origin',
        'channel',
        'destinations',
        'sources',
      },
      optional: const {'annotation', 'alt_text'},
    );
    if (document['version'] != 1) {
      throw const FormatException('$root.version: expected 1');
    }
    if (document.containsKey('alt_text')) {
      editorialCopy(document['alt_text'], '$root.alt_text', 1000);
    }

    final sources = <String, String>{};
    for (final (index, raw) in editorialList(
      document['sources'],
      '$root.sources',
      1,
      3,
    ).indexed) {
      final path = '$root.sources[$index]';
      final source = editorialObject(raw, path, const {'id', 'label'});
      final id = editorialCopy(source['id'], '$path.id', 12);
      if (!_sourceId.hasMatch(id) || sources.containsKey(id)) {
        throw FormatException('$path.id: expected a unique source ID');
      }
      sources[id] = editorialCopy(source['label'], '$path.label', 32);
    }

    IllustrationNote? annotation;
    if (document.containsKey('annotation')) {
      const path = '$root.annotation';
      final note = editorialObject(document['annotation'], path, const {
        'text',
        'source_ids',
      });
      final citations = <String>{};
      for (final (index, raw) in editorialList(
        note['source_ids'],
        '$path.source_ids',
        1,
        3,
      ).indexed) {
        if (raw is! String ||
            !sources.containsKey(raw) ||
            !citations.add(raw)) {
          throw FormatException(
            '$path.source_ids[$index]: unknown or repeated source ID',
          );
        }
      }
      annotation = (
        text: editorialCopy(note['text'], '$path.text', 105),
        sourceIds: List.unmodifiable(citations),
      );
    }

    final rawDestinations = editorialList(
      document['destinations'],
      '$root.destinations',
      1,
      2,
    );
    return IllustrationDocument._(
      title: editorialCopy(document['title'], '$root.title', 62),
      subtitle: editorialCopy(document['subtitle'], '$root.subtitle', 105),
      origin: _card(document['origin'], '$root.origin'),
      channel: _card(document['channel'], '$root.channel'),
      destinations: List.unmodifiable([
        for (final (index, raw) in rawDestinations.indexed)
          _card(raw, '$root.destinations[$index]'),
      ]),
      annotation: annotation,
      sources: Map.unmodifiable(sources),
    );
  }
}

IllustrationCard _card(Object? raw, String path) {
  final card = editorialObject(
    raw,
    path,
    const {'title', 'detail', 'symbol'},
    optional: const {'asset'},
  );
  String? asset;
  if (card.containsKey('asset')) {
    asset = editorialCopy(card['asset'], '$path.asset', 52);
    if (!_assetName.hasMatch(asset)) {
      throw FormatException(
        '$path.asset: expected a lowercase PNG filename without a path',
      );
    }
  }
  return (
    title: editorialCopy(card['title'], '$path.title', 34),
    detail: editorialCopy(card['detail'], '$path.detail', 58),
    symbol: editorialChoice(
      card['symbol'],
      '$path.symbol',
      IllustrationSymbol.values,
    ),
    asset: asset,
  );
}

final _sourceId = RegExp(r'^[a-zA-Z0-9_-]+$');
final _assetName = RegExp(r'^[a-z0-9][a-z0-9_-]{0,47}\.png$');
