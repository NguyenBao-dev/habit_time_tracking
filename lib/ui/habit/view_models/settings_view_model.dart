import 'package:flutter/foundation.dart';
import '../data/settings_storage.dart';

class SettingsViewModel extends ChangeNotifier {
  SettingsViewModel({required String username})
      : _storage = SettingsStorage(username);

  final SettingsStorage _storage;

  ProfileSettings _profile = const ProfileSettings();
  bool _isLoaded = false;

  ProfileSettings get profile => _profile;
  bool get isLoaded => _isLoaded;

  Future<void> load() async {
    _profile = await _storage.readProfile();
    _isLoaded = true;
    notifyListeners();
  }

  Future<void> save(ProfileSettings value) async {
    _profile = value;
    notifyListeners();
    await _storage.writeProfile(value);
  }
}