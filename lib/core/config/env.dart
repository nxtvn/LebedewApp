import 'app_config.dart';

/// Umgebungsvariablen für die Anwendung
/// 
/// ACHTUNG: Diese Klasse ist veraltet und wird nur für Abwärtskompatibilität beibehalten.
/// Bitte verwenden Sie stattdessen die AppConfig-Klasse.
/// 
/// @deprecated Verwenden Sie stattdessen AppConfig
class Env {
  /// Mailjet API-Key
  /// @deprecated Verwenden Sie stattdessen AppConfig.mailjetApiKey
  static String mailjetApiKey = '';

  /// Mailjet Secret-Key
  /// @deprecated Verwenden Sie stattdessen AppConfig.mailjetSecretKey
  static String mailjetSecretKey = '';

  /// E-Mail-Adresse für den Empfang von Störungsmeldungen
  /// @deprecated Verwenden Sie stattdessen AppConfig.serviceEmail
  static String serviceEmail = '';

  /// E-Mail-Adresse für den Versand von Störungsmeldungen
  /// @deprecated Verwenden Sie stattdessen AppConfig.senderEmail
  static String senderEmail = '';

  /// Absender-Name für Störungsmeldungen
  /// @deprecated Verwenden Sie stattdessen AppConfig.senderName
  static String senderName = '';
  
  /// Initialisiert die Env-Klasse mit Werten aus AppConfig
  /// Diese Methode sollte nach der Initialisierung von AppConfig aufgerufen werden
  static Future<void> initialize() async {
    mailjetApiKey = await AppConfig.mailjetApiKey;
    mailjetSecretKey = await AppConfig.mailjetSecretKey;
    serviceEmail = await AppConfig.serviceEmail;
    senderEmail = await AppConfig.senderEmail;
    senderName = await AppConfig.senderName;
  }
} 