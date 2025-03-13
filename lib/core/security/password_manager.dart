import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../config/app_config.dart';
import 'package:logging/logging.dart';

/// Verwaltet sichere Passwörter für die Anwendung
class PasswordManager {
  static final _log = Logger('PasswordManager');
  static const _defaultDevPassword = 'Haustechnik';
  
  /// Setzt das Service-Passwort
  /// 
  /// Das Passwort wird gehasht und sicher gespeichert
  static Future<void> setServicePassword(String password) async {
    final hashedPassword = _hashPassword(password);
    await AppConfig.setApiKey(ConfigKeys.servicePassword, hashedPassword);
    _log.info('Service-Passwort wurde aktualisiert');
  }

  /// Überprüft, ob das eingegebene Passwort korrekt ist
  /// 
  /// Im Debug-Modus wird auch das Standard-Passwort akzeptiert
  static Future<bool> verifyPassword(String inputPassword) async {
    // Im Debug-Modus erlauben wir das Standard-Passwort
    if (kDebugMode && inputPassword == _defaultDevPassword) {
      _log.info('Standard-Entwicklungspasswort verwendet');
      return true;
    }
    
    // Prüfe das gespeicherte Passwort
    final storedPassword = await AppConfig.getApiKey(ConfigKeys.servicePassword);
    if (storedPassword.isEmpty) {
      _log.warning('Kein Passwort gespeichert, setze Standard-Passwort');
      // Wenn kein Passwort gespeichert ist, setzen wir das Standard-Passwort
      await setServicePassword(_defaultDevPassword);
      // Vergleiche mit dem Eingabepasswort
      return inputPassword == _defaultDevPassword;
    }
    
    // Vergleiche das gehashte Eingabepasswort mit dem gespeicherten Passwort
    final hashedInput = _hashPassword(inputPassword);
    return storedPassword == hashedInput;
  }
  
  /// Hasht ein Passwort mit SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Prüft, ob ein Passwort gesetzt ist
  static Future<bool> hasPassword() async {
    final storedPassword = await AppConfig.getApiKey(ConfigKeys.servicePassword);
    return storedPassword.isNotEmpty;
  }
  
  /// Setzt das Passwort zurück (nur im Debug-Modus)
  static Future<void> resetPassword() async {
    if (kDebugMode) {
      await AppConfig.deleteApiKey(ConfigKeys.servicePassword);
      _log.warning('Passwort zurückgesetzt (Debug-Modus)');
    }
  }
} 