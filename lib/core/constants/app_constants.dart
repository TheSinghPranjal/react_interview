/// Central app-wide constants. Change [appName] here to rebrand the app.
abstract final class AppConstants {
  static const String appName = 'ReactMaster';
  static const String tagline = 'Learn React & Next.js';
  static const String subtitle =
      'Master modern web development one concept at a time.';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@example.com';
  static const String defaultUserName = 'Developer';

  /// Asset paths for bundled, offline-first content.
  static const String reactLessonsAsset = 'assets/data/react_lessons.json';
  static const String nextLessonsAsset = 'assets/data/next_lessons.json';
  static const String interviewQuestionsAsset =
      'assets/data/interview_questions.json';
  static const String mcqQuestionsAsset = 'assets/data/mcq_questions.json';
}

/// XP values for every rewarded activity.
abstract final class XpRewards {
  static const int lessonCompleted = 20;
  static const int interviewQuestionCompleted = 10;
  static const int correctMcq = 10;
  static const int perfectQuizBonus = 50;
  static const int dailyChallenge = 30;
  static const int rewardedAd = 20;

  /// Rewarded-ad XP can be claimed at most this many times per day.
  static const int maxRewardedClaimsPerDay = 3;
}

/// Quiz configuration constants.
abstract final class QuizDefaults {
  static const int defaultQuestionCount = 10;
  static const List<int> questionCountOptions = [5, 10, 20, 30, 50];
  static const int optionsPerQuestion = 4;
}
