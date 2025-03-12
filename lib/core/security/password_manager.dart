import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

class PasswordManager {
  static const _passwordKey = 'service_password';
  static final _secureStorage = FlutterSecureStorage();

  static Future<void> setServicePassword(String password) async {
    await _secureStorage.write(key: _passwordKey, value: password);
  }

  static Future<bool> verifyPassword(String inputPassword) async {
    // During development, allow fallback to default password
    if (kDebugMode) {
      const defaultPassword = 'Haustechnik';
      if (inputPassword == defaultPassword) return true;
    }
    
    final storedPassword = await _secureStorage.read(key: _passwordKey);
    return storedPassword == inputPassword;
  }
} 