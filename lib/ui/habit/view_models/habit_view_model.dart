import 'package:flutter/material.dart';
import '../data/habit.dart';
import '../data/habit_storage.dart';

class HabitViewModel extends ChangeNotifier {
  HabitViewModel({required String username})
      : _storage = HabitStorage(username);

  final HabitStorage _storage;

  List<Habit> _habits = [];
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;
  List<Habit> get habits => List.unmodifiable(_habits);

  int get doneToday {
    final now = DateTime.now();
    return _habits.where((h) => h.isDoneOn(now)).length;
  }

  Future<void> load() async {
    _habits = await _storage.read();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> add({
    required String name,
    required String iconKey,
    required Color color,
  }) async {
    _habits = [
      ..._habits,
      Habit(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        name: name.trim(),
        iconKey: iconKey,
        colorValue: color.toARGB32(),
      ),
    ];
    await _commit();
  }

  Future<void> update(
      String id, {
        required String name,
        required String iconKey,
        required Color color,
      }) async {
    _habits = [
      for (final h in _habits)
        if (h.id == id)
          h.copyWith(
            name: name.trim(),
            iconKey: iconKey,
            colorValue: color.toARGB32(),
          )
        else
          h,
    ];
    await _commit();
  }

  Future<void> delete(String id) async {
    _habits = _habits.where((h) => h.id != id).toList();
    await _commit();
  }

  /// Checks today off, or undoes it if it was already checked.
  Future<void> toggleToday(String id) async {
    final now = DateTime.now();
    final key = dateKey(now);
    _habits = [
      for (final h in _habits)
        if (h.id == id)
          h.copyWith(completions: _toggled(h.completions, key, now))
        else
          h,
    ];
    await _commit();
  }

  Map<String, int> _toggled(Map<String, int> source, String key, DateTime now) {
    final next = {...source};
    if (next.containsKey(key)) {
      next.remove(key);
    } else {
      next[key] = now.millisecondsSinceEpoch;
    }
    return next;
  }

  Future<void> _commit() async {
    notifyListeners(); // refresh the UI first, then save
    await _storage.write(_habits);
  }
}