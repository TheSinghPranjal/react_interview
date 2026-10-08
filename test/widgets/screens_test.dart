import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:react_interview/app.dart';
import 'package:react_interview/core/router/app_router.dart';
import 'package:react_interview/data/models/quiz_session.dart';
import 'package:react_interview/features/progress/providers/progress_provider.dart';
import 'package:react_interview/features/quiz/providers/quiz_providers.dart';

import '../helpers/test_helpers.dart';

Future<ProviderContainer> pumpApp(
  WidgetTester tester, {
  String? location,
}) async {
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
  await tester.pumpAndSettle();
  if (location != null) {
    container.read(routerProvider).push<void>(location).ignore();
    await tester.pumpAndSettle();
  }
  return container;
}

final _vertical = find
    .byWidgetPredicate(
      (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
    )
    .first;

Future<void> scrollTo(WidgetTester tester, Finder target) async {
  for (var i = 0; i < 30 && target.evaluate().isEmpty; i++) {
    await tester.drag(_vertical, const Offset(0, -300));
    await tester.pumpAndSettle();
  }
  expect(target, findsWidgets);
}

void main() {
  testWidgets('Home shows dashboard sections and navigates tabs', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text('Learn React & Next.js'), findsOneWidget);
    expect(
      find.text('Master modern web development one concept at a time.'),
      findsOneWidget,
    );
    expect(find.text('Continue learning'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    await scrollTo(tester, find.text('Master modern React'));
    expect(find.text('Master modern React'), findsOneWidget);

    await scrollTo(tester, find.text('Daily challenge'));
    expect(find.text('Daily challenge'), findsOneWidget);

    await tester.tap(find.text('Quiz').last);
    await tester.pumpAndSettle();
    expect(find.text('Build your quiz'), findsOneWidget);

    await tester.tap(find.text('Interview').last);
    await tester.pumpAndSettle();
    expect(find.text('Prepare for your next React interview'), findsOneWidget);
  });

  testWidgets('Lesson screen renders content and marks complete', (
    tester,
  ) async {
    final c = await pumpApp(tester, location: '/learn/react/react_use_memo');

    expect(find.text('useMemo'), findsWidgets);
    expect(find.text('Key concepts'), findsOneWidget);
    expect(find.text('What is it?'), findsOneWidget);
    expect(find.text('Copy code').hitTestable(), findsNothing); // tooltip only
    expect(find.byTooltip('Copy code'), findsWidgets);

    final complete = find.textContaining('Mark as complete');
    await scrollTo(tester, complete);
    await tester.ensureVisible(complete);
    await tester.pumpAndSettle();
    await tester.tap(complete);
    await tester.pumpAndSettle();

    expect(
      c.read(progressProvider).isLessonCompleted('react_use_memo'),
      isTrue,
    );
    expect(find.text('Lesson completed'), findsOneWidget);
    expect(c.read(progressProvider).totalXp, 20);
  });

  testWidgets('Unknown lesson shows a not found state', (tester) async {
    await pumpApp(tester, location: '/learn/react/does_not_exist');
    expect(find.text('Lesson not found'), findsOneWidget);
  });

  testWidgets('Quiz session: answer locks, feedback shows, results appear', (
    tester,
  ) async {
    final c = await pumpApp(tester);
    await c
        .read(quizSessionProvider.notifier)
        .start(const QuizConfig(questionCount: 2));
    c.read(routerProvider).push<void>(AppRoutes.quizSession).ignore();
    await tester.pumpAndSettle();

    expect(find.text('Question 1 / 2'), findsOneWidget);

    for (var i = 0; i < 2; i++) {
      final s = c.read(quizSessionProvider)!;
      final correctText = s.current.options[s.current.correctIndex];
      await tester.tap(find.text(correctText));
      await tester.pumpAndSettle();
      expect(find.text('Correct!'), findsOneWidget);

      // Tapping another option after submission must not change the answer.
      final other = s.current.options[(s.current.correctIndex + 1) % 4];
      await tester.tap(find.text(other), warnIfMissed: false);
      await tester.pumpAndSettle();
      expect(
        c.read(quizSessionProvider)!.currentAnswer,
        s.current.correctIndex,
      );

      await tester.tap(find.text(i == 0 ? 'Next Question' : 'See Results'));
      await tester.pumpAndSettle();
    }

    expect(find.text('Perfect score!'), findsOneWidget);
    expect(find.text('Review Answers'), findsOneWidget);
    expect(find.text('Retry Quiz'), findsOneWidget);
    expect(c.read(quizStatsProvider).totalQuizzes, 1);
  });

  testWidgets('Interview question reveals answer and records progress', (
    tester,
  ) async {
    final c = await pumpApp(tester, location: '/interview/react_easy_001');

    expect(find.text('What is JSX?'), findsOneWidget);
    expect(find.text('Think about your answer'), findsOneWidget);
    expect(find.text('Short answer'), findsNothing);

    await tester.tap(find.text('Show Answer'));
    await tester.pumpAndSettle();
    expect(find.text('Short answer'), findsOneWidget);
    expect(find.text('Key points'), findsOneWidget);

    await tester.tap(find.text('I Know This'));
    await tester.pumpAndSettle();
    expect(c.read(progressProvider).interviewKnown, contains('react_easy_001'));
    // Advances to the next easy question in the session.
    expect(find.text('What are keys?'), findsOneWidget);
  });

  testWidgets('Dark mode renders the home screen', (tester) async {
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await pumpApp(tester);
    final context = tester.element(find.text('Learn React & Next.js'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
