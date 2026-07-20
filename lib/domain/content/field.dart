/// A Field is a key-value pair with a set of tags
class Field {
  final String key;

  final dynamic value;

  final Set<String> tags;

  Field({required this.key, required this.value, required this.tags});
}
