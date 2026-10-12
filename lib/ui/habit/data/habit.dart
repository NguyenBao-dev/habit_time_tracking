import 'package:flutter/material.dart';

class HabitIcons {
  HabitIcons._();

  static const String defaultKey = 'star';

  static const Map<String, IconData> all = {
    'star': Icons.star_border_rounded,
    'moon': Icons.nightlight_outlined,
    'drop': Icons.water_drop_outlined,
    'book': Icons.menu_book_outlined,
    'pulse': Icons.monitor_heart_outlined,
    'wind': Icons.air_rounded,
  };

  static IconData resolve(String key) =>
      all[key] ?? Icons.star_border_rounded;
}

/// `yyyy-MM-dd` key used to record completions per calendar day.
String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')}';

/// A daily habit. [completions] maps a [dateKey] to the epoch-millisecond
/// time it was checked off.
@immutable
class Habit {
  const Habit({
    required this.id,
    required this.name,
    required this.iconKey,
    required this.colorValue,
    this.completions = const {},
  });

  final String id;
  final String name;
  final String iconKey;
  final int colorValue;
  final Map<String, int> completions;

  Color get color => Color(colorValue);
  IconData get icon => HabitIcons.resolve(iconKey);

  bool isDoneOn(DateTime day) => completions.containsKey(dateKey(day));

  Habit copyWith({
    String? name,
    String? iconKey,
    int? colorValue,
    Map<String, int>? completions,
  }) =>
      Habit(
        id: id,
        name: name ?? this.name,
        iconKey: iconKey ?? this.iconKey,
        colorValue: colorValue ?? this.colorValue,
        completions: completions ?? this.completions,
      );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'iconKey': iconKey,
    'colorValue': colorValue,
    'completions': completions,
  };

  factory Habit.fromJson(Map<String, dynamic> json) => Habit(
    id: json['id'] as String,
    name: json['name'] as String,
    iconKey: (json['iconKey'] as String?) ?? HabitIcons.defaultKey,
    colorValue: (json['colorValue'] as num).toInt(),
    completions: ((json['completions'] as Map?) ?? const {}).map(
          (k, v) => MapEntry(k as String, (v as num).toInt()),
    ),
  );
}