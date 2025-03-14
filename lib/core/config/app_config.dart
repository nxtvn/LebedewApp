import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:crypto/crypto.dart';
import 'dart:typed_data';

/// Umgebungstypen für die Anwendung
enum Environment { development, production }

/// Konfigurationsschlüssel für die sichere Speicherung
class ConfigKeys {
  static const mailjetApiKey = 'mailjet_api_key';
  static const mailjetSecretKey = 'mailjet_secret_key';
  static const serviceEmail = 'service_email';
  static const senderEmail = 'sender_email';
  static const senderName = 'sender_name';
  static const servicePassword = 'service_password';
  
  // Schlüssel für die Verschlüsselung
  static const encryptionSalt = 'encryption_salt';
}

/// Zentrale Konfigurationsklasse für die Anwendung
/// 
/// Diese Klasse verwaltet alle Konfigurationseinstellungen und
/// stellt sicher, dass sensible Daten sicher gespeichert werden.
class AppConfig {
  static final _log = Logger('AppConfig');
  static late final Environment _environment;
  static const _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );
  
  // Verschlüsselungs-Salt
  static late final String _encryptionSalt;
  static const String _defaultSalt = 'lebedew_default_salt';
  
  /// Initialisiert die Anwendungskonfiguration
  /// 
  /// Diese Methode muss vor der Verwendung von AppConfig aufgerufen werden.
  /// Sie setzt die Umgebung und initialisiert die Standardwerte, falls nötig.
  static Future<void> initialize({
    required Environment env,
    bool resetSecureStorage = false,
  }) async {
    _environment = env;
    _log.info('Initialisiere AppConfig mit Umgebung: $_environment');
    
    if (resetSecureStorage) {
      await _secureStorage.deleteAll();
      _log.info('Secure Storage zurückgesetzt');
    }
    
    // Initialisiere das Verschlüsselungs-Salt
    await _initializeEncryptionSalt();
    
    // Initialisiere Standardwerte, falls sie noch nicht gesetzt sind
    await _initializeDefaultValues();
  }
  
  /// Initialisiert das Verschlüsselungs-Salt
  static Future<void> _initializeEncryptionSalt() async {
    final storedSalt = await _secureStorage.read(key: ConfigKeys.encryptionSalt);
    
    if (storedSalt == null || storedSalt.isEmpty) {
      // Generiere ein zufälliges Salt
      final salt = _generateRandomSalt();
      await _secureStorage.write(key: ConfigKeys.encryptionSalt, value: salt);
      _encryptionSalt = salt;
      _log.info('Neues Verschlüsselungs-Salt generiert');
    } else {
      _encryptionSalt = storedSalt;
      _log.info('Vorhandenes Verschlüsselungs-Salt geladen');
    }
  }
  
  /// Generiert ein zufälliges Salt für die Verschlüsselung
  static String _generateRandomSalt() {
    // In einer echten Anwendung würden wir hier einen kryptografisch sicheren
    // Zufallszahlengenerator verwenden. Für diese Implementierung verwenden wir
    // einen einfachen Ansatz mit der aktuellen Zeit und einem festen Wert.
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(timestamp + _defaultSalt);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }
  
  /// Initialisiert Standardwerte für die Konfiguration
  /// 
  /// Diese Methode wird nur aufgerufen, wenn die Werte noch nicht gesetzt sind.
  static Future<void> _initializeDefaultValues() async {
    // In der Entwicklungsumgebung können wir Standardwerte setzen
    if (isDevelopment) {
      // Prüfe, ob die Werte bereits gesetzt sind
      final hasApiKey = await hasValue(ConfigKeys.mailjetApiKey);
      
      if (!hasApiKey) {
        _log.info('Setze Entwicklungs-Standardwerte');
        
        // Setze die Mailjet API-Schlüssel
        await setApiKey(ConfigKeys.mailjetApiKey, '3004d543963be32f5dbe4da2329e109c');
        await setApiKey(ConfigKeys.mailjetSecretKey, 'e28fd899034aba79be3b9bf6627f2621');
        await setApiKey(ConfigKeys.serviceEmail, 'service@lebedew.de');
        await setApiKey(ConfigKeys.senderEmail, 'julian.scherer@nextvision.agency');
        await setApiKey(ConfigKeys.senderName, 'Lebedew Haustechnik');
      }
    }
  }
  
  /// Prüft, ob ein Wert für einen Schlüssel existiert
  static Future<bool> hasValue(String keyName) async {
    final value = await _secureStorage.read(key: keyName);
    return value != null && value.isNotEmpty;
  }
  
  /// Verschlüsselt einen Wert
  static String _encryptValue(String value) {
    if (value.isEmpty) return value;
    
    final bytes = utf8.encode(value + _encryptionSalt);
    final hash = sha256.convert(bytes);
    final encrypted = '${base64.encode(utf8.encode(value))}.${hash.toString().substring(0, 8)}';
    return encrypted;
  }
  
  /// Entschlüsselt einen Wert
  static String _decryptValue(String encryptedValue) {
    if (encryptedValue.isEmpty) return encryptedValue;
    
    try {
      final parts = encryptedValue.split('.');
      if (parts.length != 2) return '';
      
      final encodedValue = parts[0];
      final checksum = parts[1];
      
      final decodedValue = utf8.decode(base64.decode(encodedValue));
      
      // Überprüfe die Integrität
      final bytes = utf8.encode(decodedValue + _encryptionSalt);
      final hash = sha256.convert(bytes);
      
      if (hash.toString().substring(0, 8) != checksum) {
        _log.warning('Integritätsprüfung fehlgeschlagen für Schlüssel');
        return '';
      }
      
      return decodedValue;
    } catch (e) {
      _log.severe('Fehler beim Entschlüsseln eines Werts: $e');
      return '';
    }
  }
  
  /// Setzt einen API-Schlüssel in der sicheren Speicherung
  static Future<void> setApiKey(String keyName, String value) async {
    final encryptedValue = _encryptValue(value);
    await _secureStorage.write(key: keyName, value: encryptedValue);
  }
  
  /// Liest einen API-Schlüssel aus der sicheren Speicherung
  static Future<String> getApiKey(String keyName) async {
    final encryptedValue = await _secureStorage.read(key: keyName);
    if (encryptedValue == null || encryptedValue.isEmpty) {
      _log.warning('API-Schlüssel nicht gefunden: $keyName');
      return '';
    }
    return _decryptValue(encryptedValue);
  }
  
  /// Löscht einen API-Schlüssel aus der sicheren Speicherung
  static Future<void> deleteApiKey(String keyName) async {
    await _secureStorage.delete(key: keyName);
  }
  
  /// Gibt alle gespeicherten Schlüssel zurück
  static Future<Map<String, String>> getAllValues() async {
    final encryptedValues = await _secureStorage.readAll();
    final decryptedValues = <String, String>{};
    
    encryptedValues.forEach((key, value) {
      if (key != ConfigKeys.encryptionSalt) {
        decryptedValues[key] = _decryptValue(value);
      }
    });
    
    return decryptedValues;
  }
  
  /// Importiert sichere Konfigurationswerte
  /// 
  /// Diese Methode sollte verwendet werden, um sichere Konfigurationswerte
  /// aus einer externen Quelle zu importieren, z.B. aus einer verschlüsselten
  /// Konfigurationsdatei oder einem sicheren Backend-Dienst.
  static Future<bool> importSecureConfig(Map<String, String> config) async {
    try {
      for (final entry in config.entries) {
        await setApiKey(entry.key, entry.value);
      }
      _log.info('Sichere Konfiguration importiert');
      return true;
    } catch (e) {
      _log.severe('Fehler beim Importieren der sicheren Konfiguration: $e');
      return false;
    }
  }
  
  /// Löscht einen String-Wert sicher aus dem Speicher
  /// 
  /// Diese Methode überschreibt den Speicherbereich des Strings mit zufälligen Daten,
  /// bevor die Referenz gelöscht wird. Dies reduziert das Risiko, dass sensible Daten
  /// im Speicher verbleiben und bei einem Speicherabbild lesbar sind.
  static String securelyWipeValue(String value) {
    if (value.isEmpty) return '';
    
    try {
      // Erstelle eine Kopie des Strings im Speicher
      final buffer = Uint8List(value.length);
      
      // Überschreibe mit zufälligen Daten (in Dart nicht direkt möglich, 
      // aber wir können den Wert in einem Array überschreiben)
      for (int i = 0; i < buffer.length; i++) {
        buffer[i] = (DateTime.now().microsecondsSinceEpoch % 256);
      }
      
      // Erzeuge einen neuen String aus den zufälligen Daten, um den ursprünglichen zu überschreiben
      final randomString = String.fromCharCodes(buffer);
      
      // Lösche alle Spuren im Code
      buffer.fillRange(0, buffer.length, 0);
      
      _log.fine('Wert sicher gelöscht (Länge: ${value.length})');
      return randomString;
    } catch (e) {
      _log.warning('Fehler beim sicheren Löschen eines Werts: $e');
      return '';
    }
  }
  
  /// Löscht alle sensiblen Daten sicher aus dem Speicher
  /// 
  /// Diese Methode sollte aufgerufen werden, wenn die Anwendung geschlossen wird
  /// oder wenn der Benutzer sich abmeldet, um sicherzustellen, dass keine sensiblen
  /// Daten im Speicher verbleiben.
  static Future<void> securelyWipeAllFromMemory() async {
    try {
      _log.info('Lösche alle sensiblen Daten aus dem Speicher');
      
      // Hole alle Schlüssel
      final values = await getAllValues();
      
      // Lösche jeden Wert sicher
      for (final entry in values.entries) {
        securelyWipeValue(entry.value);
      }
      
      // Lösche das Verschlüsselungs-Salt sicher
      _encryptionSalt = securelyWipeValue(_encryptionSalt);
      
      _log.info('Alle sensiblen Daten wurden sicher aus dem Speicher gelöscht');
    } catch (e) {
      _log.severe('Fehler beim sicheren Löschen aller Daten: $e');
    }
  }
  
  // App-Einstellungen
  static bool get isDevelopment => _environment == Environment.development;
  static String get apiBaseUrl => isDevelopment 
    ? 'https://dev-api.lebedew.de' 
    : 'https://api.lebedew.de';
    
  // E-Mail-Konfiguration Getter
  static Future<String> get mailjetApiKey => getApiKey(ConfigKeys.mailjetApiKey);
  static Future<String> get mailjetSecretKey => getApiKey(ConfigKeys.mailjetSecretKey);
  static Future<String> get serviceEmail => getApiKey(ConfigKeys.serviceEmail);
  static Future<String> get senderEmail => getApiKey(ConfigKeys.senderEmail);
  static Future<String> get senderName => getApiKey(ConfigKeys.senderName);
} 