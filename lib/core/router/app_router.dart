import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/enums.dart';
import '../../features/achievements/presentation/achievements_screen.dart';
import '../../features/bookmarks/presentation/bookmarks_screen.dart';
import '../../features/daily_challenge/daily_challenge_screen.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/interview/presentation/interview_home_screen.dart';
import '../../features/interview/presentation/interview_list_screen.dart';
import '../../features/interview/presentation/interview_question_screen.dart';
import '../../features/learn/presentation/learn_screen.dart';
import '../../features/learn/presentation/lesson_screen.dart';
import '../../features/learn/presentation/track_screen.dart';
import '../../features/profile/presentation/info_screens.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/stats_screen.dart';
import '../../features/quiz/presentation/quiz_home_screen.dart';
import '../../features/quiz/presentation/quiz_result_screen.dart';
import '../../features/quiz/presentation/quiz_review_screen.dart';
import '../../features/quiz/presentation/quiz_session_screen.dart';
import '../../features/quiz/providers/quiz_providers.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import 'scaffold_with_nav.dart';

/// Route paths in one place.
abstract final class AppRoutes {
  static const home = '/';
  static const learn = '/learn';
  static String track(Track t) => '/learn/${t.slug}';
  static String lesson(Track t, String id) => '/learn/${t.slug}/$id';
  static const interview = '/interview';
  static String interviewLevel(Difficulty d) => '/interview/${d.slug}';
  static String interviewQuestion(String id) => '/interview/$id';
  static const quiz = '/quiz';
  static const quizSession = '/quiz/session';
  static const quizResult = '/quiz/result';
  static const quizReview = '/quiz/review';
  static const profile = '/profile';
  static const bookmarks = '/bookmarks';
  static const settings = '/settings';
  static const search = '/search';
  static const achievements = '/achievements';
  static const stats = '/stats';
  static const challenge = '/challenge';
  static const about = '/about';
  static const privacy = '/privacy';
  static const terms = '/terms';
}

final rootNavigatorKey = GlobalKey<NavigatorState>(debugLabel: 'root');

final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: AppRoutes.home,
    debugLogDiagnostics: false,
    errorBuilder: (context, state) => NotFoundScreen(path: state.uri.path),
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => ScaffoldWithNav(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.learn,
                builder: (context, state) => const LearnScreen(),
                routes: [
                  GoRoute(
                    path: ':track',
                    redirect: (context, state) =>
                        Track.fromSlug(state.pathParameters['track']) == null
                        ? AppRoutes.learn
                        : null,
                    builder: (context, state) => TrackScreen(
                      track: Track.fromSlug(state.pathParameters['track'])!,
                    ),
                    routes: [
                      GoRoute(
                        path: ':lessonId',
                        parentNavigatorKey: rootNavigatorKey,
                        builder: (context, state) => LessonScreen(
                          lessonId: state.pathParameters['lessonId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.interview,
                builder: (context, state) => const InterviewHomeScreen(),
                routes: [
                  for (final d in Difficulty.values)
                    GoRoute(
                      path: d.slug,
                      builder: (context, state) =>
                          InterviewListScreen(difficulty: d),
                    ),
                  GoRoute(
                    path: ':questionId',
                    parentNavigatorKey: rootNavigatorKey,
                    builder: (context, state) => InterviewQuestionScreen(
                      questionId: state.pathParameters['questionId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.quiz,
                builder: (context, state) => const QuizHomeScreen(),
                routes: [
                  GoRoute(
                    path: 'session',
                    parentNavigatorKey: rootNavigatorKey,
                    redirect: (context, state) =>
                        ref.read(quizSessionProvider) == null
                        ? AppRoutes.quiz
                        : null,
                    builder: (context, state) => const QuizSessionScreen(),
                  ),
                  GoRoute(
                    path: 'result',
                    parentNavigatorKey: rootNavigatorKey,
                    redirect: (context, state) =>
                        ref.read(quizResultProvider) == null
                        ? AppRoutes.quiz
                        : null,
                    builder: (context, state) => const QuizResultScreen(),
                  ),
                  GoRoute(
                    path: 'review',
                    parentNavigatorKey: rootNavigatorKey,
                    redirect: (context, state) =>
                        ref.read(quizResultProvider) == null
                        ? AppRoutes.quiz
                        : null,
                    builder: (context, state) => const QuizReviewScreen(),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.profile,
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.bookmarks,
        builder: (context, state) => const BookmarksScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.search,
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: AppRoutes.achievements,
        builder: (context, state) => const AchievementsScreen(),
      ),
      GoRoute(
        path: AppRoutes.stats,
        builder: (context, state) => const StatsScreen(),
      ),
      GoRoute(
        path: AppRoutes.challenge,
        builder: (context, state) => const DailyChallengeScreen(),
      ),
      GoRoute(
        path: AppRoutes.about,
        builder: (context, state) => const AboutScreen(),
      ),
      GoRoute(
        path: AppRoutes.privacy,
        builder: (context, state) => const PrivacyPolicyScreen(),
      ),
      GoRoute(
        path: AppRoutes.terms,
        builder: (context, state) => const TermsScreen(),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
