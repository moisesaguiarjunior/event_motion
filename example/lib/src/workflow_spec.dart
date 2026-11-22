import 'dart:convert';

import 'package:event_motion/event_motion.dart';
import 'package:flutter/widgets.dart' show Offset;

import 'motion_clock.dart';

/// Validated input for the agent pipeline composition.
final class WorkflowSpec {
  const WorkflowSpec._({
    required this.title,
    required this.subtitle,
    required this.frameCount,
    required this.coverFrame,
    required this.diagram,
    required this.timeline,
  });

  static const fps = 24;

  final String title;
  final String? subtitle;
  final int frameCount;
  final int coverFrame;
  final MotionDiagram diagram;
  final MotionTimeline timeline;

  factory WorkflowSpec.parse(String source) {
    final Object? json;
    try {
      json = jsonDecode(source);
    } on FormatException catch (error) {
      _invalid(r'$', 'invalid JSON (${error.message})');
    }
    return WorkflowSpec.fromJson(json);
  }

  factory WorkflowSpec.fromJson(Object? value) {
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
      optional: const {'subtitle'},
    );
    if (spec['version'] != 1) _invalid('$root.version', 'expected version 1');
    if (spec['template'] != 'agent_pipeline') {
      _invalid('$root.template', 'expected agent_pipeline');
    }
    final title = _text(spec['title'], '$root.title', 36);
    final subtitle = spec.containsKey('subtitle')
        ? _text(spec['subtitle'], '$root.subtitle', 72)
        : null;
    final layout = spec['layout'];
    if (layout != 'diamond' && layout != 'vertical') {
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

    return WorkflowSpec._(
      title: title,
      subtitle: subtitle,
      frameCount: frameCount,
      coverFrame: coverFrame,
      diagram: MotionDiagram(nodes: nodes, links: links),
      timeline: MotionTimeline(events),
    );
  }

  static int _frameFor(int milliseconds) => (milliseconds / 1000 * fps).round();
}

List<MotionNode> _nodes(Object? value, String path, {required bool diamond}) {
  final entries = _array(value, path, min: diamond ? 4 : 1, max: 4);
  const diamondPositions = [
    Offset(0.5, 0),
    Offset(0, 0.44),
    Offset(1, 0.44),
    Offset(0.5, 0.94),
  ];
  final seen = <String>{};
  return [
    for (final (index, entry) in entries.indexed)
      _node(
        entry,
        '$path[$index]',
        diamond
            ? diamondPositions[index]
            : Offset(
                0.5,
                entries.length == 1 ? 0.5 : index / (entries.length - 1),
              ),
        seen,
      ),
  ];
}

MotionNode _node(
  Object? value,
  String path,
  Offset position,
  Set<String> seen,
) {
  final node = _fields(value, path, const {'id', 'label'});
  final id = _nodeId(node['id'], '$path.id');
  if (!seen.add(id)) _invalid('$path.id', 'duplicate node $id');
  return MotionNode(id, _text(node['label'], '$path.label', 18), position);
}

List<MotionLink> _links(Object? value, String path, Set<String> ids) {
  final entries = _array(value, path, max: 12);
  final seen = <(String, String)>{};
  final links = <MotionLink>[];
  for (final (index, entry) in entries.indexed) {
    final item = '$path[$index]';
    final link = _fields(entry, item, const {'from', 'to'});
    final from = _reference(link['from'], '$item.from', ids);
    final to = _reference(link['to'], '$item.to', ids);
    if (from == to) _invalid('$item.to', 'must differ from from');
    if (!seen.add((from, to))) {
      _invalid(item, 'duplicate connection $from → $to');
    }
    links.add(MotionLink(from, to));
  }
  return links;
}

List<MotionEvent> _events(
  Object? value,
  String path,
  Set<String> ids,
  Set<(String, String)> links,
  int lastFrameMs,
) {
  final entries = _array(value, path, min: 1);
  final events = <MotionEvent>[];
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
    final status = switch (event['status']) {
      'idle' => MotionStatus.idle,
      'active' => MotionStatus.active,
      'complete' => MotionStatus.complete,
      'failed' => MotionStatus.failed,
      _ => _invalid(
        '$item.status',
        'expected idle, active, complete or failed',
      ),
    };
    events.add(
      MotionEvent(
        at: Duration(milliseconds: at),
        node: node,
        from: from,
        status: status,
        message: event.containsKey('message')
            ? _text(event['message'], '$item.message', 48)
            : null,
      ),
    );
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
