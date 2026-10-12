import 'package:flutter/foundation.dart';
import 'auth_storage.dart';

class AuthValidators {
  AuthValidators._();

  static final RegExp _usernamePattern = RegExp(r'^[A-Za-z0-9_.]+$');
  static final RegExp _emailPattern =
  RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? value, String label) =>
      (value == null || value.trim().isEmpty) ? 'Please enter your $label' : null;

  static String? username(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter a username';
    if (v.length < 3) return 'Username must be at least 3 characters';
    if (!_usernamePattern.hasMatch(v)) {
      return 'Use letters, numbers, "." or "_" only';
    }
    return null;
  }

  static String? email(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email';
    if (!_emailPattern.hasMatch(v)) return 'Enter a valid email address';
    return null;
  }

  static String? newPassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter a password';
    if (v.length < 6) return 'Password must be at least 6 characters';
    return null;
  }
}

/// Holds auth state and talks to local storage.
///
/// [login] and [register] return `null` on success, or a user-facing error
/// message on failure.
class AuthViewModel extends ChangeNotifier {
  AuthViewModel({AuthStorage? storage}) : _storage = storage ?? AuthStorage();

  final AuthStorage _storage;

  bool _isInitialized = false;
  bool _isBusy = false;
  String? _currentUser;
  String? _currentEmail;

  /// True once the saved session (if any) has been restored.
  bool get isInitialized => _isInitialized;
  bool get isBusy => _isBusy;
  bool get isAuthenticated => _currentUser != null;
  String? get currentUser => _currentUser;
  String? get currentEmail => _currentEmail;

  /// Restores a previously saved session. Call once at app start.
  Future<void> initialize() async {
    final saved = await _storage.readSession();
    if (saved != null) {
      final user = await _storage.findUser(saved);
      _currentUser = user?.username;
      _currentEmail = user?.email;
      if (user == null) await _storage.writeSession(null);
    }
    _isInitialized = true;
    notifyListeners();
  }

  Future<String?> login({
    required String username,
    required String password,
  }) async {
    _setBusy(true);
    try {
      final user = await _storage.findUser(username);
      final ok = user != null &&
          AuthStorage.hashPassword(password, user.salt) == user.passwordHash;
      if (!ok) return 'Incorrect username or password.';

      await _storage.writeSession(user.username);
      _currentUser = user.username;
      _currentEmail = user.email;
      return null;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    } finally {
      _setBusy(false);
    }
  }

  Future<String?> register({
    required String username,
    required String email,
    required String password,
  }) async {
    _setBusy(true);
    try {
      if (await _storage.findUser(username) != null) {
        return 'That username is already taken.';
      }
      if (await _storage.emailExists(email)) {
        return 'An account with that email already exists.';
      }

      final salt = AuthStorage.generateSalt();
      final user = StoredUser(
        username: username.trim(),
        email: email.trim(),
        salt: salt,
        passwordHash: AuthStorage.hashPassword(password, salt),
      );
      await _storage.saveUser(user);

      // Sign the new user in straight away.
      await _storage.writeSession(user.username);
      _currentUser = user.username;
      _currentEmail = user.email;
      return null;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    } finally {
      _setBusy(false);
    }
  }

  /// Whether [password] matches the signed-in user's password. Used to
  /// confirm identity before a password change.
  Future<bool> verifyPassword(String password) async {
    final username = _currentUser;
    if (username == null) return false;
    final user = await _storage.findUser(username);
    return user != null &&
        AuthStorage.hashPassword(password, user.salt) == user.passwordHash;
  }

  /// Updates the signed-in user's [email] and/or [newPassword]. Returns
  /// `null` on success, or a user-facing error message.
  Future<String?> updateAccount({String? email, String? newPassword}) async {
    final username = _currentUser;
    if (username == null) return 'You are signed out.';

    try {
      final user = await _storage.findUser(username);
      if (user == null) return 'Account not found.';

      if (email != null) {
        final problem = AuthValidators.email(email);
        if (problem != null) return problem;
        if (await _storage.emailExists(email, exceptUsername: username)) {
          return 'An account with that email already exists.';
        }
      }
      if (newPassword != null) {
        final problem = AuthValidators.newPassword(newPassword);
        if (problem != null) return problem;
      }

      // A new password gets a fresh salt.
      final salt = newPassword == null ? user.salt : AuthStorage.generateSalt();
      final updated = StoredUser(
        username: user.username,
        email: email?.trim() ?? user.email,
        salt: salt,
        passwordHash: newPassword == null
            ? user.passwordHash
            : AuthStorage.hashPassword(newPassword, salt),
      );
      await _storage.saveUser(updated);

      _currentEmail = updated.email;
      notifyListeners();
      return null;
    } catch (_) {
      return 'Something went wrong. Please try again.';
    }
  }

  Future<void> logout() async {
    await _storage.writeSession(null);
    _currentUser = null;
    _currentEmail = null;
    notifyListeners();
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }
}