import 'dart:io';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:share_plus/share_plus.dart';
import '../platform/platform_helper.dart';

/// Eine zentrale Logging-Klasse für die gesamte App
/// 
/// Diese Klasse erweitert das vorhandene Logging-System und bietet
/// spezifische Logging-Funktionen für verschiedene Bereiche der App.
class AppLogger {
  static final Map<String, Logger> _loggers = {};
  static final List<LogRecord> _logBuffer = [];
  static const int _maxBufferSize = 1000;
  static bool _isInitialized = false;
  static File? _logFile;
  static final _dateFormat = DateFormat('yyyy-MM-dd HH:mm:ss.SSS');
  
  /// Initialisiert das Logging-System
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Konfiguriere das Root-Logger
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen(_handleLogRecord);
    
    // Initialisiere die Log-Datei
    await _initLogFile();
    
    _isInitialized = true;
    
    // Logge die Initialisierung
    final log = getLogger('AppLogger');
    log.info('Logging-System initialisiert');
    
    // Logge Systeminformationen
    _logSystemInfo(log);
  }
  
  /// Initialisiert die Log-Datei
  static Future<void> _initLogFile() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDocDir.path}/logs');
      
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      final now = DateTime.now();
      final fileName = 'app_log_${now.year}-${now.month}-${now.day}.log';
      _logFile = File('${logDir.path}/$fileName');
      
      // Prüfe, ob die Datei existiert, und erstelle sie, falls nicht
      if (!await _logFile!.exists()) {
        await _logFile!.create();
      }
    } catch (e) {
      debugPrint('Fehler beim Initialisieren der Log-Datei: $e');
    }
  }
  
  /// Behandelt einen Log-Eintrag
  static void _handleLogRecord(LogRecord record) {
    // Formatiere den Log-Eintrag
    final formattedLog = _formatLogRecord(record);
    
    // Gib den Log-Eintrag in der Konsole aus
    debugPrint(formattedLog);
    
    // Füge den Log-Eintrag zum Puffer hinzu
    _addToBuffer(record);
    
    // Schreibe den Log-Eintrag in die Datei
    _writeToFile(formattedLog);
  }
  
  /// Formatiert einen Log-Eintrag
  static String _formatLogRecord(LogRecord record) {
    final time = _dateFormat.format(record.time);
    final level = record.level.name.padRight(7);
    final loggerName = record.loggerName.padRight(15);
    final message = record.message;
    
    String formattedLog = '[$time] $level $loggerName: $message';
    
    if (record.error != null) {
      formattedLog += '\nError: ${record.error}';
    }
    
    if (record.stackTrace != null) {
      formattedLog += '\nStack trace: ${record.stackTrace}';
    }
    
    return formattedLog;
  }
  
  /// Fügt einen Log-Eintrag zum Puffer hinzu
  static void _addToBuffer(LogRecord record) {
    _logBuffer.add(record);
    
    // Begrenze die Größe des Puffers
    if (_logBuffer.length > _maxBufferSize) {
      _logBuffer.removeAt(0);
    }
  }
  
  /// Schreibt einen Log-Eintrag in die Datei
  static Future<void> _writeToFile(String logEntry) async {
    if (_logFile != null) {
      try {
        await _logFile!.writeAsString('$logEntry\n', mode: FileMode.append);
      } catch (e) {
        debugPrint('Fehler beim Schreiben in die Log-Datei: $e');
      }
    }
  }
  
  /// Loggt Systeminformationen
  static void _logSystemInfo(Logger log) {
    log.info('=== Systeminformationen ===');
    log.info('Betriebssystem: ${Platform.operatingSystem} ${Platform.operatingSystemVersion}');
    log.info('Gerät: ${Platform.localHostname}');
    log.info('Dart Version: ${Platform.version}');
    log.info('Ist iOS: ${PlatformHelper.isIOS()}');
    log.info('Ist Android: ${PlatformHelper.isAndroid()}');
    log.info('Anzahl Prozessoren: ${Platform.numberOfProcessors}');
    log.info('Locale: ${Platform.localeName}');
    log.info('=== Ende Systeminformationen ===');
  }
  
  /// Gibt einen Logger für eine bestimmte Klasse zurück
  static Logger getLogger(String name) {
    if (!_loggers.containsKey(name)) {
      _loggers[name] = Logger(name);
    }
    return _loggers[name]!;
  }
  
  /// Teilt die Log-Datei
  static Future<void> shareLogs() async {
    if (_logFile != null && await _logFile!.exists()) {
      try {
        await Share.shareXFiles([XFile(_logFile!.path)], text: 'App-Logs');
      } catch (e) {
        debugPrint('Fehler beim Teilen der Log-Datei: $e');
      }
    }
  }
  
  /// Gibt die letzten Log-Einträge zurück
  static List<LogRecord> getRecentLogs({int count = 100}) {
    final endIndex = _logBuffer.length;
    final startIndex = endIndex - count < 0 ? 0 : endIndex - count;
    return _logBuffer.sublist(startIndex, endIndex);
  }
  
  /// Löscht alle Log-Dateien
  static Future<void> clearLogs() async {
    try {
      final appDocDir = await getApplicationDocumentsDirectory();
      final logDir = Directory('${appDocDir.path}/logs');
      
      if (await logDir.exists()) {
        await logDir.delete(recursive: true);
        await logDir.create();
      }
      
      // Initialisiere die Log-Datei neu
      await _initLogFile();
      
      // Leere den Puffer
      _logBuffer.clear();
      
      final log = getLogger('AppLogger');
      log.info('Log-Dateien gelöscht');
    } catch (e) {
      debugPrint('Fehler beim Löschen der Log-Dateien: $e');
    }
  }
  
  /// Erstellt einen eindeutigen Identifier für Tracking-Zwecke
  static String generateUniqueId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    final random = DateTime.now().microsecondsSinceEpoch % 1000;
    return '$now-$random';
  }
  
  /// Loggt einen Authentifizierungsversuch
  static void logAuthAttempt(Logger log, {required bool success, String? username}) {
    if (success) {
      log.info('Authentifizierung erfolgreich${username != null ? ' für Benutzer: $username' : ''}');
    } else {
      log.warning('Authentifizierung fehlgeschlagen${username != null ? ' für Benutzer: $username' : ''}');
    }
  }
  
  /// Loggt das Speichern oder Abrufen eines Passworts
  static void logPasswordOperation(Logger log, {required String operation, required bool success}) {
    if (success) {
      log.info('Passwort-Operation erfolgreich: $operation');
    } else {
      log.warning('Passwort-Operation fehlgeschlagen: $operation');
    }
  }
  
  /// Loggt die Formularvalidierung
  static void logFormValidation(Logger log, {required bool isValid, String? formName, Map<String, dynamic>? invalidFields}) {
    if (isValid) {
      log.info('Formularvalidierung erfolgreich${formName != null ? ' für $formName' : ''}');
    } else {
      log.warning('Formularvalidierung fehlgeschlagen${formName != null ? ' für $formName' : ''}');
      if (invalidFields != null && invalidFields.isNotEmpty) {
        log.warning('Ungültige Felder: ${jsonEncode(invalidFields)}');
      }
    }
  }
  
  /// Loggt das Erscheinen oder Verschwinden von bedingten Feldern
  static void logConditionalFieldChange(Logger log, {required String fieldName, required bool isVisible, String? dependsOn, dynamic dependsOnValue}) {
    log.info('Bedingtes Feld "$fieldName" ist jetzt ${isVisible ? 'sichtbar' : 'versteckt'}${dependsOn != null ? ', abhängig von "$dependsOn" mit Wert "$dependsOnValue"' : ''}');
  }
  
  /// Loggt kritische Feldwerte vor dem Absenden
  static void logCriticalFieldValues(Logger log, {required Map<String, dynamic> fields}) {
    // Entferne sensible Daten
    final safeFields = Map<String, dynamic>.from(fields);
    
    // Entferne oder maskiere sensible Felder
    final sensitiveFields = ['password', 'token', 'secret', 'key'];
    for (final field in sensitiveFields) {
      if (safeFields.containsKey(field)) {
        safeFields[field] = '******';
      }
    }
    
    log.info('Kritische Feldwerte vor dem Absenden: ${jsonEncode(safeFields)}');
  }
  
  /// Loggt den Bildauswahl-Workflow
  static void logImagePickerWorkflow(Logger log, {required String step, String? source, String? filePath, int? fileSize, String? error, String? uniqueId}) {
    final timestamp = _dateFormat.format(DateTime.now());
    
    String message = '[$timestamp] Bildauswahl: $step';
    
    if (source != null) {
      message += ', Quelle: $source';
    }
    
    if (filePath != null) {
      message += ', Pfad: $filePath';
    }
    
    if (fileSize != null) {
      final fileSizeKB = (fileSize / 1024).toStringAsFixed(2);
      message += ', Größe: $fileSizeKB KB';
    }
    
    if (uniqueId != null) {
      message += ', ID: $uniqueId';
    }
    
    if (error != null) {
      log.warning('$message, Fehler: $error');
    } else {
      log.info(message);
    }
  }
  
  /// Loggt Berechtigungsstatus und Benutzerantworten
  static void logPermissionStatus(Logger log, {required String permission, required String status, String? userResponse}) {
    log.info('Berechtigung "$permission" Status: $status${userResponse != null ? ', Benutzerantwort: $userResponse' : ''}');
  }
  
  /// Loggt die E-Mail-Vorbereitung
  static void logEmailPreparation(Logger log, {required String recipient, required String subject, int? attachmentsCount, String? uniqueId}) {
    log.info('E-Mail-Vorbereitung: Empfänger: $recipient, Betreff: $subject${attachmentsCount != null ? ', Anhänge: $attachmentsCount' : ''}${uniqueId != null ? ', ID: $uniqueId' : ''}');
  }
  
  /// Loggt API-Antworten
  static void logApiResponse(Logger log, {required String endpoint, required int statusCode, String? responseBody, String? uniqueId}) {
    if (statusCode >= 200 && statusCode < 300) {
      log.info('API-Antwort von $endpoint: Status $statusCode${uniqueId != null ? ', ID: $uniqueId' : ''}');
    } else {
      log.warning('API-Antwort von $endpoint: Status $statusCode${uniqueId != null ? ', ID: $uniqueId' : ''}${responseBody != null ? ', Antwort: $responseBody' : ''}');
    }
  }
  
  /// Loggt die Akzeptanz der AGB
  static void logTermsAcceptance(Logger log, {required bool accepted}) {
    if (accepted) {
      log.info('AGB wurden akzeptiert');
    } else {
      log.warning('AGB wurden nicht akzeptiert');
    }
  }
} 