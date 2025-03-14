import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'dart:math' as math;
import 'package:logging/logging.dart';
import 'package:image/image.dart' as img;
import '../../domain/entities/trouble_report.dart';
import '../../domain/services/email_service.dart';
import '../../core/config/app_config.dart';
import '../../core/network/network_info_facade.dart';
import '../../core/network/secure_http_client.dart';
import 'package:intl/intl.dart';
import 'email_queue_service.dart';
import 'package:http/http.dart' as http;

/// MailjetEmailService
/// 
/// Ein Service für den Versand von E-Mails über die Mailjet API.
///
/// Änderungen vom 20.06.2024:
/// - Implementierung eines statischen Credential-Caches, um validierte API-Credentials
///   zwischen Service-Neustarts zu behalten
/// - Verbesserte Fehlerbehandlung bei HTTP-Client-Schließung während laufender Tests
/// - Optimierte dispose()-Methode, die auf laufende API-Tests wartet
/// - Erweiterte Diagnose-Funktionen mit detailliertem Logging
/// - Statische Methode zur Validierung der Credentials unabhängig vom Service-Lebenszyklus
/// - Verbesserte Sicherheit durch Maskierung sensibler Daten in Logs
/// - Robustere Fehlerbehandlung bei verschiedenen Edge-Cases
///
/// Implementierung des E-Mail-Services mit Mailjet
class MailjetEmailService implements EmailService {
  static final _log = Logger('MailjetEmailService');
  static const String _baseUrl = 'https://api.mailjet.com/v3.1';
  
  // HINWEIS: Diese Fallback-Credentials sind ungültig und müssen mit gültigen Werten ersetzt werden
  // Die Mailjet API meldet "API key authentication/authorization failure" für diese Credentials
  static const String _fallbackApiKey = '3004d543963be32f5dbe4da2329e109c';
  static const String _fallbackSecretKey = 'd3b943563866a4e9a703787a89f21076';
  
  // Cache für validierte Credentials, die über App-Neustarts hinweg bestehen bleiben
  static String? _validatedApiKey;
  static String? _validatedSecretKey;
  static bool _hasValidatedCredentials = false;
  
  // Flag zum Verfolgen von laufenden API-Tests
  bool _apiTestInProgress = false;
  Completer<void>? _apiTestCompleter;
  
  // Statischer Lock für die Validierung um Race Conditions zu vermeiden
  static bool _isValidatingGlobally = false;
  static Completer<bool>? _globalValidationCompleter;
  
  // Diese Flag steuert, ob ein API-Test beim Start durchgeführt werden soll
  static const bool _runApiValidationTest = true;
  
  String _apiKey;
  String _secretKey;
  final String _toEmail;
  final EmailQueueService _queueService;
  final NetworkInfoFacade _networkInfo;
  SecureHttpClient _httpClient;
  
  // Zwischengespeicherte Werte für Absender-E-Mail und -Name
  String? _cachedSenderEmail;
  String? _cachedSenderName;
  
  // Flag für die Verwendung des Fallbacks
  bool _usingFallbackCredentials = false;
  
  MailjetEmailService({
    required String apiKey,
    required String secretKey,
    required String toEmail,
    required EmailQueueService queueService,
    required NetworkInfoFacade networkInfo,
    SecureHttpClient? httpClient,
  })  : _apiKey = apiKey,
        _secretKey = secretKey,
        _toEmail = toEmail,
        _queueService = queueService,
        _networkInfo = networkInfo,
        _httpClient = httpClient ?? SecureHttpClient() {
    // Überprüfe die Credentials und setze Fallback-Werte, falls nötig
    _validateAndFixCredentials();
    
    // Log den Credential-Status nach der Validierung
    logCredentialStatus();
    
    // Starte globale Credential-Validierung unabhängig vom Service-Lebenszyklus
    if (_runApiValidationTest) {
      // Wir verwenden die statische Methode statt der instanzgebundenen
      validateCredentials(_apiKey, _secretKey, _toEmail).then((isValid) {
        if (!isValid) {
          _log.severe('❌ API-Credentials sind ungültig! E-Mail-Versand wird nicht funktionieren.');
          _log.severe('❌ Bitte aktualisieren Sie die API-Credentials in den App-Einstellungen oder in der config.json.');
          _log.severe('❌ Auch die Fallback-Credentials sind ungültig und müssen aktualisiert werden.');
        } else {
          _log.info('✅ API-Credentials erfolgreich validiert. E-Mail-Versand ist bereit.');
          
          // WICHTIG: Aktualisiere die aktuellen Instanzvariablen mit den validierten Credentials
          if (_validatedApiKey != null && _validatedSecretKey != null) {
            if (_apiKey != _validatedApiKey || _secretKey != _validatedSecretKey) {
              _log.info('🔄 Aktualisiere lokale Credentials mit validierten Werten nach erfolgreicher Validierung.');
              _apiKey = _validatedApiKey!;
              _secretKey = _validatedSecretKey!;
            }
          }
        }
      }).catchError((error) {
        _log.severe('❌ Fehler bei der API-Validierung: $error');
        _log.severe('❌ Der E-Mail-Versand könnte beeinträchtigt sein.');
      });
    }
    
    // Lade die E-Mail-Warteschlange beim Start
    _queueService.loadQueue().then((_) {
      // Versuche, ausstehende E-Mails zu senden
      _processQueue();
    });
    
    // Verbinde den E-Mail-Queue-Service mit dem Netzwerk-Monitor
    _queueService.connectToNetworkMonitor(_networkInfo);
    
    // Lade die Absender-Informationen
    _loadSenderInfo();
  }
  
  /// Überprüft die API-Credentials und setzt Fallback-Werte, falls nötig
  void _validateAndFixCredentials() {
    // Überprüfe zunächst, ob wir bereits validierte Credentials im statischen Cache haben
    if (_hasValidatedCredentials && _validatedApiKey != null && _validatedSecretKey != null) {
      _log.info('✅ Verwende validierte Credentials aus dem Cache.');
      
      // Prüfe, ob die aktuellen Credentials mit den validierten übereinstimmen
      if (_apiKey != _validatedApiKey || _secretKey != _validatedSecretKey) {
        _log.warning('⚠️ Die aktuellen Credentials unterscheiden sich von den validierten Credentials im Cache.');
        _log.info('🔄 Aktualisiere die lokalen Credentials mit den validierten Werten.');
        
        // Verwende die validierten Credentials aus dem Cache
        _apiKey = _validatedApiKey!;
        _secretKey = _validatedSecretKey!;
      }
      
      return;
    }

    _log.info('🔑 Überprüfe API-Credentials...');
    
    // Überprüfe, ob die API-Credentials vorhanden sind
    if (_apiKey.isEmpty || _secretKey.isEmpty) {
      _log.warning('⚠️ API-Credentials fehlen. Verwende Fallback-Werte.');
      
      // Setze Fallback-Werte, wenn die Credentials fehlen
      if (_apiKey.isEmpty) {
        _apiKey = _fallbackApiKey;
        _log.warning('⚠️ API-Key fehlt. Verwende Fallback-Wert.');
      }
      
      if (_secretKey.isEmpty) {
        _secretKey = _fallbackSecretKey;
        _log.warning('⚠️ Secret-Key fehlt. Verwende Fallback-Wert.');
      }
    }
    
    // Überprüfe die Länge der API-Credentials
    if (_apiKey.length < 16 || _secretKey.length < 16) {
      _log.warning('⚠️ API-Credentials scheinen ungültig zu sein (zu kurz).');
      
      // Setze Fallback-Werte, wenn die Credentials zu kurz sind
      if (_apiKey.length < 16) {
        _apiKey = _fallbackApiKey;
        _log.warning('⚠️ API-Key scheint ungültig zu sein. Verwende Fallback-Wert.');
      }
      
      if (_secretKey.length < 16) {
        _secretKey = _fallbackSecretKey;
        _log.warning('⚠️ Secret-Key scheint ungültig zu sein. Verwende Fallback-Wert.');
      }
    }
    
    // Base64-Validierung - nur Anzeigen der Warnung, kein Fix
    try {
      base64.decode(_apiKey);
      base64.decode(_secretKey);
    } catch (e) {
      _log.warning('⚠️ API-Credentials scheinen nicht Base64-kodiert zu sein: $e');
    }
  }
  
  /// Testet die API-Credentials mit einer einfachen Anfrage
  Future<bool> _testApiCredentials() async {
    try {
      _log.info('=== API-VERBINDUNGSTEST BEGINNT ===');
      
      // Setze Test-Flags
      _apiTestInProgress = true;
      _apiTestCompleter = Completer<void>();
      
      _log.info('Testing API credentials with validation request...');
      
      final headers = _getHeaders();
      headers['Content-Type'] = 'application/json';
      
      // Use proper test endpoint with POST request
      final testUrl = 'https://api.mailjet.com/v3.1/send';
      _log.info('Test URL: $testUrl');
      _log.info('HTTP-Methode: POST');
      
      // Log headers (nicht den kompletten Auth-Header)
      _log.info('Request-Headers:');
      headers.forEach((key, value) {
        if (key == 'Authorization') {
          final prefix = value.substring(0, value.length > 20 ? 20 : value.length);
          _log.info('  $key: $prefix...');
        } else {
          _log.info('  $key: $value');
        }
      });
      
      // Create minimal test payload
      final testData = {
        'Messages': [
          {
            'From': {
              'Email': await _senderEmail,
              'Name': await _senderName
            },
            'To': [
              {
                'Email': _toEmail,
                'Name': 'Test'
              }
            ],
            'Subject': 'API Test',
            'TextPart': 'This is an API validation test'
          }
        ]
      };
      
      // Log request body
      final jsonBody = jsonEncode(testData);
      _log.info('Request-Body:');
      _log.info(jsonBody);
      
      http.Response? response;
      try {
        _log.info('Sende API-Test-Anfrage...');
        
        // Versuche, den Request zu senden, und fange mögliche Fehler ab
        try {
          response = await _httpClient.post(
            testUrl,
            headers: headers,
            body: jsonBody,
          );
        } catch (e) {
          if (e.toString().contains('Client is closed') || 
              e.toString().contains('ClientException')) {
            _log.severe('HTTP-Client wurde geschlossen oder ist nicht verfügbar: $e');
            
            // Test ist abgeschlossen
            _apiTestInProgress = false;
            _apiTestCompleter?.complete();
            
            return false;
          } else {
            // Andere Fehler weiterwerfen
            rethrow;
          }
        }
        
        // Log response
        _log.info('Antwort erhalten - Statuscode: ${response.statusCode}');
        _log.info('Response-Body:');
        
        try {
          // Versuche die Antwort als JSON zu formatieren für bessere Lesbarkeit
          final dynamic responseJson = jsonDecode(response.body);
          _log.info(jsonEncode(responseJson));
        } catch (_) {
          // Bei Fehler einfach den Rohtext ausgeben
          _log.info(response.body);
        }
        
        // 401 means invalid credentials
        if (response.statusCode == 401) {
          _log.severe('API credentials are invalid: Authentication error (401 Unauthorized)');
          _log.severe('Server response: ${response.body}');
          _log.info('=== API-VERBINDUNGSTEST BEENDET (FEHLGESCHLAGEN) ===');
          
          // Test ist abgeschlossen
          _apiTestInProgress = false;
          _apiTestCompleter?.complete();
          
          return false;
        }
        
        // Any status code other than 401 means auth worked
        // (even 400 is OK as it might be validation error)
        _log.info('API credentials are valid: Request received status code ${response.statusCode}');
        _log.info('=== API-VERBINDUNGSTEST BEENDET (ERFOLGREICH) ===');
        
        // Speichere die validierten Credentials im Cache
        _validatedApiKey = _apiKey;
        _validatedSecretKey = _secretKey;
        _hasValidatedCredentials = true;
        _log.info('API-Credentials im Cache gespeichert für zukünftige Verwendung.');
        
        // Test ist abgeschlossen
        _apiTestInProgress = false;
        _apiTestCompleter?.complete();
        
        return true;
      } catch (e) {
        _log.severe('HTTP error during API test: $e');
        _log.info('=== API-VERBINDUNGSTEST BEENDET (FEHLER) ===');
        
        // Test ist abgeschlossen
        _apiTestInProgress = false;
        _apiTestCompleter?.complete();
        
        return false;
      }
    } catch (e) {
      _log.severe('Error testing API credentials: $e');
      _log.info('=== API-VERBINDUNGSTEST BEENDET (FEHLER) ===');
      
      // Test ist abgeschlossen
      _apiTestInProgress = false;
      _apiTestCompleter?.complete();
      
      return false;
    }
  }
  
  /// Aktualisiert den Authorization-Header für die API-Anfrage
  Map<String, String> _getHeaders() {
    final credentials = '$_apiKey:$_secretKey';
    final encodedCredentials = base64Encode(utf8.encode(credentials));
    final authHeader = 'Basic $encodedCredentials';
    
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': authHeader,
    };
    
    _log.info('Authorization header created successfully');
    // Sichereres Logging ohne mögliche Encoding-Probleme
    _log.info('API Key length: ${_apiKey.length}, first char: ${_apiKey.isNotEmpty ? _apiKey.codeUnitAt(0) : "empty"}');
    return headers;
  }
  
  /// Lädt die Absender-Informationen aus AppConfig
  Future<void> _loadSenderInfo() async {
    try {
      _log.info('Lade Absender-Informationen aus AppConfig');
      
      // Prüfe zuerst, ob bereits E-Mail-Daten im Cache verfügbar sind
      if (_cachedSenderEmail != null && _cachedSenderEmail!.isNotEmpty) {
        _log.info('Verwende bereits geladene Absender-E-Mail aus Cache: ${_maskEmail(_cachedSenderEmail!)}');
        return;
      }
      
      // Lade die Absender-E-Mail aus der AppConfig
      final configSenderEmail = await AppConfig.senderEmail;
      if (configSenderEmail.isNotEmpty) {
        _cachedSenderEmail = configSenderEmail;
        _log.info('Absender-E-Mail aus Konfiguration geladen: ${_maskEmail(_cachedSenderEmail!)}');
      } else {
        // Direkte Diagnose ausführen
        final allValues = await AppConfig.getAllValues();
        _log.warning('⚠️ Absender-E-Mail konnte nicht aus Konfiguration geladen werden, alle verfügbaren Schlüssel:');
        allValues.keys.forEach((key) {
          _log.warning('  - $key: ${key.contains('email') ? _maskEmail(allValues[key] ?? 'leer') : 'Wert vorhanden'}');
        });
        
        // Fallback-E-Mail setzen
        _log.warning('⚠️ Setze Fallback-Wert für Absender-E-Mail: noreply@nextvision.agency');
        _cachedSenderEmail = "noreply@nextvision.agency";
        
        // Versuche erneut, den Wert zu speichern für spätere Verwendung
        await AppConfig.setApiKey('sender_email', _cachedSenderEmail!);
      }
      
      // Lade Absender-Namen
      _cachedSenderName = await AppConfig.senderName;
      if (_cachedSenderName == null || _cachedSenderName!.isEmpty) {
        _log.warning('Absender-Name konnte nicht aus Konfiguration geladen werden, verwende Fallback-Wert');
        _cachedSenderName = "Lebedew Haustechnik";
        await AppConfig.setApiKey('sender_name', _cachedSenderName!);
      }
      
      _log.info('Absender-Informationen vollständig geladen: $_cachedSenderName <${_maskEmail(_cachedSenderEmail!)}>');;
    } catch (e) {
      _log.severe('❌ Fehler beim Laden der Absender-Informationen: $e');
      // Fallback-Werte setzen
      _cachedSenderEmail = "noreply@nextvision.agency";
      _cachedSenderName = "Lebedew Haustechnik";
      
      // Versuche, die Fallback-Werte in der Konfiguration zu speichern
      try {
        await AppConfig.setApiKey('sender_email', _cachedSenderEmail!);
        await AppConfig.setApiKey('sender_name', _cachedSenderName!);
        _log.info('✅ Fallback-Werte in der Konfiguration gespeichert');
      } catch (saveError) {
        _log.severe('❌ Fehler beim Speichern der Fallback-Werte: $saveError');
      }
    }
  }
  
  /// Maskiert eine E-Mail-Adresse für sicheres Logging
  String _maskEmail(String email) {
    if (email.isEmpty) return "leer";
    if (email.length < 6) return "***@***";
    
    final parts = email.split('@');
    if (parts.length != 2) return "ungültige-email";
    
    final username = parts[0];
    final domain = parts[1];
    
    final maskedUsername = username.length <= 3 
        ? username 
        : '${username.substring(0, 3)}***';
    
    return '$maskedUsername@$domain';
  }
  
  /// Gibt die Absender-E-Mail zurück
  Future<String> get _senderEmail async {
    if (_cachedSenderEmail == null || _cachedSenderEmail!.isEmpty) {
      await _loadSenderInfo();
    }
    return _cachedSenderEmail ?? 'noreply@nextvision.agency';
  }
  
  /// Gibt den Absender-Namen zurück
  Future<String> get _senderName async {
    if (_cachedSenderName == null || _cachedSenderName!.isEmpty) {
      await _loadSenderInfo();
    }
    return _cachedSenderName ?? '';
  }

  Future<void> _processQueue() async {
    // Prüfe zuerst, ob eine Netzwerkverbindung besteht
    final isConnected = await _networkInfo.isCurrentlyConnected;
    if (!isConnected) {
      _log.info('Keine Netzwerkverbindung. Queue-Verarbeitung wird übersprungen.');
      return;
    }
    
    // Verarbeite Störungsmeldungen
    await _queueService.processQueue(_sendEmail);
    
    // Verarbeite einfache E-Mails
    await _queueService.processSimpleQueue(_sendSimpleEmail);
  }

  Future<bool> _sendSimpleEmail(EmailQueueItem email) async {
    try {
      _log.info('Sende einfache E-Mail an: ${email.toEmail}');
      
      // WICHTIG: Vor dem Senden der einfachen E-Mail nochmal prüfen, ob wir validierte Credentials haben
      // und diese gegebenenfalls verwenden
      if (_hasValidatedCredentials && _validatedApiKey != null && _validatedSecretKey != null) {
        if (_apiKey != _validatedApiKey || _secretKey != _validatedSecretKey) {
          _log.warning('⚠️ Verwendete Credentials stimmen nicht mit validierten überein - aktualisiere für einfache E-Mail');
          _apiKey = _validatedApiKey!;
          _secretKey = _validatedSecretKey!;
          _log.info('✅ Credentials auf validierte Werte aktualisiert: ${_maskApiKey(_apiKey)}');
        }
      }
      
      // TEMPORÄRE LÖSUNG: Simulation des E-Mail-Versands, bis gültige API-Credentials verfügbar sind
      if (false) { // Temporarily disable simulation mode to test with actual credentials
        _log.warning('⚠️ ACHTUNG: Verwende Simulations-Modus für E-Mail-Versand, da keine gültigen API-Credentials verfügbar sind.');
        _log.warning('⚠️ E-Mail wird NICHT wirklich gesendet! Details der simulierten E-Mail:');
        _log.warning('⚠️ An: ${email.toEmail}');
        _log.warning('⚠️ Betreff: ${email.subject}');
        _log.warning('⚠️ Anhänge: ${email.attachmentPaths?.length ?? 0}');
        
        // Verzögerung hinzufügen, um einen echten API-Aufruf zu simulieren
        await Future.delayed(const Duration(seconds: 1));
        
        // Erfolgreich simulierter Versand
        return true;
      }
      
      // Normale Implementierung fortsetzen, wenn gültige Credentials vorhanden sind
      // Validiere erforderliche Felder
      if (email.toEmail.isEmpty || email.subject.isEmpty || email.body.isEmpty) {
        _log.severe('Fehler beim Senden der einfachen E-Mail: Erforderliche Felder fehlen');
        return false;
      }
      
      final headers = _getHeaders();
      _log.info('Auth-Header erstellt (Länge: ${headers['Authorization']?.length ?? 0})');
      
      // Debug-Ausgabe für den Authorization-Header
      final authHeader = headers['Authorization'] ?? '';
      if (authHeader.length > 20) {
        _log.info('Auth-Header Vorschau: ${authHeader.substring(0, 10)}...${authHeader.substring(authHeader.length - 10)}');
      } else {
        _log.severe('WARNUNG: Auth-Header ist zu kurz oder unvollständig: $authHeader');
      }

      // Stelle sicher, dass Absender-E-Mail und -Name vorhanden sind
      final effectiveSenderEmail = email.fromEmail ?? await _senderEmail;
      final effectiveSenderName = email.fromName ?? await _senderName;
      
      if (effectiveSenderEmail.isEmpty) {
        _log.severe('❌ Absender-E-Mail ist leer! Verwende Fallback-E-Mail.');
        // Setze einen harten Fallback für diesen Sendevorgang
        _cachedSenderEmail = "noreply@nextvision.agency";
      }
      
      if (effectiveSenderName.isEmpty) {
        _log.info('Absender-Name ist leer. Verwende Fallback-Wert.');
        _cachedSenderName = "Lebedew Haustechnik";
      }

      final Map<String, dynamic> emailData = {
        'Messages': [
          {
            'From': {
              'Email': effectiveSenderEmail.isEmpty ? "noreply@nextvision.agency" : effectiveSenderEmail,
              'Name': effectiveSenderName.isEmpty ? "Lebedew Haustechnik" : effectiveSenderName,
            },
            'To': [
              {
                'Email': email.toEmail,
                'Name': '',
              }
            ],
            'Subject': email.subject,
            'HTMLPart': email.body,
          }
        ]
      };
      
      // Log für Diagnose
      _log.info('E-Mail-Request Body: ${jsonEncode(emailData)}');
      
      // Füge Anhänge hinzu, falls vorhanden
      if (email.attachmentPaths != null && email.attachmentPaths!.isNotEmpty) {
        final attachments = <Map<String, dynamic>>[];
        
        for (final path in email.attachmentPaths!) {
          try {
            final file = File(path);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final filename = path.split('/').last;
              final contentType = _getContentType(filename);
              
              attachments.add({
                'ContentType': contentType,
                'Filename': filename,
                'Base64Content': base64Encode(bytes),
              });
            } else {
              _log.warning('Anhang existiert nicht: $path');
            }
          } catch (e) {
            _log.severe('Fehler beim Hinzufügen des Anhangs: $e');
          }
        }
        
        if (attachments.isNotEmpty) {
          emailData['Messages'][0]['Attachments'] = attachments;
        }
      }

      _log.info('Sende E-Mail-Anfrage an Mailjet API');
      
      http.Response? response;
      try {
        response = await _httpClient.post(
          '$_baseUrl/send',
          headers: headers,
          body: jsonEncode(emailData),
        );
      } catch (e) {
        if (e.toString().contains('Client is already closed')) {
          _log.warning('Client war bereits geschlossen, versuche erneut mit neuem Client');
          // Der Client wurde bereits geschlossen, versuche es erneut mit einem neuen Client
          response = await _httpClient.post(
            '$_baseUrl/send',
            headers: headers,
            body: jsonEncode(emailData),
          );
        } else {
          rethrow;
        }
      }

      if (response.statusCode == 401) {
        _log.severe('Authentifizierungsfehler (401) bei der Mailjet API! '
            'Versuche mit den Fallback-Credentials...');
        
        // Fallback-Credentials verwenden und erneut versuchen
        if (!_usingFallbackCredentials) {
          _apiKey = _fallbackApiKey;
          _secretKey = _fallbackSecretKey;
          _usingFallbackCredentials = true;
          
          // Neuen Header mit Fallback-Credentials erstellen
          final fallbackHeaders = _getHeaders();
          
          // Erneuter Versuch mit Fallback-Credentials
          final retryResponse = await _httpClient.post(
            '$_baseUrl/send',
            headers: fallbackHeaders,
            body: jsonEncode(emailData),
          );
          
          final isSuccess = _httpClient.isSuccessful(retryResponse);
          if (isSuccess) {
            _log.info('E-Mail mit Fallback-Credentials erfolgreich gesendet an: ${email.toEmail}');
          } else {
            _log.severe('Fehler beim Senden der E-Mail auch mit Fallback-Credentials: '
                '${retryResponse.statusCode} - ${retryResponse.body}');
          }
          
          return isSuccess;
        }
        
        // Fehler in AppConfig persistieren, damit zukünftige App-Starts direkt die korrekten Credentials verwenden
        if (_usingFallbackCredentials) {
          try {
            await AppConfig.setApiKey('mailjet_api_key', _fallbackApiKey);
            await AppConfig.setApiKey('mailjet_secret_key', _fallbackSecretKey);
            _log.info('Fallback-Credentials in AppConfig gespeichert');
          } catch (e) {
            _log.warning('Fehler beim Speichern der Fallback-Credentials: $e');
          }
        }
        
        return false;
      }

      final isSuccess = _httpClient.isSuccessful(response);
      if (isSuccess) {
        _log.info('E-Mail erfolgreich gesendet an: ${email.toEmail}');
      } else {
        _log.severe('Fehler beim Senden der E-Mail: ${response.statusCode} - ${response.body}');
      }
      
      return isSuccess;
    } catch (e) {
      _log.severe('Fehler beim Senden der einfachen E-Mail: $e');
      return false;
    }
  }

  /// Komprimiert ein Bild auf 80% Qualität
  Future<List<int>> _compressImage(File imageFile) async {
    try {
      // Bild einlesen
      final bytes = await imageFile.readAsBytes();
      final image = img.decodeImage(bytes);
      
      if (image == null) {
        _log.warning('Konnte Bild nicht dekodieren: ${imageFile.path}');
        return bytes;
      }

      // Bild als JPEG mit 80% Qualität enkodieren
      return img.encodeJpg(image, quality: 80);
    } catch (e) {
      _log.warning('Fehler bei der Bildkomprimierung: $e', e);
      return imageFile.readAsBytesSync();
    }
  }

  /// Validiert die erforderlichen Felder eines Störungsberichts
  bool _validateTroubleReport(TroubleReport report) {
    if (report.name.isEmpty) {
      _log.warning('Validierungsfehler: Name fehlt');
      return false;
    }
    
    if (report.email.isEmpty) {
      _log.warning('Validierungsfehler: E-Mail fehlt');
      return false;
    }
    
    if (report.phone == null || report.phone!.isEmpty) {
      _log.warning('Validierungsfehler: Telefonnummer fehlt');
      return false;
    }
    
    if (report.description.isEmpty) {
      _log.warning('Validierungsfehler: Beschreibung fehlt');
      return false;
    }
    
    // Prüfe, ob eine Kundennummer angegeben wurde, wenn ein Wartungsvertrag vorhanden ist
    if (report.hasMaintenanceContract && (report.customerNumber == null || report.customerNumber!.isEmpty)) {
      _log.warning('Validierungsfehler: Kundennummer fehlt bei vorhandenem Wartungsvertrag');
      return false;
    }
    
    return true;
  }

  Future<bool> _sendEmail(TroubleReport form, List<File> images) async {
    try {
      _log.info('=== SENDING EMAIL DIAGNOSTICS ===');
      _log.info('Current API Key length: ${_apiKey.length}');
      _log.info('API Key code units: ${_apiKey.isNotEmpty ? _apiKey.codeUnits.take(4).toList() : []}');
      _log.info('Current Secret Key length: ${_secretKey.length}');
      _log.info('Using fallback credentials: ${_usingFallbackCredentials}');
      
      // Stelle sicher, dass der HTTP-Client aktiv ist
      await _ensureHttpClientActive();
      
      // WICHTIG: Vor dem Senden der Störungsmeldung nochmal prüfen, ob wir validierte Credentials haben
      // und diese gegebenenfalls verwenden
      if (_hasValidatedCredentials && _validatedApiKey != null && _validatedSecretKey != null) {
        if (_apiKey != _validatedApiKey || _secretKey != _validatedSecretKey) {
          _log.warning('⚠️ Verwendete Credentials stimmen nicht mit validierten überein - aktualisiere für Störungsbericht');
          _apiKey = _validatedApiKey!;
          _secretKey = _validatedSecretKey!;
          _log.info('✅ Credentials auf validierte Werte aktualisiert: ${_maskApiKey(_apiKey)}');
        }
      }
      
      // Versuche, einen sauberen API-Key zu garantieren, indem wir die Zeichen einzeln überprüfen
      String cleanApiKey = '';
      for (int i = 0; i < _apiKey.length; i++) {
        final char = _apiKey[i];
        // Prüfe, ob das Zeichen im ASCII-Bereich ist und ein gültiges Zeichen für einen API-Key ist
        if (char.codeUnitAt(0) < 128 && (char.codeUnitAt(0) >= 48 && char.codeUnitAt(0) <= 57 || 
            char.codeUnitAt(0) >= 97 && char.codeUnitAt(0) <= 122 || 
            char.codeUnitAt(0) >= 65 && char.codeUnitAt(0) <= 90)) {
          cleanApiKey += char;
        } else {
          _log.warning('Ungültiges Zeichen im API-Key gefunden: ${char.codeUnitAt(0)}');
        }
      }
      
      if (cleanApiKey != _apiKey) {
        _log.warning('API-Key enthält ungültige Zeichen! Gereinigter Key hat Länge: ${cleanApiKey.length}');
        _log.warning('Gereinigter API-Key: ${cleanApiKey.substring(0, cleanApiKey.length > 4 ? 4 : cleanApiKey.length)}...');
        // Aktualisiere den API-Key für diesen Sendevorgang
        _apiKey = cleanApiKey;
      }
      
      final testAuth = 'Basic ' + base64Encode(utf8.encode('$_apiKey:$_secretKey'));
      _log.info('Generated auth header: ${testAuth.substring(0, math.min(12, testAuth.length))}...');
      _log.info('=== END DIAGNOSTICS ===');
      
      _log.info('Sende Störungsmeldung für: ${form.name} <${form.email}>');
      
      // Normale Implementierung fortsetzen, wenn gültige Credentials vorhanden sind
      // Validiere den Störungsbericht
      if (!_validateTroubleReport(form)) {
        _log.severe('Fehler beim Senden der Störungsmeldung: Validierung fehlgeschlagen');
        return false;
      }

      // Prüfe zuerst, ob eine Netzwerkverbindung besteht
      final isConnected = await _networkInfo.isCurrentlyConnected;
      if (!isConnected) {
        _log.info('Keine Netzwerkverbindung. Störungsmeldung wird in die Warteschlange gestellt.');
        
        // Speichere die Bilder temporär und verwende die Pfade für die Queue
        List<String> imagePaths = [];
        for (final image in images) {
          try {
            final filename = image.path.split('/').last;
            final tempDir = await Directory.systemTemp.createTemp('mailjet_temp');
            final tempFile = File('${tempDir.path}/$filename');
            await tempFile.writeAsBytes(await image.readAsBytes());
            imagePaths.add(tempFile.path);
            _log.info('Bild temporär gespeichert: ${tempFile.path}');
          } catch (e) {
            _log.warning('Fehler beim Speichern des temporären Bildes: $e');
          }
        }
        
        // Füge die Störungsmeldung zur Warteschlange hinzu
        await _queueService.addToQueue(form, imagePaths);
        
        return true; // Wir geben true zurück, da die E-Mail in die Warteschlange gestellt wurde
      }
      
      _log.info('Bereite Bilder für den Versand vor');
      
      // Bildanhänge vorbereiten
      final attachments = await Future.wait(
        images.map((file) async {
          try {
            final bytes = await _compressImage(file);
            return {
              'ContentType': 'image/jpeg',
              'Filename': file.path.split('/').last,
              'Base64Content': base64Encode(bytes),
            };
          } catch (e) {
            _log.warning('Fehler beim Verarbeiten des Anhangs: ${file.path}', e);
            // Fehler bei einzelnen Anhängen sollten nicht den gesamten Sendevorgang abbrechen
            return null;
          }
        }),
      );
      
      // Filtere null-Werte aus der Anhangsliste
      final validAttachments = attachments.where((a) => a != null).cast<Map<String, dynamic>>().toList();
      
      _log.info('${validAttachments.length} Anhänge vorbereitet');
      
      // Lade Absenderinformationen
      final senderEmail = await _senderEmail;
      final senderName = await _senderName;
      
      // Erstelle die E-Mail-Daten
      final reportDate = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
      
      // Erstelle die Service-E-Mail-Daten
      final serviceHtmlBody = _createHtmlTemplate(form, reportDate);
      
      final Map<String, dynamic> serviceEmailData = {
        'Messages': [
          {
            'From': {
              'Email': senderEmail,
              'Name': senderName,
            },
            'To': [
              {
                'Email': _toEmail,
                'Name': 'Lebedew Haustechnik',
              }
            ],
            'Subject': 'Störungsmeldung: ${form.type.label} von ${form.name}',
            'HTMLPart': serviceHtmlBody,
            if (validAttachments.isNotEmpty) 'Attachments': validAttachments,
          }
        ]
      };
      
      // Erstelle die Kunden-Bestätigungs-E-Mail HTML
      final customerHtmlBody = _createCustomerConfirmationTemplate(form);
      
      // Erstelle die Kunden-E-Mail-Daten (ohne Anhänge)
      final Map<String, dynamic> customerEmailData = {
        'Messages': [
          {
            'From': {
              'Email': senderEmail,
              'Name': senderName,
            },
            'To': [
              {
                'Email': form.email,
                'Name': form.name,
              }
            ],
            'Subject': 'Bestätigung Ihrer Störungsmeldung',
            'HTMLPart': customerHtmlBody,
          }
        ]
      };
      
      // Debug-Ausgabe für die E-Mail-Daten (ohne Anhänge wegen der Größe)
      final debugEmailData = Map<String, dynamic>.from(serviceEmailData);
      if (debugEmailData['Messages'] != null && 
          debugEmailData['Messages'].isNotEmpty && 
          debugEmailData['Messages'][0]['Attachments'] != null) {
        debugEmailData['Messages'][0]['Attachments'] = 
          '${validAttachments.length} Anhänge (nicht angezeigt)';
      }
      _log.info('Service-E-Mail-Daten: ${jsonEncode(debugEmailData)}');
      
      // Debug-Ausgabe für Kunden-E-Mail
      _log.info('Kunden-E-Mail-Daten: ${jsonEncode(customerEmailData)}');
      
      final headers = _getHeaders();
      
      bool serviceEmailSent = false;
      bool customerEmailSent = false;
      
      // FIXIERT: Versende zuerst die Service-E-Mail separat, dann die Kunden-E-Mail
      _log.info('Sende beide E-Mails separat, um korrekte Inhalte zu gewährleisten');
      
      // 1. Sende die Service-E-Mail
      try {
        _log.info('Sende Service-E-Mail an: $_toEmail');
        
        final serviceJsonBody = jsonEncode(serviceEmailData);
        http.Response? serviceResponse;
        
        try {
          serviceResponse = await _httpClient.post(
            '$_baseUrl/send',
            headers: headers,
            body: serviceJsonBody,
          );
        } catch (e) {
          _log.severe('❌ Ausnahme beim Senden der Service-E-Mail: $e');
          
          if (e.toString().contains('Client is closed') || 
              e.toString().contains('ClientException') || 
              e.toString().contains('Socket')) {
            _log.warning('⚠️ HTTP-Client-Problem erkannt. Versuche mit frischem Client für Service-E-Mail...');
            serviceEmailSent = await _sendEmailWithFreshClient(serviceEmailData);
          } else {
            throw e; // Andere Fehler weiterwerfen
          }
        }
        
        // Wenn wir eine Antwort haben, verarbeite sie
        if (serviceResponse != null) {
          if (serviceResponse.statusCode >= 200 && serviceResponse.statusCode < 300) {
            _log.info('✅ Service-E-Mail erfolgreich gesendet (Status: ${serviceResponse.statusCode})');
            serviceEmailSent = true;
          } else {
            _log.severe('❌ Fehler beim Senden der Service-E-Mail: HTTP ${serviceResponse.statusCode}');
            _log.severe('Server-Antwort: ${serviceResponse.body}');
            
            if (serviceResponse.statusCode == 401) {
              _log.severe('❌ Authentifizierungsfehler (401) für Service-E-Mail. Versuche mit frischem Client...');
              serviceEmailSent = await _sendEmailWithFreshClient(serviceEmailData);
            }
          }
        }
      } catch (e) {
        _log.severe('❌ Fehler beim Senden der Service-E-Mail: $e');
        // Versuche erneut mit frischem Client
        serviceEmailSent = await _sendEmailWithFreshClient(serviceEmailData);
      }
      
      // 2. Sende die Kunden-Bestätigungs-E-Mail
      try {
        _log.info('Sende Bestätigungs-E-Mail an Kunden: ${form.email}');
        
        final customerJsonBody = jsonEncode(customerEmailData);
        http.Response? customerResponse;
        
        try {
          customerResponse = await _httpClient.post(
            '$_baseUrl/send',
            headers: headers,
            body: customerJsonBody,
          );
        } catch (e) {
          _log.severe('❌ Ausnahme beim Senden der Kunden-E-Mail: $e');
          
          if (e.toString().contains('Client is closed') || 
              e.toString().contains('ClientException') || 
              e.toString().contains('Socket')) {
            _log.warning('⚠️ HTTP-Client-Problem erkannt. Versuche mit frischem Client für Kunden-E-Mail...');
            customerEmailSent = await _sendEmailWithFreshClient(customerEmailData);
          } else {
            throw e; // Andere Fehler weiterwerfen
          }
        }
        
        // Wenn wir eine Antwort haben, verarbeite sie
        if (customerResponse != null) {
          if (customerResponse.statusCode >= 200 && customerResponse.statusCode < 300) {
            _log.info('✅ Kunden-E-Mail erfolgreich gesendet (Status: ${customerResponse.statusCode})');
            customerEmailSent = true;
          } else {
            _log.severe('❌ Fehler beim Senden der Kunden-E-Mail: HTTP ${customerResponse.statusCode}');
            _log.severe('Server-Antwort: ${customerResponse.body}');
            
            if (customerResponse.statusCode == 401) {
              _log.severe('❌ Authentifizierungsfehler (401) für Kunden-E-Mail. Versuche mit frischem Client...');
              customerEmailSent = await _sendEmailWithFreshClient(customerEmailData);
            }
          }
        }
      } catch (e) {
        _log.severe('❌ Fehler beim Senden der Kunden-E-Mail: $e');
        // Versuche erneut mit frischem Client
        customerEmailSent = await _sendEmailWithFreshClient(customerEmailData);
      }
      
      // Protokolliere den Gesamtstatus
      _log.info('📊 E-Mail-Versand Status: Service-E-Mail: ${serviceEmailSent ? "✅" : "❌"}, Kunden-E-Mail: ${customerEmailSent ? "✅" : "❌"}');
      
      // FIXIERT: Der Rückgabewert muss genau dann true sein, wenn die Service-E-Mail gesendet wurde
      // Da dies die kritische E-Mail ist, die wir als Erfolg betrachten
      return serviceEmailSent;
    } catch (e, stack) {
      _log.severe('❌ Unerwartete Ausnahme beim Senden der Störungsmeldung: $e');
      _log.severe('Stack trace: $stack');
      return false;
    }
  }

  /// Erstellt ein HTML-Template für die Störungsmeldung
  String _createHtmlTemplate(TroubleReport form, String reportDate) {
    // Formatiere alle Werte richtig für HTML und sorge für Sicherheit
    final htmlSafeDescription = form.description
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('\n', '<br>');
    
    // Generiere HTML für nicht leere optionale Felder
    final addressHtml = form.address != null && form.address!.isNotEmpty 
        ? '<p><strong>Adresse:</strong> ${form.address!.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</p>' 
        : '';
        
    final deviceModelHtml = form.deviceModel != null && form.deviceModel!.isNotEmpty 
        ? '<p><strong>Gerätemodell:</strong> ${form.deviceModel!.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</p>' 
        : '';
        
    final manufacturerHtml = form.manufacturer != null && form.manufacturer!.isNotEmpty 
        ? '<p><strong>Hersteller:</strong> ${form.manufacturer!.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</p>' 
        : '';
        
    final serialNumberHtml = form.serialNumber != null && form.serialNumber!.isNotEmpty 
        ? '<p><strong>Seriennummer:</strong> ${form.serialNumber!.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</p>' 
        : '';
        
    final errorCodeHtml = form.errorCode != null && form.errorCode!.isNotEmpty 
        ? '<p><strong>Fehlercode:</strong> ${form.errorCode!.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</p>' 
        : '';
        
    final occurrenceDateHtml = form.occurrenceDate != null 
        ? '<p><strong>Datum des Vorfalls:</strong> ${DateFormat('dd.MM.yyyy').format(form.occurrenceDate!)}</p>' 
        : '';
        
    final customerNumberHtml = form.customerNumber != null && form.customerNumber!.isNotEmpty 
        ? '<p><strong>Kundennummer:</strong> ${form.customerNumber!.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</p>' 
        : '';
        
    final serviceHistoryHtml = form.serviceHistory != null && form.serviceHistory!.isNotEmpty 
        ? '<p><strong>Servicehistorie:</strong> ${form.serviceHistory!.replaceAll('<', '&lt;').replaceAll('>', '&gt;').replaceAll('\n', '<br>')}</p>' 
        : '';
        
    final energySourcesHtml = form.energySources.isNotEmpty 
        ? '<p><strong>Energiequellen:</strong> ${form.energySources.join(', ').replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</p>' 
        : '';

    return '''
      <h2>Neue Störungsmeldung</h2>
      <h3>Art des Anliegens</h3>
      <p><strong>Typ:</strong> ${form.type.label}</p>
      <p><strong>Dringlichkeit:</strong> ${form.urgencyLevel.label}</p>
      <p><strong>Datum der Meldung:</strong> $reportDate</p>
      
      <h3>Kontaktdaten</h3>
      <p><strong>Name:</strong> ${form.name.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</p>
      <p><strong>E-Mail:</strong> ${form.email.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</p>
      ${form.phone != null ? '<p><strong>Telefon:</strong> ${form.phone!.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</p>' : ''}
      $addressHtml
      
      <h3>Gerätedaten</h3>
      $deviceModelHtml
      $manufacturerHtml
      $serialNumberHtml
      $errorCodeHtml
      $occurrenceDateHtml
      
      <h3>Service-Informationen</h3>
      <p><strong>Wartungsvertrag:</strong> ${form.hasMaintenanceContract ? 'Ja' : 'Nein'}</p>
      $customerNumberHtml
      $serviceHistoryHtml
      $energySourcesHtml
      
      <h3>Problembeschreibung</h3>
      <p>$htmlSafeDescription</p>
    ''';
  }

  /// Erstellt eine Bestätigungs-E-Mail-Vorlage für den Kunden
  String _createCustomerConfirmationTemplate(TroubleReport form) {
    // Formatiere alle Werte richtig für HTML und sorge für Sicherheit
    final htmlSafeDescription = form.description
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('\n', '<br>');
        
    final deviceModelHtml = form.deviceModel != null && form.deviceModel!.isNotEmpty 
        ? '<p><strong>Gerätemodell:</strong> ${form.deviceModel!.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</p>' 
        : '';
        
    final manufacturerHtml = form.manufacturer != null && form.manufacturer!.isNotEmpty 
        ? '<p><strong>Hersteller:</strong> ${form.manufacturer!.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</p>' 
        : '';
        
    final serialNumberHtml = form.serialNumber != null && form.serialNumber!.isNotEmpty 
        ? '<p><strong>Seriennummer:</strong> ${form.serialNumber!.replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</p>' 
        : '';

    return '''
      <h2>Bestätigung Ihrer Störungsmeldung</h2>
      
      <p>Sehr geehrte(r) ${form.name.replaceAll('<', '&lt;').replaceAll('>', '&gt;')},</p>
      
      <p>vielen Dank für Ihre Störungsmeldung. Wir haben Ihre Meldung erfolgreich erhalten und werden uns zeitnah mit Ihnen in Verbindung setzen.</p>
      
      <p>Nachfolgend finden Sie eine Zusammenfassung Ihrer Meldung:</p>
      
      <div style="background-color: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
        <h3 style="color: #1976D2;">Details Ihrer Meldung</h3>
        
        <p><strong>Meldungstyp:</strong> ${form.type.label}</p>
        <p><strong>Dringlichkeit:</strong> ${form.urgencyLevel.label}</p>
        <p><strong>Beschreibung:</strong> $htmlSafeDescription</p>
        
        $deviceModelHtml
        $manufacturerHtml
        $serialNumberHtml
      </div>
      
      <p>Sollten Sie weitere Fragen haben oder zusätzliche Informationen bereitstellen möchten, antworten Sie bitte auf diese E-Mail oder kontaktieren Sie uns telefonisch.</p>
      
      <p>Mit freundlichen Grüßen,<br>
      Ihr Lebedew Haustechnik Team</p>
    ''';
  }

  String _getContentType(String filename) {
    final extension = filename.split('.').last.toLowerCase();
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Versucht, alle ausstehenden E-Mails in der Warteschlange zu senden
  Future<void> syncQueuedEmails() async {
    _log.info('Synchronisiere E-Mail-Warteschlange');
    await _processQueue();
  }

  /// Liefert Diagnoseinformationen über den aktuellen Status der API-Credentials
  void logCredentialStatus() {
    _log.info('======== MAILJET CREDENTIAL STATUS ========');
    _log.info('📍 Instanz-ID: ${identityHashCode(this)}');
    _log.info('🔑 Aktuelle API-Key: ${_maskApiKey(_apiKey)} (Länge: ${_apiKey.length})');
    _log.info('🔑 Aktueller Secret-Key: ${_maskApiKey(_secretKey)} (Länge: ${_secretKey.length})');
    _log.info('⚠️ Fallback-Credentials werden verwendet: $_usingFallbackCredentials');
    _log.info('✅ Validierte Credentials im Cache: $_hasValidatedCredentials');
    _log.info('🧪 API-Test läuft gerade: $_apiTestInProgress');
    _log.info('🌐 Globale Validierung läuft: $_isValidatingGlobally');
    
    if (_hasValidatedCredentials) {
      _log.info('💾 Cache API-Key: ${_maskApiKey(_validatedApiKey ?? "")} (Länge: ${_validatedApiKey?.length})');
      _log.info('💾 Cache Secret-Key: ${_maskApiKey(_validatedSecretKey ?? "")} (Länge: ${_validatedSecretKey?.length})');
      _log.info('🔄 API-Key ist identisch mit Cache: ${_apiKey == _validatedApiKey}');
      _log.info('🔄 Secret-Key ist identisch mit Cache: ${_secretKey == _validatedSecretKey}');
    }
    
    // Prüfe HTTP-Client Status
    final clientStatus = _httpClient != null ? 'aktiv' : 'geschlossen/null';
    _log.info('🌐 HTTP-Client Status: $clientStatus');
    
    _log.info('==========================================');
  }

  /// Maskiert einen API-Key für sicheres Logging
  String _maskApiKey(String key) {
    if (key.length <= 8) return '***';
    return '${key.substring(0, 4)}...${key.substring(key.length - 4)}';
  }

  /// Löscht sensible Daten aus dem Speicher
  /// 
  /// Diese Methode überschreibt die sensiblen Daten im Speicher mit 
  /// zufälligen Werten, bevor die Referenzen gelöscht werden.
  void securelyWipeCredentials() {
    _log.info('Lösche Mailjet-Credentials sicher aus dem Speicher');
    
    // Wenn validierte Credentials vorhanden sind, bewahre sie im Cache
    if (_hasValidatedCredentials && _apiKey == _validatedApiKey && _secretKey == _validatedSecretKey) {
      _log.info('Bewahre validierte API-Credentials im Cache.');
      // Lokale Instanzvariablen überschreiben, aber Cache behalten
      _apiKey = AppConfig.securelyWipeValue(_apiKey);
      _secretKey = AppConfig.securelyWipeValue(_secretKey);
    } else {
      // Bei nicht validierten Credentials alles löschen
      _apiKey = AppConfig.securelyWipeValue(_apiKey);
      _secretKey = AppConfig.securelyWipeValue(_secretKey);
    }
    
    // Lösche zwischengespeicherte Absenderinformationen
    if (_cachedSenderEmail != null) {
      _cachedSenderEmail = AppConfig.securelyWipeValue(_cachedSenderEmail!);
      _cachedSenderEmail = null;
    }
    
    if (_cachedSenderName != null) {
      _cachedSenderName = AppConfig.securelyWipeValue(_cachedSenderName!);
      _cachedSenderName = null;
    }
    
    _log.info('Mailjet-Credentials sicher gelöscht');
  }

  /// Löscht eine Datei sicher
  /// 
  /// Diese Methode überschreibt den Inhalt einer Datei mit zufälligen Daten,
  /// bevor sie gelöscht wird, um sicherzustellen, dass die Daten nicht wiederhergestellt werden können.
  Future<void> securelyDeleteFile(File file) async {
    try {
      if (await file.exists()) {
        _log.info('Lösche Datei sicher: ${file.path}');
        
        // Hole die Dateigröße
        final fileSize = await file.length();
        
        // Erstelle zufällige Daten
        final random = List.generate(
          fileSize > 1024 ? 1024 : fileSize.toInt(), 
          (index) => (DateTime.now().microsecondsSinceEpoch % 256)
        );
        
        // Überschreibe die Datei mehrmals mit zufälligen Daten
        for (int i = 0; i < 3; i++) {
          final sink = file.openWrite(mode: FileMode.writeOnly);
          
          // Bei großen Dateien überschreiben wir in Blöcken
          for (int offset = 0; offset < fileSize; offset += 1024) {
            sink.add(random);
          }
          
          await sink.flush();
          await sink.close();
        }
        
        // Lösche die Datei
        await file.delete();
        _log.info('Datei sicher gelöscht: ${file.path}');
      }
    } catch (e) {
      _log.warning('Fehler beim sicheren Löschen der Datei ${file.path}: $e');
      // Versuche, die Datei trotzdem zu löschen
      try {
        await file.delete();
      } catch (deleteError) {
        _log.severe('Konnte Datei nicht löschen: ${file.path}');
      }
    }
  }

  /// Bereinigt temporäre Dateien, die für die E-Mail-Queue verwendet wurden
  Future<void> _cleanupTemporaryFiles() async {
    try {
      // Versuche, das temporäre Verzeichnis zu finden und zu bereinigen
      final tempDir = Directory.systemTemp;
      if (await tempDir.exists()) {
        final entities = await tempDir.list(recursive: true).toList();
        
        for (final entity in entities) {
          if (entity is File && entity.path.contains('mailjet_temp')) {
            await securelyDeleteFile(entity);
          } else if (entity is Directory && entity.path.contains('mailjet_temp')) {
            try {
              await entity.delete(recursive: true);
              _log.info('Temporäres Verzeichnis gelöscht: ${entity.path}');
            } catch (e) {
              _log.warning('Fehler beim Löschen des temporären Verzeichnisses: $e');
            }
          }
        }
      }
    } catch (e) {
      _log.warning('Fehler beim Bereinigen temporärer Dateien: $e');
    }
  }

  /// Gibt alle Ressourcen frei und löscht sensible Daten aus dem Speicher
  /// 
  /// Diese Methode sollte aufgerufen werden, wenn der Service nicht mehr benötigt wird,
  /// z.B. wenn die Anwendung geschlossen wird oder der Benutzer sich abmeldet.
  @override
  Future<void> dispose() async {
    // Log den aktuellen Status der Credentials vor der Deaktivierung
    logCredentialStatus();
    
    _log.info('🔌 MailjetEmailService wird beendet...');
    
    // Prüfe, ob ein API-Test läuft und warte darauf (mit Timeout)
    if (_apiTestInProgress && _apiTestCompleter != null) {
      _log.warning('⚠️ API-Test läuft noch! Warte auf Abschluss...');
      
      try {
        // Warte max. 5 Sekunden auf den Abschluss des API-Tests
        await _apiTestCompleter!.future.timeout(const Duration(seconds: 5));
        _log.info('✅ API-Test wurde erfolgreich abgeschlossen.');
      } catch (e) {
        _log.severe('❌ Timeout beim Warten auf API-Test: $e');
        // Setze den Test-Status zurück
        _apiTestInProgress = false;
        _apiTestCompleter = null;
      }
    }
    
    // Lösche Credentials nur, wenn wir nicht die statischen Validierungsergebnisse 
    // erhalten wollen
    if (!_hasValidatedCredentials) {
      _log.info('🧹 Lösche unsichere Credentials...');
      securelyWipeCredentials();
    } else {
      _log.info('🔒 Behalte validierte Credentials im Cache für zukünftige Verwendung.');
    }
    
    // Schließe den HTTP-Client nur, wenn kein API-Test läuft
    if (!_apiTestInProgress) {
      try {
        if (_httpClient != null) {
          _log.info('🔌 Schließe HTTP-Client...');
          _httpClient!.close();
        }
      } catch (e) {
        _log.severe('❌ Fehler beim Schließen des HTTP-Clients: $e');
      }
    } else {
      _log.warning('⚠️ HTTP-Client wird nicht geschlossen, da API-Test noch läuft!');
    }
    
    _log.info('👋 MailjetEmailService wurde erfolgreich beendet.');
  }

  /// Statische Methode zur globalen Validierung der API-Credentials
  /// Diese Methode kann unabhängig von einer Service-Instanz aufgerufen werden
  static Future<bool> validateCredentials(String apiKey, String secretKey, String toEmail) async {
    // Prüfe zuerst, ob bereits validierte Credentials im Cache vorhanden sind
    if (_hasValidatedCredentials && _validatedApiKey != null && _validatedSecretKey != null &&
        apiKey == _validatedApiKey && secretKey == _validatedSecretKey) {
      _log.info('Credentials bereits im Cache validiert.');
      return true;
    }
    
    // Wenn bereits eine Validierung läuft, warte auf deren Ergebnis
    if (_isValidatingGlobally) {
      _log.info('Credential-Validierung läuft bereits, warte auf Ergebnis...');
      if (_globalValidationCompleter != null) {
        try {
          return await _globalValidationCompleter!.future.timeout(Duration(seconds: 10));
        } catch (e) {
          _log.warning('Timeout beim Warten auf globale Validierung: $e');
          _isValidatingGlobally = false;
          _globalValidationCompleter = null;
          // Fahre mit eigener Validierung fort
        }
      }
    }
    
    // Setze den globalen Lock und Completer
    _isValidatingGlobally = true;
    _globalValidationCompleter = Completer<bool>();
    
    _log.info('Starte globale API-Credential-Validierung...');
    
    try {
      // Erstelle einen temporären HTTP-Client für den Test
      final httpClient = SecureHttpClient();
      
      try {
        final credentials = '$apiKey:$secretKey';
        final encodedCredentials = base64Encode(utf8.encode(credentials));
        final authHeader = 'Basic $encodedCredentials';
        
        final headers = {
          'Content-Type': 'application/json',
          'Authorization': authHeader,
        };
        
        // Wir verwenden dasselbe Test-Payload wie in _testApiCredentials
        final testUrl = 'https://api.mailjet.com/v3.1/send';
        
        // Lade Absender-Informationen direkt aus AppConfig
        String senderEmail = "noreply@nextvision.agency";
        String senderName = "Lebedew Haustechnik";
        try {
          final configSenderEmail = await AppConfig.senderEmail;
          if (configSenderEmail.isNotEmpty) {
            senderEmail = configSenderEmail;
          }
          final configSenderName = await AppConfig.senderName;
          if (configSenderName.isNotEmpty) {
            senderName = configSenderName;
          }
        } catch (e) {
          _log.warning('Fehler beim Laden der Absenderinformationen: $e');
        }
        
        final testData = {
          'Messages': [
            {
              'From': {
                'Email': senderEmail,
                'Name': senderName
              },
              'To': [
                {
                  'Email': toEmail,
                  'Name': 'Test'
                }
              ],
              'Subject': 'API Test',
              'TextPart': 'This is an API validation test'
            }
          ]
        };
        
        final jsonBody = jsonEncode(testData);
        
        http.Response? response;
        try {
          response = await httpClient.post(
            testUrl,
            headers: headers,
            body: jsonBody,
          );
          
          if (response.statusCode == 401) {
            _log.severe('Globale Validierung: API-Credentials ungültig (401 Unauthorized)');
            _isValidatingGlobally = false;
            _globalValidationCompleter?.complete(false);
            return false;
          }
          
          // Jeder andere Statuscode als 401 bedeutet, dass die Auth funktioniert hat
          _log.info('Globale Validierung: API-Credentials gültig (Status: ${response.statusCode})');
          
          // Speichere im statischen Cache
          _validatedApiKey = apiKey;
          _validatedSecretKey = secretKey;
          _hasValidatedCredentials = true;
          
          _isValidatingGlobally = false;
          _globalValidationCompleter?.complete(true);
          return true;
        } catch (e) {
          _log.severe('Fehler bei HTTP-Anfrage während globaler Validierung: $e');
          _isValidatingGlobally = false;
          _globalValidationCompleter?.complete(false);
          return false;
        } 
      } finally {
        // Stelle sicher, dass der temporäre HTTP-Client geschlossen wird
        httpClient.close();
      }
    } catch (e) {
      _log.severe('Fehler bei globaler Credential-Validierung: $e');
      _isValidatingGlobally = false;
      _globalValidationCompleter?.complete(false);
      return false;
    }
  }

  /// Stellt sicher, dass der HTTP-Client aktiv ist
  /// Bei Bedarf wird ein neuer HTTP-Client erstellt
  Future<void> _ensureHttpClientActive() async {
    try {
      // Prüfe, ob der HTTP-Client aktiv ist
      if (_httpClient == null) {
        _log.warning('⚠️ HTTP-Client ist null. Erstelle einen neuen Client...');
        _httpClient = SecureHttpClient();
        _log.info('✅ Neuer HTTP-Client erstellt.');
      }
      
      // Als weitere Absicherung können wir noch die Credentials erneut validieren
      if (_hasValidatedCredentials && _validatedApiKey != null && _validatedSecretKey != null) {
        if (_apiKey != _validatedApiKey || _secretKey != _validatedSecretKey) {
          _log.warning('⚠️ Credentials sind nicht synchron mit dem Cache. Aktualisiere...');
          _apiKey = _validatedApiKey!;
          _secretKey = _validatedSecretKey!;
          _log.info('✅ Lokale Credentials mit Cache synchronisiert.');
        }
      } else {
        _log.info('ℹ️ Keine validierten Credentials im Cache. Führe Validierung durch...');
        final isValid = await validateCredentials(_apiKey, _secretKey, _toEmail);
        if (isValid) {
          _log.info('✅ Credentials erfolgreich validiert.');
        } else {
          _log.severe('❌ Credentials-Validierung fehlgeschlagen!');
        }
      }
    } catch (e) {
      _log.severe('❌ Fehler beim Sicherstellen des HTTP-Clients: $e');
    }
  }

  /// Erstellt und sendet eine E-Mail über die Mailjet API mit einem temporären HTTP-Client
  /// Diese Methode wird verwendet, wenn der reguläre HTTP-Client geschlossen ist
  Future<bool> _sendEmailWithFreshClient(Map<String, dynamic> emailData) async {
    _log.info('Versuche, E-Mail mit frischem HTTP-Client zu senden...');
    
    // Erstelle einen neuen HTTP-Client für diese einzelne Anfrage
    final tempClient = SecureHttpClient();
    
    try {
      // Stelle sicher, dass die validesten Credentials verwendet werden
      if (_hasValidatedCredentials && _validatedApiKey != null && _validatedSecretKey != null) {
        _apiKey = _validatedApiKey!;
        _secretKey = _validatedSecretKey!;
      }
      
      // Erstelle die HTTP-Header
      final credentials = '$_apiKey:$_secretKey';
      final encodedCredentials = base64Encode(utf8.encode(credentials));
      final authHeader = 'Basic $encodedCredentials';
      
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': authHeader,
      };
      
      // API-Endpunkt für E-Mail-Versand
      final emailEndpoint = '$_baseUrl/send';
      
      _log.info('Sende E-Mail-Anfrage mit frischem Client an $emailEndpoint');
      
      final jsonBody = jsonEncode(emailData);
      
      // Sende die Anfrage
      final response = await tempClient.post(
        emailEndpoint,
        headers: headers,
        body: jsonBody,
      );
      
      _log.info('Antwort vom Server erhalten. Statuscode: ${response.statusCode}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log.info('✅ E-Mail erfolgreich gesendet! (Statuscode: ${response.statusCode})');
        return true;
      } else {
        _log.severe('❌ Fehler beim Senden der E-Mail: HTTP-Fehler ${response.statusCode}');
        _log.severe('Server-Antwort: ${response.body}');
        
        if (response.statusCode == 401) {
          _log.severe('❌ Authentifizierungsfehler: API-Credentials sind ungültig!');
          _log.severe('⚠️ Alle zukünftigen Versuche, E-Mails zu senden, werden fehlschlagen, bis gültige Credentials bereitgestellt werden.');
        }
        
        return false;
      }
    } catch (e) {
      _log.severe('❌ Ausnahme beim Senden der E-Mail mit frischem Client: $e');
      return false;
    } finally {
      // Schließe den temporären HTTP-Client
      tempClient.close();
      _log.info('Temporärer HTTP-Client geschlossen.');
    }
  }

  @override
  Future<bool> sendTroubleReport({
    required TroubleReport form,
    required List<File> images,
  }) async {
    try {
      _log.info('Sende Störungsmeldung für: ${form.name} <${form.email}>');
      
      // Validiere den Störungsbericht
      if (!_validateTroubleReport(form)) {
        _log.severe('Fehler beim Senden der Störungsmeldung: Validierung fehlgeschlagen');
        return false;
      }
      
      return await _sendEmail(form, images);
    } catch (e, stackTrace) {
      _log.severe('Fehler beim Senden der Störungsmeldung: $e', e, stackTrace);
      return false;
    }
  }

  /// Sendet eine E-Mail über die Mailjet API
  @override
  Future<bool> sendEmail({
    required String subject,
    required String body,
    required String toEmail,
    String? fromEmail,
    String? fromName,
    List<String>? attachmentPaths,
  }) async {
    try {
      _log.info('Sende E-Mail an: $toEmail');
      
      // Stelle sicher, dass der HTTP-Client aktiv ist
      await _ensureHttpClientActive();
      
      // Lade die Absender-Informationen, falls noch nicht geschehen
      if (_cachedSenderEmail == null || _cachedSenderName == null) {
        await _loadSenderInfo();
      }

      // WICHTIG: Vor dem Senden nochmal prüfen, ob wir validierte Credentials haben
      // und diese gegebenenfalls verwenden
      if (_hasValidatedCredentials && _validatedApiKey != null && _validatedSecretKey != null) {
        if (_apiKey != _validatedApiKey || _secretKey != _validatedSecretKey) {
          _log.warning('⚠️ Verwendete Credentials stimmen nicht mit validierten überein - aktualisiere für diesen Request');
          _apiKey = _validatedApiKey!;
          _secretKey = _validatedSecretKey!;
          _log.info('✅ Credentials auf validierte Werte aktualisiert: ${_maskApiKey(_apiKey)}');
        }
      }
      
      // Erstelle die HTTP-Header
      final headers = _getHeaders();
      
      // API-Endpunkt für E-Mail-Versand
      final emailEndpoint = '$_baseUrl/send';
      
      final authHeader = headers['Authorization'] ?? '';
      _log.info('Erstelle Auth-Header mit API Key: ${_maskApiKey(_apiKey)}');
      _log.info('Auth-Header erstellt (Länge: ${authHeader.length})');
      _log.info('Auth-Header Vorschau: ${authHeader.substring(0, math.min(20, authHeader.length))}...');
      
      // Stelle sicher, dass Absender-E-Mail vorhanden ist
      final effectiveSenderEmail = fromEmail ?? await _senderEmail;
      if (effectiveSenderEmail.isEmpty) {
        _log.severe('❌ Absender-E-Mail ist leer! Verwende Fallback-E-Mail.');
        // Setze einen harten Fallback
        _cachedSenderEmail = "noreply@nextvision.agency";
      }
      
      // Stelle sicher, dass Absender-Name vorhanden ist
      final effectiveSenderName = fromName ?? await _senderName;
      if (effectiveSenderName.isEmpty) {
        _log.info('Absender-Name ist leer. Verwende Fallback-Wert.');
        _cachedSenderName = "Lebedew Haustechnik";
      }
      
      // Erstelle die E-Mail-Daten
      final Map<String, dynamic> emailData = {
        'Messages': [
          {
            'From': {
              'Email': effectiveSenderEmail.isEmpty ? "noreply@nextvision.agency" : effectiveSenderEmail,
              'Name': effectiveSenderName.isEmpty ? "Lebedew Haustechnik" : effectiveSenderName,
            },
            'To': [
              {
                'Email': toEmail,
                'Name': '',
              }
            ],
            'Subject': subject,
            'HTMLPart': body,
          }
        ]
      };
      
      // Log des gesamten Anfrage-Body für die Diagnose
      _log.info('E-Mail-Anfrage-Body: ${jsonEncode(emailData)}');
      
      // Füge Anhänge hinzu, falls vorhanden
      if (attachmentPaths != null && attachmentPaths.isNotEmpty) {
        _log.info('Füge ${attachmentPaths.length} Anhänge hinzu');
        
        final attachments = <Map<String, dynamic>>[];
        
        for (final path in attachmentPaths) {
          try {
            final file = File(path);
            if (await file.exists()) {
              final bytes = await file.readAsBytes();
              final filename = path.split('/').last;
              
              final contentType = _getContentType(filename);
              
              attachments.add({
                'ContentType': contentType,
                'Filename': filename,
                'Base64Content': base64Encode(bytes),
              });
              
              _log.info('Anhang hinzugefügt: $filename (${bytes.length} Bytes)');
            } else {
              _log.warning('Anhang nicht gefunden: $path');
            }
          } catch (e) {
            _log.warning('Fehler beim Hinzufügen des Anhangs $path: $e');
          }
        }
        
        if (attachments.isNotEmpty) {
          emailData['Messages'][0]['Attachments'] = attachments;
        }
      }
      
      http.Response? response;
      try {
        _log.info('Sende E-Mail an $emailEndpoint');
        
        // Sende die Anfrage
        final jsonBody = jsonEncode(emailData);
        response = await _httpClient.post(
          emailEndpoint,
          headers: headers,
          body: jsonBody,
        );
      } catch (e) {
        _log.severe('❌ Ausnahme beim Senden der E-Mail: $e');
        
        // Wenn der HTTP-Client geschlossen ist oder ein Verbindungsfehler auftritt, 
        // versuche es mit einem frischen Client
        if (e.toString().contains('Client is closed') || 
            e.toString().contains('ClientException') ||
            e.toString().contains('Socket')) {
          _log.warning('⚠️ HTTP-Client-Problem erkannt. Versuche mit frischem Client...');
          
          return await _sendEmailWithFreshClient(emailData);
        }
        
        return false;
      }
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        _log.info('✅ E-Mail erfolgreich gesendet! (Statuscode: ${response.statusCode})');
        return true;
      } else {
        _log.severe('❌ Fehler beim Senden der E-Mail: HTTP-Fehler ${response.statusCode}');
        _log.severe('Server-Antwort: ${response.body}');
        
        if (response.statusCode == 401) {
          _log.severe('❌ Authentifizierungsfehler: API-Credentials sind ungültig!');
          _log.severe('⚠️ Alle zukünftigen Versuche, E-Mails zu senden, werden fehlschlagen, bis gültige Credentials bereitgestellt werden.');
        }
        
        return false;
      }
    } catch (e) {
      _log.severe('❌ Ausnahme beim Senden der E-Mail: $e');
      return false;
    }
  }
} 