/// Thrown when bundled content or persisted data has an unexpected shape.
class ContentFormatException implements Exception {
  ContentFormatException(this.message);
  final String message;

  @override
  String toString() => 'ContentFormatException: $message';
}

typedef JsonMap = Map<String, Object?>;

/// Small typed readers so models never pass `dynamic` around.
extension JsonRead on JsonMap {
  String reqString(String key) {
    final v = this[key];
    if (v is String && v.trim().isNotEmpty) return v;
    throw ContentFormatException('Missing or invalid string "$key"');
  }

  String optString(String key, [String fallback = '']) {
    final v = this[key];
    return v is String ? v : fallback;
  }

  String? nullableString(String key) {
    final v = this[key];
    return v is String && v.isNotEmpty ? v : null;
  }

  int reqInt(String key) {
    final v = this[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    throw ContentFormatException('Missing or invalid int "$key"');
  }

  int optInt(String key, [int fallback = 0]) {
    final v = this[key];
    return v is num ? v.toInt() : fallback;
  }

  double optDouble(String key, [double fallback = 0]) {
    final v = this[key];
    return v is num ? v.toDouble() : fallback;
  }

  bool optBool(String key, [bool fallback = false]) {
    final v = this[key];
    return v is bool ? v : fallback;
  }

  List<String> stringList(String key) {
    final v = this[key];
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e is String) e,
    ];
  }

  List<JsonMap> mapList(String key) {
    final v = this[key];
    if (v is! List) return const [];
    return [
      for (final e in v)
        if (e is Map) e.cast<String, Object?>(),
    ];
  }

  JsonMap? obj(String key) {
    final v = this[key];
    return v is Map ? v.cast<String, Object?>() : null;
  }

  Map<String, int> intMap(String key) {
    final v = this[key];
    if (v is! Map) return {};
    return {
      for (final e in v.entries)
        if (e.key is String && e.value is num)
          e.key as String: (e.value as num).toInt(),
    };
  }

  Map<String, String> stringMap(String key) {
    final v = this[key];
    if (v is! Map) return {};
    return {
      for (final e in v.entries)
        if (e.key is String && e.value is String)
          e.key as String: e.value as String,
    };
  }
}
