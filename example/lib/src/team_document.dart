import 'dart:convert';

import 'editorial_fields.dart';

enum WorkshopFigure { lantern, fold, seed, ticket, seal }

enum WorkshopPalette { forest, midnight, aubergine }

enum WorkshopPace { standard, fast }

typedef WorkshopMember = ({
  String id,
  String role,
  String note,
  WorkshopFigure figure,
  int? color,
});

/// A shared cast of one lead and four members, with optional activation groups.
final class TeamDocument {
  TeamDocument._(
    this.title,
    this.subtitle,
    this.summary,
    this.lead,
    this.palette,
    this.pace,
    List<WorkshopMember> members,
    List<List<WorkshopMember>> groups,
  ) : members = List.unmodifiable(members),
      groups = List.unmodifiable(groups.map(List<WorkshopMember>.unmodifiable));

  final String title;
  final String subtitle;
  final String summary;
  final WorkshopMember lead;
  final WorkshopPalette palette;
  final WorkshopPace pace;
  final List<WorkshopMember> members;
  final List<List<WorkshopMember>> groups;

  factory TeamDocument.parse(String source) {
    const root = r'$';
    final document = editorialObject(
      jsonDecode(source),
      root,
      const {'version', 'title', 'subtitle', 'summary', 'lead', 'members'},
      optional: const {'palette', 'pace', 'groups'},
    );
    if (document['version'] != 1) {
      throw FormatException('$root.version: expected 1');
    }
    final ids = <String>{};
    final figures = <WorkshopFigure>{};
    WorkshopMember member(Object? raw, String path) {
      final value = editorialObject(
        raw,
        path,
        const {'id', 'role', 'note', 'figure'},
        optional: const {'color'},
      );
      final id = editorialId(value['id'], '$path.id');
      if (!ids.add(id)) throw FormatException('$path.id: duplicate member $id');
      final figure = WorkshopFigure.values
          .where((figure) => figure.name == value['figure'])
          .firstOrNull;
      if (figure == null || !figures.add(figure)) {
        throw FormatException(
          '$path.figure: expected a distinct workshop figure',
        );
      }
      return (
        id: id,
        role: editorialCopy(value['role'], '$path.role', 16),
        note: editorialCopy(value['note'], '$path.note', 43),
        figure: figure,
        color: value.containsKey('color')
            ? editorialRgb(value['color'], '$path.color')
            : null,
      );
    }

    final lead = member(document['lead'], '$root.lead');
    final members = [
      for (final (index, raw) in editorialList(
        document['members'],
        '$root.members',
        4,
        4,
      ).indexed)
        member(raw, '$root.members[$index]'),
    ];
    final palette = document.containsKey('palette')
        ? editorialChoice(
            document['palette'],
            '$root.palette',
            WorkshopPalette.values,
          )
        : WorkshopPalette.forest;
    final pace = document.containsKey('pace')
        ? editorialChoice(document['pace'], '$root.pace', WorkshopPace.values)
        : WorkshopPace.standard;
    final groups = [
      for (final member in members) [member],
    ];
    if (document.containsKey('groups')) {
      groups.clear();
      final remaining = {for (final member in members) member.id: member};
      final sequence = editorialList(document['groups'], '$root.groups', 1, 4);
      for (final (index, raw) in sequence.indexed) {
        final path = '$root.groups[$index]';
        final group = <WorkshopMember>[];
        for (final (slot, value) in editorialList(raw, path, 1, 4).indexed) {
          final id = editorialId(value, '$path[$slot]');
          final member = remaining.remove(id);
          if (member == null) {
            throw FormatException(
              '$path[$slot]: unknown or repeated member $id',
            );
          }
          group.add(member);
        }
        groups.add(group);
      }
      if (remaining.isNotEmpty) {
        throw FormatException(
          '$root.groups: missing members ${remaining.keys.join(', ')}',
        );
      }
    }
    return TeamDocument._(
      editorialCopy(document['title'], '$root.title', 33),
      editorialCopy(document['subtitle'], '$root.subtitle', 74),
      editorialCopy(document['summary'], '$root.summary', 48),
      lead,
      palette,
      pace,
      members,
      groups,
    );
  }
}
