/// Validation shared by the editorial grid and the character compositions.
Map<String, Object?> editorialObject(
  Object? value,
  String path,
  Set<String> fields, {
  Set<String> optional = const {},
}) {
  if (value is! Map<String, Object?>) {
    throw FormatException('$path: expected an object');
  }
  for (final key in value.keys) {
    if (!fields.contains(key) && !optional.contains(key)) {
      throw FormatException('$path.$key: unknown field');
    }
  }
  for (final key in fields) {
    if (!value.containsKey(key)) {
      throw FormatException('$path.$key: required field');
    }
  }
  return value;
}

List<Object?> editorialList(Object? value, String path, int min, int max) {
  if (value is! List<Object?> || value.length < min || value.length > max) {
    throw FormatException('$path: expected $min–$max entries');
  }
  return value;
}

final _control = RegExp(r'[\u0000-\u001f\u007f]');
final _id = RegExp(r'^[a-z][a-z0-9_-]{0,23}$');
final _rgb = RegExp(r'^#[0-9a-fA-F]{6}$');

int editorialRgb(Object? value, String path) {
  if (value is! String || !_rgb.hasMatch(value) || value.length != 7) {
    throw FormatException('$path: expected #RRGGBB');
  }
  return 0xff000000 | int.parse(value.substring(1), radix: 16);
}

T editorialChoice<T extends Enum>(Object? value, String path, List<T> choices) {
  for (final choice in choices) {
    if (choice.name == value) return choice;
  }
  throw FormatException(
    '$path: expected one of ${choices.map((choice) => choice.name).join(', ')}',
  );
}

String editorialCopy(Object? value, String path, int maximum) {
  if (value is! String ||
      value.trim().isEmpty ||
      _control.hasMatch(value) ||
      value.runes.length > maximum) {
    throw FormatException(
      '$path: expected nonblank single-line copy up to $maximum characters',
    );
  }
  return value;
}

String editorialId(Object? value, String path) {
  if (value is! String || _id.firstMatch(value)?.end != value.length) {
    throw FormatException(
      '$path: expected a lowercase ID of up to 24 characters',
    );
  }
  return value;
}
