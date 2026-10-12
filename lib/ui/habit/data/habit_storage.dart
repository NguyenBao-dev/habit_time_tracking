import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'habit.dart';

class HabitStorage {
  HabitStorage(String username)
      : _key = 'habits.${username.trim().toLowerCase()}';

  final String _key;

  Future<List<Habit>> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_key);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => Habit.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      // Corrupt data should never brick the app.
      return [];
    }
  }

  Future<void> write(List<Habit> habits) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _key,
      jsonEncode(habits.map((h) => h.toJson()).toList()),
    );
  }
}