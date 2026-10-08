import '../../../core/utils/levels.dart';
import '../../../data/models/achievement.dart';
import '../../../data/models/user_progress.dart';

/// All achievements in the app.
abstract final class AchievementCatalog {
  static final List<Achievement> all = [
    Achievement(
      id: 'first_lesson',
      title: 'First Lesson',
      description: 'Complete your first lesson.',
      iconKey: 'lesson',
      target: 1,
      metric: (p) => p.lessonsCompleted,
    ),
    Achievement(
      id: 'first_quiz',
      title: 'First Quiz',
      description: 'Finish your first quiz.',
      iconKey: 'quiz',
      target: 1,
      metric: (p) => p.quizStats.totalQuizzes,
    ),
    Achievement(
      id: 'correct_10',
      title: '10 Correct Answers',
      description: 'Answer 10 quiz questions correctly.',
      iconKey: 'check',
      target: 10,
      metric: (p) => p.quizStats.correctAnswers,
    ),
    Achievement(
      id: 'correct_50',
      title: '50 Correct Answers',
      description: 'Answer 50 quiz questions correctly.',
      iconKey: 'check',
      target: 50,
      metric: (p) => p.quizStats.correctAnswers,
    ),
    Achievement(
      id: 'correct_100',
      title: '100 Correct Answers',
      description: 'Answer 100 quiz questions correctly.',
      iconKey: 'trophy',
      target: 100,
      metric: (p) => p.quizStats.correctAnswers,
    ),
    Achievement(
      id: 'perfect_quiz',
      title: 'Perfect Quiz',
      description: 'Score 100% on a quiz.',
      iconKey: 'star',
      target: 1,
      metric: (p) => p.quizStats.perfectQuizzes,
    ),
    Achievement(
      id: 'streak_7',
      title: '7 Day Streak',
      description: 'Learn something 7 days in a row.',
      iconKey: 'fire',
      target: 7,
      metric: (p) => p.streak.longestStreak,
    ),
    Achievement(
      id: 'streak_30',
      title: '30 Day Streak',
      description: 'Learn something 30 days in a row.',
      iconKey: 'fire',
      target: 30,
      metric: (p) => p.streak.longestStreak,
    ),
    Achievement(
      id: 'lessons_10',
      title: '10 Lessons Completed',
      description: 'Complete 10 lessons.',
      iconKey: 'book',
      target: 10,
      metric: (p) => p.lessonsCompleted,
    ),
    Achievement(
      id: 'lessons_50',
      title: '50 Lessons Completed',
      description: 'Complete 50 lessons.',
      iconKey: 'school',
      target: 50,
      metric: (p) => p.lessonsCompleted,
    ),
    Achievement(
      id: 'interview_25',
      title: '25 Interview Questions',
      description: 'Review 25 interview questions.',
      iconKey: 'interview',
      target: 25,
      metric: (p) => p.interviewCompleted,
    ),
    Achievement(
      id: 'interview_100',
      title: '100 Interview Questions',
      description: 'Review 100 interview questions.',
      iconKey: 'badge',
      target: 100,
      metric: (p) => p.interviewCompleted,
    ),
    Achievement(
      id: 'daily_7',
      title: 'Daily Habit',
      description: 'Complete 7 daily challenges.',
      iconKey: 'calendar',
      target: 7,
      metric: (p) => p.dailyChallengeDays.length,
    ),
    Achievement(
      id: 'level_5',
      title: 'Level 5',
      description: 'Reach level 5.',
      iconKey: 'level',
      target: 5,
      metric: (p) => LevelSystem.fromXp(p.totalXp).level,
    ),
  ];

  /// Achievements that are met by [progress] but not yet recorded.
  static List<Achievement> newlyUnlocked(UserProgress progress) => [
    for (final a in all)
      if (!progress.achievements.containsKey(a.id) && a.isMet(progress)) a,
  ];

  static List<AchievementStatus> statuses(UserProgress progress) => [
    for (final a in all)
      AchievementStatus(
        achievement: a,
        current: a.metric(progress),
        unlockedAt: switch (progress.achievements[a.id]) {
          final iso? => DateTime.tryParse(iso),
          null => null,
        },
      ),
  ];
}
