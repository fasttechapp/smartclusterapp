import 'package:shared_preferences/shared_preferences.dart';

import 'logger.dart';

class UserSession {
  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;
  UserSession._internal();

  String? userName;
  String? email;
  String? rememberToken;

  Future<void> loadFromPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    userName = prefs.getString('name');
    email = prefs.getString('email');
    rememberToken = prefs.getString('remember_token');
    log.info(
      'Loaded session: userName=$userName, email=$email, token=$rememberToken',
    );
  }

  Future<void> setSession({
    required String name,
    required String email,
    required String rememberToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('email', email);
    await prefs.setString('remember_token', rememberToken);

    userName = name;
    this.email = email;
    this.rememberToken = rememberToken;
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('name');
    await prefs.remove('email');
    await prefs.remove('remember_token');

    userName = null;
    email = null;
    rememberToken = null;
  }

  bool get isLoggedIn => rememberToken != null;
}
