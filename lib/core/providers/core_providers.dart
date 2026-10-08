import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/storage_service.dart';

/// Persistent key-value store. Overridden in `main()` with the opened Hive
/// store, and in tests with an [InMemoryKeyValueStore].
final keyValueStoreProvider = Provider<KeyValueStore>(
  (ref) => InMemoryKeyValueStore(),
);

/// Injectable clock so date-based logic (streaks, daily challenge) is testable.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);

/// Injectable randomness for quiz generation.
final randomProvider = Provider<Random>((ref) => Random());

/// Asset bundle for bundled content (overridable in tests).
final assetBundleProvider = Provider<AssetBundle>((ref) => rootBundle);
