import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/providers/core_providers.dart';
import 'core/services/storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kReleaseMode) {
      debugPrint('Flutter error: ${details.exceptionAsString()}');
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('Uncaught error: $error\n$stack');
    return true; // Handled: never crash on stray async errors (e.g. ads).
  };

  final store = await HiveKeyValueStore.open();

  runApp(
    ProviderScope(
      overrides: [keyValueStoreProvider.overrideWithValue(store)],
      // Content is bundled locally; retrying failed loads won't help.
      retry: (retryCount, error) => null,
      child: const ReactMasterApp(),
    ),
  );
}
