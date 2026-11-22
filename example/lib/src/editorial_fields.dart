/// Validation shared by the editorial grid and the character compositions.
Map<String, Object?> editorialObject(
  Object? value,
  String path,
  Set<String> fields,
) {
  if (value is! Map<String, Object?>) {
    throw FormatException('$path: expected an object');
  }
  for (final key in value.keys) {
    if (!fields.contains(key)) {
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
