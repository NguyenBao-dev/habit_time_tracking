import 'dart:math' as math;
import 'habit.dart';

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

/// Monday of the week containing [now], shifted by [offset] weeks.
DateTime weekStart(DateTime now, int offset) {
  final t = _day(now);
  return DateTime(t.year, t.month, t.day - (t.weekday - 1) + offset * 7);
}

int _completedOn(List<Habit> habits, DateTime day) =>
    habits.where((h) => h.isDoneOn(day)).length;

List<int> _dailyCounts(List<Habit> habits, DateTime start) => List.generate(
  7,
      (i) => _completedOn(
      habits, DateTime(start.year, start.month, start.day + i)),
);

/// Completion numbers for one Monday–Sunday week.
class WeekStats {
  const WeekStats({
    required this.start,
    required this.daily,
    required this.goal,
    required this.elapsedDays,
    required this.previousPercent,
  });

  /// Monday of the week.
  final DateTime start;

  /// Habits completed on each day, Monday first.
  final List<int> daily;

  /// Daily goal: complete every habit.
  final int goal;

  /// Days counted towards the percentage (up to today for the current week).
  final int elapsedDays;

  /// Previous week's percentage over the same number of days.
  final int previousPercent;

  int get completed => daily.take(elapsedDays).fold(0, (a, b) => a + b);
  int get possible => goal * elapsedDays;
  int get percent =>
      possible == 0 ? 0 : (completed * 100 / possible).round();
  int get delta => percent - previousPercent;

  factory WeekStats.compute(
      List<Habit> habits, {
        int weekOffset = 0,
        DateTime? now,
      }) {
    final today = _day(now ?? DateTime.now());
    final start = weekStart(today, weekOffset);
    final elapsed = weekOffset == 0 ? today.weekday : 7;
    final goal = habits.length;

    final prevDaily = _dailyCounts(habits, weekStart(today, weekOffset - 1));
    final prevCompleted = prevDaily.take(elapsed).fold(0, (a, b) => a + b);
    final prevPossible = goal * elapsed;

    return WeekStats(
      start: start,
      daily: _dailyCounts(habits, start),
      goal: goal,
      elapsedDays: elapsed,
      previousPercent: prevPossible == 0
          ? 0
          : (prevCompleted * 100 / prevPossible).round(),
    );
  }
}

/// Text for the "Best week this month" banner.
String recordMessage(List<Habit> habits, {DateTime? now}) {
  if (habits.isEmpty) return 'Add a habit to start tracking your weeks.';

  final today = _day(now ?? DateTime.now());
  int total(int offset) => _dailyCounts(habits, weekStart(today, offset))
      .fold(0, (a, b) => a + b);

  final thisWeek = total(0);
  final best = math.max(total(-1), math.max(total(-2), total(-3)));

  if (best == 0 && thisWeek == 0) {
    return 'Check off a habit to get your week going.';
  }
  if (thisWeek > best) return "You're on a record week. Keep it up!";
  final remaining = best - thisWeek + 1;
  return "You're $remaining completion${remaining == 1 ? '' : 's'} "
      'away from a new record.';
}

/// A single "habit checked off" event.
class HabitActivity {
  const HabitActivity(this.habit, this.time);
  final Habit habit;
  final DateTime time;
}

/// Completions across all habits, newest first.
List<HabitActivity> recentActivity(List<Habit> habits, {int? limit}) {
  final items = <HabitActivity>[
    for (final h in habits)
      for (final ms in h.completions.values)
        HabitActivity(h, DateTime.fromMillisecondsSinceEpoch(ms)),
  ]..sort((a, b) => b.time.compareTo(a.time));
  return limit == null ? items : items.take(limit).toList();
}

String timeAgo(DateTime time, {DateTime? now}) {
  final diff = (now ?? DateTime.now()).difference(time);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  if (diff.inHours < 24) {
    final h = diff.inHours;
    return '$h hour${h == 1 ? '' : 's'} ago';
  }
  final d = diff.inDays;
  return d == 1 ? 'Yesterday' : '$d days ago';
}