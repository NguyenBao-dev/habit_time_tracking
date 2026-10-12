import 'package:flutter/foundation.dart';
import '../data/settings_storage.dart';

class NotificationViewModel extends ChangeNotifier {
  NotificationViewModel({required String username})
      : _storage = SettingsStorage(username);

  final SettingsStorage _storage;

  NotificationSettings _settings = const NotificationSettings();
  bool _isLoaded = false;

  NotificationSettings get settings => _settings;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _settings = await _storage.readNotifications();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> save(NotificationSettings value) async {
    _settings = value;
    notifyListeners();
    await _storage.writeNotifications(value);
  }
}