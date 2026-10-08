import 'package:flutter/material.dart';

import '../../core/constants/app_constants.dart';
import 'json_utils.dart';

@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.userName = AppConstants.defaultUserName,
    this.dailyReminder = false,
    this.lastQuizConfigCount = QuizDefaults.defaultQuestionCount,
  });

  final ThemeMode themeMode;
  final String userName;
  final bool dailyReminder;
  final int lastQuizConfigCount;

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? userName,
    bool? dailyReminder,
    int? lastQuizConfigCount,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    userName: userName ?? this.userName,
    dailyReminder: dailyReminder ?? this.dailyReminder,
    lastQuizConfigCount: lastQuizConfigCount ?? this.lastQuizConfigCount,
  );

  factory AppSettings.fromJson(JsonMap json) => AppSettings(
    themeMode:
        ThemeMode.values
            .where((m) => m.name == json.optString('themeMode'))
            .firstOrNull ??
        ThemeMode.system,
    userName: json.optString('userName', AppConstants.defaultUserName),
    dailyReminder: json.optBool('dailyReminder'),
    lastQuizConfigCount: json.optInt(
      'lastQuizConfigCount',
      QuizDefaults.defaultQuestionCount,
    ),
  );

  JsonMap toJson() => {
    'themeMode': themeMode.name,
    'userName': userName,
    'dailyReminder': dailyReminder,
    'lastQuizConfigCount': lastQuizConfigCount,
  };
}
