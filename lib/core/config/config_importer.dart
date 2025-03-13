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
    // Mailjet-Konfiguration
    if (config.containsKey('mailjet')) {
      final mailjet = config['mailjet'];
      
      if (mailjet.containsKey('apiKey')) {
        await AppConfig.setApiKey(ConfigKeys.mailjetApiKey, mailjet['apiKey']);
      }
      
      if (mailjet.containsKey('secretKey')) {
        await AppConfig.setApiKey(ConfigKeys.mailjetSecretKey, mailjet['secretKey']);
      }
    }
    
    // E-Mail-Konfiguration
    if (config.containsKey('email')) {
      final email = config['email'];
      
      if (email.containsKey('serviceEmail')) {
        await AppConfig.setApiKey(ConfigKeys.serviceEmail, email['serviceEmail']);
      }
      
      if (email.containsKey('senderEmail')) {
        await AppConfig.setApiKey(ConfigKeys.senderEmail, email['senderEmail']);
      }
      
      if (email.containsKey('senderName')) {
        await AppConfig.setApiKey(ConfigKeys.senderName, email['senderName']);
      }
    }
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