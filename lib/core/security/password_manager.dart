import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../config/app_config.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../logging/app_logger.dart';

/// Verwaltet sichere Passwörter für die Anwendung
class PasswordManager {
  static final _log = AppLogger.getLogger('PasswordManager');
  static const _defaultDevPassword = 'Haustechnik';
  static const _rememberPasswordKey = 'remembered_password';
  static const _rememberPasswordEnabledKey = 'remember_password_enabled';
  static const _secureStorage = FlutterSecureStorage();
  
  /// Setzt das Service-Passwort
  /// 
  /// Das Passwort wird gehasht und sicher gespeichert
  static Future<void> setServicePassword(String password) async {
    try {
      final hashedPassword = _hashPassword(password);
      await AppConfig.setApiKey(ConfigKeys.servicePassword, hashedPassword);
      
      AppLogger.logPasswordOperation(
        _log, 
        operation: 'Passwort setzen',
        success: true
      );
      
      _log.info('Service-Passwort wurde aktualisiert');
    } catch (e) {
      AppLogger.logPasswordOperation(
        _log, 
        operation: 'Passwort setzen',
        success: false
      );
      _log.severe('Fehler beim Setzen des Service-Passworts: $e', e);
    }
  }

  /// Überprüft, ob das eingegebene Passwort korrekt ist
  /// 
  /// Im Debug-Modus wird auch das Standard-Passwort akzeptiert
  static Future<bool> verifyPassword(String inputPassword) async {
    try {
      // Im Debug-Modus erlauben wir das Standard-Passwort
      if (kDebugMode && inputPassword == _defaultDevPassword) {
        _log.info('Standard-Entwicklungspasswort verwendet');
        
        AppLogger.logAuthAttempt(
          _log,
          success: true,
          username: 'Entwickler'
        );
        
        return true;
      }
      
      // Prüfe das gespeicherte Passwort
      final storedPassword = await AppConfig.getApiKey(ConfigKeys.servicePassword);
      if (storedPassword.isEmpty) {
        _log.warning('Kein Passwort gespeichert, setze Standard-Passwort');
        
        // Wenn kein Passwort gespeichert ist, setzen wir das Standard-Passwort
        await setServicePassword(_defaultDevPassword);
        
        // Vergleiche mit dem Eingabepasswort
        final isValid = inputPassword == _defaultDevPassword;
        
        AppLogger.logAuthAttempt(
          _log,
          success: isValid
        );
        
        return isValid;
      }
      
      // Vergleiche das gehashte Eingabepasswort mit dem gespeicherten Passwort
      final hashedInput = _hashPassword(inputPassword);
      final isValid = storedPassword == hashedInput;
      
      AppLogger.logAuthAttempt(
        _log,
        success: isValid
      );
      
      if (!isValid) {
        _log.warning('Ungültiges Passwort eingegeben');
      } else {
        _log.info('Passwort erfolgreich verifiziert');
      }
      
      return isValid;
    } catch (e) {
      _log.severe('Fehler bei der Passwortüberprüfung: $e', e);
      
      AppLogger.logAuthAttempt(
        _log,
        success: false
      );
      
      return false;
    }
  }
  
  /// Hasht ein Passwort mit SHA-256
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }
  
  /// Prüft, ob ein Passwort gesetzt ist
  static Future<bool> hasPassword() async {
    try {
      final storedPassword = await AppConfig.getApiKey(ConfigKeys.servicePassword);
      final hasPassword = storedPassword.isNotEmpty;
      
      _log.info('Passwort-Status geprüft: ${hasPassword ? 'Vorhanden' : 'Nicht vorhanden'}');
      
      return hasPassword;
    } catch (e) {
      _log.severe('Fehler beim Prüfen des Passwort-Status: $e', e);
      return false;
    }
  }
  
  /// Setzt das Passwort zurück (nur im Debug-Modus)
  static Future<void> resetPassword() async {
    if (kDebugMode) {
      try {
        await AppConfig.deleteApiKey(ConfigKeys.servicePassword);
        
        AppLogger.logPasswordOperation(
          _log, 
          operation: 'Passwort zurücksetzen',
          success: true
        );
        
        _log.warning('Passwort zurückgesetzt (Debug-Modus)');
      } catch (e) {
        AppLogger.logPasswordOperation(
          _log, 
          operation: 'Passwort zurücksetzen',
          success: false
        );
        
        _log.severe('Fehler beim Zurücksetzen des Passworts: $e', e);
      }
    }
  }

  /// Speichert das Passwort für die "Passwort merken" Funktion
  static Future<void> saveRememberedPassword(String password) async {
    try {
      await _secureStorage.write(key: _rememberPasswordKey, value: password);
      await _secureStorage.write(key: _rememberPasswordEnabledKey, value: 'true');
      
      AppLogger.logPasswordOperation(
        _log, 
        operation: 'Passwort speichern (Passwort merken)',
        success: true
      );
      
      _log.info('Passwort für "Passwort merken" gespeichert');
    } catch (e) {
      AppLogger.logPasswordOperation(
        _log, 
        operation: 'Passwort speichern (Passwort merken)',
        success: false
      );
      
      _log.severe('Fehler beim Speichern des Passworts: $e', e);
    }
  }

  /// Löscht das gespeicherte Passwort für die "Passwort merken" Funktion
  static Future<void> clearRememberedPassword() async {
    try {
      await _secureStorage.delete(key: _rememberPasswordKey);
      await _secureStorage.write(key: _rememberPasswordEnabledKey, value: 'false');
      
      AppLogger.logPasswordOperation(
        _log, 
        operation: 'Passwort löschen (Passwort merken)',
        success: true
      );
      
      _log.info('Gespeichertes Passwort gelöscht');
    } catch (e) {
      AppLogger.logPasswordOperation(
        _log, 
        operation: 'Passwort löschen (Passwort merken)',
        success: false
      );
      
      _log.severe('Fehler beim Löschen des gespeicherten Passworts: $e', e);
    }
  }

  /// Ruft das gespeicherte Passwort ab
  static Future<String> getRememberedPassword() async {
    try {
      final password = await _secureStorage.read(key: _rememberPasswordKey);
      
      AppLogger.logPasswordOperation(
        _log, 
        operation: 'Passwort abrufen (Passwort merken)',
        success: password != null
      );
      
      if (password != null) {
        _log.info('Gespeichertes Passwort abgerufen');
      } else {
        _log.info('Kein gespeichertes Passwort vorhanden');
      }
      
      return password ?? '';
    } catch (e) {
      AppLogger.logPasswordOperation(
        _log, 
        operation: 'Passwort abrufen (Passwort merken)',
        success: false
      );
      
      _log.severe('Fehler beim Abrufen des gespeicherten Passworts: $e', e);
      return '';
    }
  }

  /// Prüft, ob die "Passwort merken" Funktion aktiviert ist
  static Future<bool> isRememberPasswordEnabled() async {
    try {
      final enabled = await _secureStorage.read(key: _rememberPasswordEnabledKey);
      final isEnabled = enabled == 'true';
      
      _log.info('"Passwort merken" Status: ${isEnabled ? 'Aktiviert' : 'Deaktiviert'}');
      
      return isEnabled;
    } catch (e) {
      _log.severe('Fehler beim Prüfen des "Passwort merken" Status: $e', e);
      return false;
    }
  }
} 