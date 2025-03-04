// Keine Imports nötig für die vereinfachte Version

class PasswordManager {
  static const _defaultPassword = 'Haustechnik';

  static Future<bool> verifyPassword(String password) async {
    return password == _defaultPassword;
  }
} 