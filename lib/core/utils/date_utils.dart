/// Date helpers that work on local calendar days, independent of time.
abstract final class AppDates {
  /// `yyyy-MM-dd` key for a calendar day in local time.
  static String dayKey(DateTime date) {
    final d = date.toLocal();
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static DateTime? parseDayKey(String? key) {
    if (key == null) return null;
    final parts = key.split('-');
    if (parts.length != 3) return null;
    final y = int.tryParse(parts[0]);
    final m = int.tryParse(parts[1]);
    final d = int.tryParse(parts[2]);
    if (y == null || m == null || d == null) return null;
    return DateTime(y, m, d);
  }

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  /// Whole calendar days from [from] to [to] (DST-safe).
  static int daysBetween(DateTime from, DateTime to) {
    final a = DateTime.utc(from.year, from.month, from.day);
    final b = DateTime.utc(to.year, to.month, to.day);
    return b.difference(a).inDays;
  }

  /// Monday of the week containing [date].
  static DateTime startOfWeek(DateTime date) {
    final d = startOfDay(date);
    return DateTime(d.year, d.month, d.day - (d.weekday - DateTime.monday));
  }

  /// Stable day number since 2024-01-01, used for deterministic selection.
  static int dayNumber(DateTime date) =>
      daysBetween(DateTime(2024, 1, 1), date);

  static const List<String> weekdayShort = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static String relative(DateTime date, DateTime now) {
    final days = daysBetween(date, now);
    if (days <= 0) return 'Today';
    if (days == 1) return 'Yesterday';
    if (days < 7) return '$days days ago';
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '${date.year}-$m-$d';
  }
}
