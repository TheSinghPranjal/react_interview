import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../data/models/json_utils.dart';

/// Minimal persistence abstraction. Repositories depend on this, never on
/// Hive directly, so storage can be swapped or faked in tests.
abstract interface class KeyValueStore {
  String? read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
  Future<void> clear();
}

extension KeyValueStoreJson on KeyValueStore {
  /// Reads a JSON object. Returns null if missing or corrupt.
  JsonMap? readJson(String key) {
    final raw = read(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? decoded.cast<String, Object?>() : null;
    } on FormatException catch (e) {
      debugPrint('Corrupt JSON for "$key": $e');
      return null;
    }
  }

  /// Reads a JSON array. Returns null if missing or corrupt.
  List<Object?>? readJsonList(String key) {
    final raw = read(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded.cast<Object?>() : null;
    } on FormatException catch (e) {
      debugPrint('Corrupt JSON for "$key": $e');
      return null;
    }
  }

  /// Writes JSON, swallowing (but logging) persistence failures so a disk
  /// error never crashes the UI. Returns whether the write succeeded.
  Future<bool> writeJson(String key, Object value) async {
    try {
      await write(key, jsonEncode(value));
      return true;
    } catch (e, st) {
      debugPrint('Failed to persist "$key": $e\n$st');
      return false;
    }
  }
}

class HiveKeyValueStore implements KeyValueStore {
  HiveKeyValueStore(this._box);

  static const String boxName = 'react_master_store';

  final Box<String> _box;

  /// Initialises Hive and opens the app box. If the box is corrupt it is
  /// deleted and recreated; if Hive is unavailable entirely an in-memory
  /// store is returned so the app can still run.
  static Future<KeyValueStore> open() async {
    try {
      await Hive.initFlutter();
      return HiveKeyValueStore(await Hive.openBox<String>(boxName));
    } catch (e) {
      debugPrint('Hive open failed, attempting recovery: $e');
      try {
        await Hive.deleteBoxFromDisk(boxName);
        return HiveKeyValueStore(await Hive.openBox<String>(boxName));
      } catch (e2) {
        debugPrint('Hive unavailable, falling back to memory: $e2');
        return InMemoryKeyValueStore();
      }
    }
  }

  @override
  String? read(String key) => _box.get(key);

  @override
  Future<void> write(String key, String value) => _box.put(key, value);

  @override
  Future<void> delete(String key) => _box.delete(key);

  @override
  Future<void> clear() async {
    await _box.clear();
  }
}

class InMemoryKeyValueStore implements KeyValueStore {
  InMemoryKeyValueStore([Map<String, String>? initial]) : _data = {...?initial};

  final Map<String, String> _data;

  @override
  String? read(String key) => _data[key];

  @override
  Future<void> write(String key, String value) async => _data[key] = value;

  @override
  Future<void> delete(String key) async => _data.remove(key);

  @override
  Future<void> clear() async => _data.clear();
}
