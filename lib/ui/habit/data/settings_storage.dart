import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSettings {
  const ProfileSettings({
    this.fullName = '',
    this.countryName,
    this.countryCode,
  });

  final String fullName;
  final String? countryName;
  final String? countryCode;

  Map<String, dynamic> toJson() => {
    'fullName': fullName,
    'countryName': countryName,
    'countryCode': countryCode,
  };

  factory ProfileSettings.fromJson(Map<String, dynamic> json) =>
      ProfileSettings(
        fullName: (json['fullName'] as String?) ?? '',
        countryName: json['countryName'] as String?,
        countryCode: json['countryCode'] as String?,
      );
}

enum RepeatRule {
  everyDay('Every day'),
  weekdays('Weekdays'),
  weekends('Weekends');

  const RepeatRule(this.label);
  final String label;
}

/// Reminder configuration for one user.
class NotificationSettings {
  const NotificationSettings({
    this.enabled = true,
    this.habitIds = const <String>{},
    this.hour = 7,
    this.minute = 30,
    this.repeat = RepeatRule.everyDay,
  });

  final bool enabled;
  final Set<String> habitIds;

  /// 24-hour clock.
  final int hour;
  final int minute;
  final RepeatRule repeat;

  NotificationSettings copyWith({
    bool? enabled,
    Set<String>? habitIds,
    int? hour,
    int? minute,
    RepeatRule? repeat,
  }) =>
      NotificationSettings(
        enabled: enabled ?? this.enabled,
        habitIds: habitIds ?? this.habitIds,
        hour: hour ?? this.hour,
        minute: minute ?? this.minute,
        repeat: repeat ?? this.repeat,
      );

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'habitIds': habitIds.toList(),
    'hour': hour,
    'minute': minute,
    'repeat': repeat.name,
  };

  factory NotificationSettings.fromJson(Map<String, dynamic> json) =>
      NotificationSettings(
        enabled: (json['enabled'] as bool?) ?? true,
        habitIds: ((json['habitIds'] as List?) ?? const [])
            .map((e) => e as String)
            .toSet(),
        hour: (json['hour'] as num?)?.toInt() ?? 7,
        minute: (json['minute'] as num?)?.toInt() ?? 30,
        repeat: RepeatRule.values.firstWhere(
              (r) => r.name == json['repeat'],
          orElse: () => RepeatRule.everyDay,
        ),
      );
}

/// "7:30 AM" style label.
String formatTime(int hour24, int minute) {
  final h12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
  final period = hour24 >= 12 ? 'PM' : 'AM';
  return '$h12:${minute.toString().padLeft(2, '0')} $period';
}

/// Local persistence for one user's profile and notification settings,
/// backed by `shared_preferences`.
class SettingsStorage {
  SettingsStorage(String username) : _user = username.trim().toLowerCase();

  final String _user;

  String get _profileKey => 'profile.$_user';
  String get _notificationsKey => 'notifications.$_user';

  Future<ProfileSettings> readProfile() async {
    final json = await _read(_profileKey);
    return json == null
        ? const ProfileSettings()
        : ProfileSettings.fromJson(json);
  }

  Future<void> writeProfile(ProfileSettings value) =>
      _write(_profileKey, value.toJson());

  Future<NotificationSettings> readNotifications() async {
    final json = await _read(_notificationsKey);
    return json == null
        ? const NotificationSettings()
        : NotificationSettings.fromJson(json);
  }

  Future<void> writeNotifications(NotificationSettings value) =>
      _write(_notificationsKey, value.toJson());

  Future<Map<String, dynamic>?> _read(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(key);
    if (raw == null || raw.isEmpty) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      // Corrupt data should never brick the app.
      return null;
    }
  }

  Future<void> _write(String key, Map<String, dynamic> json) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(key, jsonEncode(json));
  }
}