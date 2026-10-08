import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react_interview/core/router/app_router.dart';

import 'screens_test.dart' show pumpApp;

void main() {
  for (final route in [
    '/',
    '/learn',
    '/learn/react',
    '/learn/react/react_use_memo',
    '/interview',
    '/interview/easy',
    '/interview/react_easy_001',
    '/quiz',
    '/profile',
    '/settings',
    '/stats',
    '/achievements',
    '/bookmarks',
    '/challenge',
    '/search',
    '/about',
  ]) {
    testWidgets('no overflow at 1.6x text on $route (small phone)', (
      tester,
    ) async {
      tester.platformDispatcher.textScaleFactorTestValue = 1.6;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      final c = await pumpApp(tester);
      tester.view.physicalSize = const Size(720, 1440); // 360x720 dp
      tester.view.devicePixelRatio = 2;
      c.read(routerProvider).go(route);
      await tester.pumpAndSettle();
      // Scroll through the page to build all lazy items.
      final scrollables = find.byWidgetPredicate(
        (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
      );
      for (var i = 0; i < 12 && scrollables.evaluate().isNotEmpty; i++) {
        await tester.drag(scrollables.first, const Offset(0, -400));
        await tester.pumpAndSettle();
      }
      expect(tester.takeException(), isNull);
    });
  }
}
