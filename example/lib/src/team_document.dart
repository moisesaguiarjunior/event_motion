import 'dart:convert';

import 'editorial_fields.dart';

enum WorkshopFigure { lantern, fold, seed, ticket, seal }

typedef WorkshopMember = ({
  String id,
  String role,
  String note,
  WorkshopFigure figure,
});

/// A shared cast of one lead and four members, in dashboard activation order.
final class TeamDocument {
  TeamDocument._(
    this.title,
    this.subtitle,
    this.summary,
    this.lead,
    List<WorkshopMember> members,
  ) : members = List.unmodifiable(members);

  final String title;
  final String subtitle;
  final String summary;
  final WorkshopMember lead;
  final List<WorkshopMember> members;

  factory TeamDocument.parse(String source) {
    const root = r'$';
    final document = editorialObject(jsonDecode(source), root, const {
      'version',
      'title',
      'subtitle',
      'summary',
      'lead',
      'members',
    });
    if (document['version'] != 1) {
      throw FormatException('$root.version: expected 1');
    }
    final ids = <String>{};
    final figures = <WorkshopFigure>{};
    WorkshopMember member(Object? raw, String path) {
      final value = editorialObject(raw, path, const {
        'id',
        'role',
        'note',
        'figure',
      });
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
    return TeamDocument._(
      editorialCopy(document['title'], '$root.title', 33),
      editorialCopy(document['subtitle'], '$root.subtitle', 74),
      editorialCopy(document['summary'], '$root.summary', 48),
      lead,
      members,
    );
  }
}
