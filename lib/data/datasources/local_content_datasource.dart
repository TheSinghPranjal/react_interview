import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/json_utils.dart';

/// Raised when bundled content is missing or not valid JSON.
class ContentLoadException implements Exception {
  ContentLoadException(this.asset, this.cause);
  final String asset;
  final Object cause;

  @override
  String toString() => 'Could not load $asset: $cause';
}

/// Reads bundled JSON content from the asset bundle. Content is offline-first:
/// nothing here touches the network.
class LocalContentDataSource {
  LocalContentDataSource(this._bundle);

  final AssetBundle _bundle;

  /// Loads a JSON array of objects from [asset].
  Future<List<JsonMap>> loadList(String asset) async {
    final String raw;
    try {
      raw = await _bundle.loadString(asset);
    } catch (e) {
      throw ContentLoadException(asset, e);
    }
    return decodeList(asset, raw);
  }

  /// Decodes a JSON array. Large payloads are decoded off the UI isolate.
  static Future<List<JsonMap>> decodeList(String asset, String raw) async {
    try {
      final decoded = raw.length > 50 * 1024
          ? await compute(_decode, raw)
          : _decode(raw);
      return decoded;
    } on FormatException catch (e) {
      throw ContentLoadException(asset, e);
    }
  }

  static List<JsonMap> _decode(String raw) {
    final Object? decoded = jsonDecode(raw);
    final Object? list = decoded is Map ? decoded['items'] : decoded;
    if (list is! List) {
      throw const FormatException('Expected a JSON array of objects');
    }
    return [
      for (final e in list)
        if (e is Map) e.cast<String, Object?>(),
    ];
  }

  /// Parses each item with [parse], skipping (and logging) invalid entries so
  /// one bad item never takes down a whole section of the app.
  static List<T> parseEach<T>(
    String asset,
    List<JsonMap> items,
    T Function(JsonMap) parse,
  ) {
    final result = <T>[];
    for (final item in items) {
      try {
        result.add(parse(item));
      } catch (e) {
        debugPrint('Skipping invalid item in $asset (${item['id']}): $e');
      }
    }
    return result;
  }
}
