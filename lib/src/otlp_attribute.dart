/// OTLP JSON attribute encoding (protobuf JSON mapping).
abstract final class OtlpAttribute {
  static Map<String, Object?> string(String key, String value) => {
        'key': key,
        'value': {'stringValue': value},
      };

  static Map<String, Object?> int64(String key, int value) => {
        'key': key,
        'value': {'intValue': value.toString()},
      };

  static Map<String, Object?> boolValue(String key, bool value) => {
        'key': key,
        'value': {'boolValue': value},
      };

  static List<Map<String, Object?>> fromMap(Map<String, String> attributes) {
    return attributes.entries
        .map((e) => string(e.key, e.value))
        .toList(growable: false);
  }

  /// Merge [extra] over [base] (extra wins on key conflict).
  static Map<String, String> merge(
    Map<String, String> base,
    Map<String, String> extra,
  ) {
    if (base.isEmpty) return Map<String, String>.from(extra);
    if (extra.isEmpty) return Map<String, String>.from(base);
    return {...base, ...extra};
  }
}
