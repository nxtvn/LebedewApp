import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';

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
    
    // Initialisiere Standardwerte, falls sie noch nicht gesetzt sind
    await _initializeDefaultValues();
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
        
        // Hier würden wir in einer echten Anwendung sichere Standardwerte setzen
        // Für die Entwicklung verwenden wir Platzhalter
        await setApiKey(ConfigKeys.mailjetApiKey, 'dev_api_key');
        await setApiKey(ConfigKeys.mailjetSecretKey, 'dev_secret_key');
        await setApiKey(ConfigKeys.serviceEmail, 'dev@example.com');
        await setApiKey(ConfigKeys.senderEmail, 'dev@example.com');
        await setApiKey(ConfigKeys.senderName, 'Development');
      }
    }
  }
  
  /// Prüft, ob ein Wert für einen Schlüssel existiert
  static Future<bool> hasValue(String keyName) async {
    final value = await _secureStorage.read(key: keyName);
    return value != null && value.isNotEmpty;
  }
  
  /// Setzt einen API-Schlüssel in der sicheren Speicherung
  static Future<void> setApiKey(String keyName, String value) async {
    await _secureStorage.write(key: keyName, value: value);
  }
  
  /// Liest einen API-Schlüssel aus der sicheren Speicherung
  static Future<String> getApiKey(String keyName) async {
    final value = await _secureStorage.read(key: keyName);
    if (value == null || value.isEmpty) {
      _log.warning('API-Schlüssel nicht gefunden: $keyName');
      return '';
    }
    return value;
  }
  
  /// Löscht einen API-Schlüssel aus der sicheren Speicherung
  static Future<void> deleteApiKey(String keyName) async {
    await _secureStorage.delete(key: keyName);
  }
  
  /// Gibt alle gespeicherten Schlüssel zurück
  static Future<Map<String, String>> getAllValues() async {
    return await _secureStorage.readAll();
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