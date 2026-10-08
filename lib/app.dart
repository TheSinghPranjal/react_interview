import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/constants/app_constants.dart';
import 'core/router/app_router.dart';
import 'core/services/ad_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/providers/settings_provider.dart';

class ReactMasterApp extends ConsumerStatefulWidget {
  const ReactMasterApp({this.initializeAds = true, super.key});

  /// Disabled in tests.
  final bool initializeAds;

  @override
  ConsumerState<ReactMasterApp> createState() => _ReactMasterAppState();
}

class _ReactMasterAppState extends ConsumerState<ReactMasterApp> {
  @override
  void initState() {
    super.initState();
    if (widget.initializeAds) {
      // Consent + ads SDK start after the first frame so the UI is never
      // blocked; failures are swallowed inside the service.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adsEnabledProvider.notifier).initialize();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      routerConfig: router,
      builder: (context, child) {
        // Honour the user's font scale, but cap extreme values so layouts
        // stay usable.
        final mq = MediaQuery.of(context);
        return MediaQuery(
          data: mq.copyWith(
            textScaler: mq.textScaler.clamp(maxScaleFactor: 1.8),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
