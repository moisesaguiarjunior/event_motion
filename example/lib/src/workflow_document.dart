import 'dart:convert';

typedef WorkflowNode = ({String id, String label});
typedef WorkflowLink = ({String from, String to});
typedef WorkflowEvent = ({
  int atMs,
  String node,
  String? from,
  String status,
  String? message,
});

Duration motionTimeAtFrame(int frame, int fps) => Duration(
  microseconds: (frame * Duration.microsecondsPerSecond / fps).round(),
);

/// Validated input for the agent pipeline composition.
final class WorkflowDocument {
  const WorkflowDocument._({
    required this.title,
    required this.subtitle,
    required this.locale,
    required this.frameCount,
    required this.coverFrame,
    required this.layout,
    required this.nodes,
    required this.links,
    required this.events,
  });

  static const fps = 24;

  final String title;
  final String? subtitle;
  final String locale;
  final int frameCount;
  final int coverFrame;
  final String layout;
  final List<WorkflowNode> nodes;
  final List<WorkflowLink> links;
  final List<WorkflowEvent> events;

  factory WorkflowDocument.parse(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException catch (error) {
      _invalid(r'$', 'invalid JSON (${error.message})');
    }
    return WorkflowDocument.fromJson(json);
  }

  factory WorkflowDocument.fromJson(Object? value) {
    const root = r'$';
    final spec = _fields(
      value,
      root,
      const {
        'version',
        'template',
        'title',
        'layout',
        'durationMs',
        'coverMs',
        'nodes',
        'links',
        'events',
      },
      optional: const {'subtitle', 'locale'},
    );
    if (spec['version'] != 1) _invalid('$root.version', 'expected version 1');
    if (spec['template'] != 'agent_pipeline') {
      _invalid('$root.template', 'expected agent_pipeline');
    }
    final title = _text(spec['title'], '$root.title', 36);
    final subtitle = spec.containsKey('subtitle')
        ? _text(spec['subtitle'], '$root.subtitle', 72)
        : null;
    final locale = spec.containsKey('locale') ? spec['locale'] : 'en';
    if (locale is! String || locale != 'en' && locale != 'pt-BR') {
      _invalid('$root.locale', 'expected en or pt-BR');
    }
    final layout = spec['layout'];
    if (layout is! String || layout != 'diamond' && layout != 'vertical') {
      _invalid('$root.layout', 'expected diamond or vertical');
    }
    final duration = _integer(
      spec['durationMs'],
      '$root.durationMs',
      250,
      60000,
    );
    final cover = _integer(spec['coverMs'], '$root.coverMs', 0, duration - 1);
    final frameCount = _frameFor(duration);
    final coverFrame = _frameFor(cover);
    if (coverFrame >= frameCount) {
      _invalid('$root.coverMs', 'rounds past the final frame at $fps fps');
    }

    final nodes = _nodes(
      spec['nodes'],
      '$root.nodes',
      diamond: layout == 'diamond',
    );
    final ids = {for (final node in nodes) node.id};
    final links = _links(spec['links'], '$root.links', ids);
    final events = _events(spec['events'], '$root.events', ids, {
      for (final link in links) (link.from, link.to),
    }, motionTimeAtFrame(frameCount - 1, fps).inMilliseconds);

    return WorkflowDocument._(
      title: title,
      subtitle: subtitle,
      locale: locale,
      frameCount: frameCount,
      coverFrame: coverFrame,
      layout: layout,
      nodes: List.unmodifiable(nodes),
      links: List.unmodifiable(links),
      events: List.unmodifiable(events),
    );
  }

  static int _frameFor(int milliseconds) => (milliseconds / 1000 * fps).round();
}

List<WorkflowNode> _nodes(Object? value, String path, {required bool diamond}) {
  final entries = _array(value, path, min: diamond ? 4 : 1, max: 4);
  final seen = <String>{};
  final nodes = <WorkflowNode>[];
  for (final (index, entry) in entries.indexed) {
    final item = '$path[$index]';
    final node = _fields(entry, item, const {'id', 'label'});
    final id = _nodeId(node['id'], '$item.id');
    if (!seen.add(id)) _invalid('$item.id', 'duplicate node $id');
    nodes.add((id: id, label: _text(node['label'], '$item.label', 18)));
  }
  return nodes;
}

List<WorkflowLink> _links(Object? value, String path, Set<String> ids) {
  final entries = _array(value, path, max: 12);
  final seen = <(String, String)>{};
  final links = <WorkflowLink>[];
  for (final (index, entry) in entries.indexed) {
    final item = '$path[$index]';
    final link = _fields(entry, item, const {'from', 'to'});
    final from = _reference(link['from'], '$item.from', ids);
    final to = _reference(link['to'], '$item.to', ids);
    if (from == to) _invalid('$item.to', 'must differ from from');
    if (!seen.add((from, to))) {
      _invalid(item, 'duplicate connection $from → $to');
    }
    links.add((from: from, to: to));
  }
  return links;
}

List<WorkflowEvent> _events(
  Object? value,
  String path,
  Set<String> ids,
  Set<(String, String)> links,
  int lastFrameMs,
) {
  final entries = _array(value, path, min: 1);
  final events = <WorkflowEvent>[];
  var previous = 0;
  for (final (index, entry) in entries.indexed) {
    final item = '$path[$index]';
    final event = _fields(
      entry,
      item,
      const {'atMs', 'node', 'status'},
      optional: const {'from', 'message'},
    );
    final at = _integer(event['atMs'], '$item.atMs', 0, lastFrameMs);
    if (at < previous) {
      _invalid('$item.atMs', 'events must be in chronological order');
    }
    previous = at;
    final node = _reference(event['node'], '$item.node', ids);
    final from = event.containsKey('from')
        ? _reference(event['from'], '$item.from', ids)
        : null;
    if (from != null && !links.contains((from, node))) {
      _invalid('$item.from', 'connection $from → $node is missing from links');
    }
    final status = event['status'];
    if (status is! String ||
        !const {'idle', 'active', 'complete', 'failed'}.contains(status)) {
      _invalid('$item.status', 'expected idle, active, complete or failed');
    }
    events.add((
      atMs: at,
      node: node,
      from: from,
      status: status,
      message: event.containsKey('message')
          ? _text(event['message'], '$item.message', 48)
          : null,
    ));
  }
  return events;
}

Map<String, Object?> _fields(
  Object? value,
  String path,
  Set<String> required, {
  Set<String> optional = const {},
}) {
  if (value is! Map<String, Object?>) _invalid(path, 'expected an object');
  for (final key in value.keys) {
    if (!required.contains(key) && !optional.contains(key)) {
      _invalid('$path.$key', 'unknown field');
    }
  }
  for (final key in required) {
    if (!value.containsKey(key)) _invalid('$path.$key', 'required field');
  }
  return value;
}

List<Object?> _array(Object? value, String path, {int min = 0, int? max}) {
  if (value is! List<Object?>) _invalid(path, 'expected an array');
  if (value.length < min || max != null && value.length > max) {
    final range = switch (max) {
      null => 'at least $min',
      _ when max == min => 'exactly $min',
      _ => 'between $min and $max',
    };
    _invalid(path, 'expected $range items');
  }
  return value;
}

int _integer(Object? value, String path, int min, int max) {
  if (value is! num ||
      !value.isFinite ||
      value < min ||
      value > max ||
      value != value.truncate()) {
    _invalid(path, 'expected an integer between $min and $max');
  }
  return value.toInt();
}

final _nodeIdPattern = RegExp(r'^[a-z][a-z0-9_-]{0,23}$');
final _controlCharacter = RegExp(r'[\u0000-\u001f\u007f]');

String _nodeId(Object? value, String path) {
  if (value is! String ||
      _nodeIdPattern.firstMatch(value)?.end != value.length) {
    _invalid(
      path,
      'expected a lowercase ID of up to 24 letters, digits, underscores or hyphens',
    );
  }
  return value;
}

String _reference(Object? value, String path, Set<String> ids) {
  final id = _nodeId(value, path);
  if (!ids.contains(id)) _invalid(path, 'unknown node $id');
  return id;
}

String _text(Object? value, String path, int max) {
  if (value is! String ||
      value.trim().isEmpty ||
      _controlCharacter.hasMatch(value) ||
      value.runes.length > max) {
    _invalid(
      path,
      'expected nonblank text up to $max characters without control characters',
    );
  }
  return value;
}

Never _invalid(String path, String message) =>
    throw FormatException('$path: $message');
