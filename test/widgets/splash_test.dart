import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react_interview/app.dart';
import 'package:react_interview/core/constants/app_constants.dart';
import 'package:react_interview/core/theme/app_colors.dart';
import 'package:react_interview/core/theme/app_theme.dart';
import 'package:react_interview/features/splash/studio_splash.dart';

import '../helpers/test_helpers.dart';

class _Scenario {
  const _Scenario({
    required this.name,
    required this.size,
    required this.themeMode,
    this.textScale = 1,
  });

  final String name;
  final Size size;
  final ThemeMode themeMode;
  final double textScale;
}

const _scenarios = [
  _Scenario(
    name: 'small phone, large text, light',
    size: Size(320, 568),
    themeMode: ThemeMode.light,
    textScale: 1.8,
  ),
  _Scenario(
    name: 'phone, light',
    size: Size(390, 844),
    themeMode: ThemeMode.light,
  ),
  _Scenario(
    name: 'phone, dark',
    size: Size(390, 844),
    themeMode: ThemeMode.dark,
  ),
  _Scenario(
    name: 'phone landscape, large text',
    size: Size(844, 390),
    themeMode: ThemeMode.light,
    textScale: 1.6,
  ),
  _Scenario(
    name: 'tablet, light',
    size: Size(834, 1194),
    themeMode: ThemeMode.light,
  ),
  _Scenario(
    name: 'tablet, dark',
    size: Size(1024, 1366),
    themeMode: ThemeMode.dark,
    textScale: 1.3,
  ),
];

Future<void> _pumpSplash(WidgetTester tester, _Scenario scenario) async {
  tester.view.physicalSize = scenario.size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = scenario.textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

  tester.platformDispatcher.platformBrightnessTestValue =
      scenario.themeMode == ThemeMode.dark ? Brightness.dark : Brightness.light;
  addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);

  await tester.pumpWidget(
    MaterialApp(
      key: ValueKey(scenario.name),
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: scenario.themeMode,
      debugShowCheckedModeBanner: false,
      home: const StudioSplashScreen(),
    ),
  );
  await tester.pump();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final scenario in _scenarios) {
    testWidgets('splash fits and shows the byline on ${scenario.name}', (
      tester,
    ) async {
      await _pumpSplash(tester, scenario);

      expect(find.text(AppConstants.appName), findsOneWidget);
      expect(find.text(AppConstants.tagline), findsOneWidget);
      expect(find.text(StudioSplashScreen.byWord), findsOneWidget);
      expect(find.text(StudioSplashScreen.studioName), findsOneWidget);
      expect(find.byKey(StudioSplashScreen.brandIconKey), findsOneWidget);
      expect(find.byKey(StudioSplashScreen.logoKey), findsOneWidget);

      final icon = tester.widget<Image>(
        find.byKey(StudioSplashScreen.brandIconKey),
      );
      expect(
        (icon.image as AssetImage).assetName,
        StudioSplashScreen.brandIconAsset,
      );
      final logo = tester.widget<Image>(find.byKey(StudioSplashScreen.logoKey));
      expect(
        (logo.image as AssetImage).assetName,
        StudioSplashScreen.logoAsset,
      );

      final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
      expect(
        scaffold.backgroundColor,
        scenario.themeMode == ThemeMode.dark
            ? AppColors.darkBackground
            : AppColors.lightBackground,
      );

      final screen = tester.view.physicalSize / tester.view.devicePixelRatio;
      for (final key in [
        StudioSplashScreen.logoKey,
        StudioSplashScreen.brandIconKey,
      ]) {
        final rect = tester.getRect(find.byKey(key));
        expect(
          (rect.center.dx - screen.width / 2).abs(),
          lessThan(2),
          reason: '${scenario.name} $key at $rect on $screen',
        );
      }
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('app shows the splash, then the home screen', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.6;
    addTearDown(tester.view.reset);

    final container = createContainer();
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ReactMasterApp(initializeAds: false),
      ),
    );
    await tester.pump();

    expect(find.byType(StudioSplashScreen), findsOneWidget);
    expect(find.text(AppConstants.appName), findsOneWidget);
    expect(find.text(StudioSplashScreen.byWord), findsOneWidget);
    expect(find.text(StudioSplashScreen.studioName), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pump(StudioSplashGate.duration);
    await tester.pumpAndSettle();

    expect(find.byType(StudioSplashScreen), findsNothing);
    expect(find.text('Good morning,'), findsOneWidget);
    expect(find.text(AppConstants.tagline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'splash stays readable when the app caps text scale on a small phone',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2.4;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final container = createContainer();
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const ReactMasterApp(initializeAds: false),
        ),
      );
      await tester.pump();

      expect(find.text(StudioSplashScreen.studioName), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.pump(StudioSplashGate.duration);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    },
  );
}
