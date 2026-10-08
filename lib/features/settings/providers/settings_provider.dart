import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../../../data/models/app_settings.dart';
import '../../../data/repositories/repository_providers.dart';

class SettingsNotifier extends Notifier<AppSettings> {
  @override
  AppSettings build() => ref.read(settingsRepositoryProvider).load();

  void setThemeMode(ThemeMode mode) => _update(state.copyWith(themeMode: mode));

  void setUserName(String name) {
    final trimmed = name.trim();
    _update(
      state.copyWith(
        userName: trimmed.isEmpty
            ? AppConstants.defaultUserName
            : trimmed.length > 30
            ? trimmed.substring(0, 30)
            : trimmed,
      ),
    );
  }

  void setDailyReminder(bool enabled) =>
      _update(state.copyWith(dailyReminder: enabled));

  void setLastQuizCount(int count) =>
      _update(state.copyWith(lastQuizConfigCount: count));

  void _update(AppSettings next) {
    state = next;
    ref.read(settingsRepositoryProvider).save(next).ignore();
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(
  SettingsNotifier.new,
);

final themeModeProvider = Provider<ThemeMode>(
  (ref) => ref.watch(settingsProvider.select((s) => s.themeMode)),
);
