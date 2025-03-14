import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:logging/logging.dart';
import 'app_config.dart';

/// Hilfsmethoden zum Importieren von Konfigurationsdaten
class ConfigImporter {
  static final _log = Logger('ConfigImporter');
  
  /// Importiert Konfigurationsdaten aus einer JSON-Datei
  /// 
  /// Diese Methode kann verwendet werden, um Konfigurationsdaten aus einer
  /// JSON-Datei zu importieren, die nicht im Quellcode enthalten ist.
  /// Die Datei sollte im Assets-Verzeichnis liegen.
  static Future<bool> importFromAsset(String assetPath) async {
    try {
      _log.info('Importiere Konfiguration aus Asset: $assetPath');
      
      // Versuche, die Datei zu laden
      final jsonString = await rootBundle.loadString(assetPath);
      final Map<String, dynamic> config = json.decode(jsonString);
      
      // Importiere die Konfigurationsdaten
      await _importConfig(config);
      
      _log.info('Konfiguration erfolgreich importiert');
      return true;
    } catch (e) {
      if (e.toString().contains('Unable to load asset') || 
          e.toString().contains('asset not found') ||
          e.toString().contains('FileNotFoundException')) {
        _log.warning('Konfigurationsdatei nicht gefunden: $assetPath. Standard-Konfiguration wird verwendet.');
        // Initialisiere Standard-Konfigurationswerte
        await _importDefaultConfig();
        return true;
      } else {
        _log.severe('Fehler beim Importieren der Konfiguration: ${e.toString()}');
        return false;
      }
    }
  }
  
  /// Importiert Konfigurationsdaten aus einem JSON-String
  /// 
  /// Diese Methode kann verwendet werden, um Konfigurationsdaten aus einem
  /// JSON-String zu importieren, der z.B. von einer API oder einem QR-Code
  /// stammt.
  static Future<bool> importFromJson(String jsonString) async {
    try {
      _log.info('Importiere Konfiguration aus JSON-String');
      
      // Dekodiere den JSON-String
      final Map<String, dynamic> config = json.decode(jsonString);
      
      // Importiere die Konfigurationsdaten
      await _importConfig(config);
      
      _log.info('Konfiguration erfolgreich importiert');
      return true;
    } catch (e) {
      _log.severe('Fehler beim Importieren der Konfiguration', e);
      return false;
    }
  }
  
  /// Importiert Konfigurationsdaten aus einer Map
  static Future<void> _importConfig(Map<String, dynamic> config) async {
    _log.info('Beginne mit dem Import der Konfigurationsdaten');
    
    // Logging der Struktur, um Fehler zu identifizieren (ohne sensible Werte zu zeigen)
    _log.info('Konfigurationsstruktur: ${config.keys.toList()}');
    if (config.containsKey('mailjet')) {
      _log.info('Mailjet-Abschnitt gefunden mit Schlüsseln: ${config['mailjet'].keys.toList()}');
    }
    if (config.containsKey('email')) {
      _log.info('Email-Abschnitt gefunden mit Schlüsseln: ${config['email'].keys.toList()}');
    }
    
    // Mailjet-Konfiguration
    if (config.containsKey('mailjet')) {
      final mailjet = config['mailjet'];
      
      if (mailjet.containsKey('apiKey')) {
        await AppConfig.setApiKey(ConfigKeys.mailjetApiKey, mailjet['apiKey']);
        _log.info('Mailjet API-Key gespeichert');
      }
      
      if (mailjet.containsKey('secretKey')) {
        await AppConfig.setApiKey(ConfigKeys.mailjetSecretKey, mailjet['secretKey']);
        _log.info('Mailjet Secret-Key gespeichert');
      }
    }
    
    // E-Mail-Konfiguration
    if (config.containsKey('email')) {
      final email = config['email'];
      
      if (email.containsKey('serviceEmail')) {
        final serviceEmail = email['serviceEmail'];
        await AppConfig.setApiKey(ConfigKeys.serviceEmail, serviceEmail);
        _log.info('Service-E-Mail gespeichert: ${serviceEmail.substring(0, 3)}***');
      }
      
      if (email.containsKey('senderEmail')) {
        final senderEmail = email['senderEmail'];
        await AppConfig.setApiKey(ConfigKeys.senderEmail, senderEmail);
        _log.info('Absender-E-Mail gespeichert: ${senderEmail.substring(0, 3)}***');
      }
      
      if (email.containsKey('senderName')) {
        final senderName = email['senderName'];
        await AppConfig.setApiKey(ConfigKeys.senderName, senderName);
        _log.info('Absender-Name gespeichert: $senderName');
      }
    }
    
    // Überprüfe die gespeicherten Werte zur Bestätigung
    final storedSenderEmail = await AppConfig.senderEmail;
    _log.info('Gespeicherter Wert für sender_email: ${storedSenderEmail.isEmpty ? "leer" : storedSenderEmail.substring(0, 3) + "***"}');
  }
  
  /// Neue Hilfsmethode für Standardkonfiguration
  static Future<void> _importDefaultConfig() async {
    // Setze Standardwerte für die Konfiguration
    await AppConfig.setApiKey(ConfigKeys.mailjetApiKey, 'default_key');
    await AppConfig.setApiKey(ConfigKeys.mailjetSecretKey, 'default_secret');
    await AppConfig.setApiKey(ConfigKeys.serviceEmail, 'service@example.com');
    await AppConfig.setApiKey(ConfigKeys.senderEmail, 'noreply@example.com');
    await AppConfig.setApiKey(ConfigKeys.senderName, 'Lebedew Haustechnik');
  }
} 