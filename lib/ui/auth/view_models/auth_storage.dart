import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StoredUser {
  const StoredUser({
    required this.username,
    required this.email,
    required this.salt,
    required this.passwordHash,
  });

  final String username;
  final String email;
  final String salt;
  final String passwordHash;

  Map<String, dynamic> toJson() => {
    'username': username,
    'email': email,
    'salt': salt,
    'passwordHash': passwordHash,
  };

  factory StoredUser.fromJson(Map<String, dynamic> json) => StoredUser(
    username: json['username'] as String,
    email: json['email'] as String,
    salt: json['salt'] as String,
    passwordHash: json['passwordHash'] as String,
  );
}

/// Local persistence for accounts and the signed-in session, backed by
/// `shared_preferences`.
class AuthStorage {
  static const _usersKey = 'auth.users';
  static const _sessionKey = 'auth.session';

  // Usernames and emails are matched case-insensitively.
  static String _key(String value) => value.trim().toLowerCase();

  Future<Map<String, StoredUser>> _readUsers() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_usersKey);
    if (raw == null || raw.isEmpty) return {};
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return decoded.map(
          (key, value) =>
          MapEntry(key, StoredUser.fromJson(value as Map<String, dynamic>)),
    );
  }

  Future<void> _writeUsers(Map<String, StoredUser> users) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _usersKey,
      jsonEncode(users.map((key, value) => MapEntry(key, value.toJson()))),
    );
  }

  Future<StoredUser?> findUser(String username) async =>
      (await _readUsers())[_key(username)];

  /// Whether another account already uses [email]. Pass [exceptUsername] to
  /// ignore the account being edited.
  Future<bool> emailExists(String email, {String? exceptUsername}) async {
    final target = _key(email);
    final except = exceptUsername == null ? null : _key(exceptUsername);
    final users = await _readUsers();
    return users.entries
        .any((e) => e.key != except && _key(e.value.email) == target);
  }

  Future<void> saveUser(StoredUser user) async {
    final users = await _readUsers();
    users[_key(user.username)] = user;
    await _writeUsers(users);
  }

  /// Returns the username of the signed-in user, if a session exists.
  Future<String?> readSession() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_sessionKey);
  }

  Future<void> writeSession(String? username) async {
    final prefs = await SharedPreferences.getInstance();
    if (username == null) {
      await prefs.remove(_sessionKey);
    } else {
      await prefs.setString(_sessionKey, _key(username));
    }
  }

  static String generateSalt() {
    final random = Random.secure();
    return base64UrlEncode(List<int>.generate(16, (_) => random.nextInt(256)));
  }

  static String hashPassword(String password, String salt) =>
      sha256.convert(utf8.encode('$salt:$password')).toString();
}