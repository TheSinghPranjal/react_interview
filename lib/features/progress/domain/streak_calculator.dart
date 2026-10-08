import 'dart:math';

import 'package:flutter/foundation.dart';

import '../../../core/utils/date_utils.dart';
import '../../../data/models/user_progress.dart';

@immutable
class StreakDay {
  const StreakDay({
    required this.date,
    required this.label,
    required this.isActive,
    required this.isToday,
    required this.isFuture,
  });

  final DateTime date;
  final String label;
  final bool isActive;
  final bool isToday;
  final bool isFuture;
}

/// Pure streak rules.
///
/// * Activity on the same day as `lastActiveDate` changes nothing.
/// * Activity on the day after `lastActiveDate` extends the streak.
/// * Any longer gap starts a new streak at 1.
abstract final class StreakCalculator {
  static StreakState registerActivity(StreakState state, DateTime now) {
    final todayKey = AppDates.dayKey(now);
    if (state.lastActiveDate == todayKey) return state;

    final last = AppDates.parseDayKey(state.lastActiveDate);
    final gap = last == null ? null : AppDates.daysBetween(last, now);

    // Clock moved backwards (e.g. manual time change): don't punish the user.
    if (gap != null && gap < 0) return state;

    final current = gap == 1 ? state.currentStreak + 1 : 1;
    final days = [...state.activeDays, todayKey];
    final trimmed = days.length > StreakState.maxActiveDays
        ? days.sublist(days.length - StreakState.maxActiveDays)
        : days;

    return StreakState(
      currentStreak: current,
      longestStreak: max(state.longestStreak, current),
      lastActiveDate: todayKey,
      activeDays: trimmed,
    );
  }

  /// The streak as it should be displayed today: a streak whose last activity
  /// was before yesterday has been broken and shows as 0.
  static int effectiveStreak(StreakState state, DateTime now) {
    final last = AppDates.parseDayKey(state.lastActiveDate);
    if (last == null) return 0;
    final gap = AppDates.daysBetween(last, now);
    return gap <= 1 ? state.currentStreak : 0;
  }

  static bool isActiveToday(StreakState state, DateTime now) =>
      state.lastActiveDate == AppDates.dayKey(now);

  /// Monday–Sunday view of the current week.
  static List<StreakDay> currentWeek(StreakState state, DateTime now) {
    final active = state.activeDays.toSet();
    final monday = AppDates.startOfWeek(now);
    final today = AppDates.startOfDay(now);
    return [
      for (var i = 0; i < 7; i++)
        () {
          final d = DateTime(monday.year, monday.month, monday.day + i);
          return StreakDay(
            date: d,
            label: AppDates.weekdayShort[i],
            isActive: active.contains(AppDates.dayKey(d)),
            isToday: d == today,
            isFuture: d.isAfter(today),
          );
        }(),
    ];
  }
}
