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
      
      // Lade die Datei
      final jsonString = await rootBundle.loadString(assetPath);
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
} 