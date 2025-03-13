import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:logging/logging.dart';
import 'package:image/image.dart' as img;
import '../../domain/entities/trouble_report.dart';
import '../../domain/services/email_service.dart';
import '../../core/config/app_config.dart';
import '../../core/network/network_info_facade.dart';
import '../../core/network/secure_http_client.dart';
import 'package:intl/intl.dart';
import 'email_queue_service.dart';

/// Implementierung des E-Mail-Services mit Mailjet
class MailjetEmailService implements EmailService {
  static final _log = Logger('MailjetEmailService');
  static const String _baseUrl = 'https://api.mailjet.com/v3.1';
  
  // Korrekte Credentials als Fallback, falls die AppConfig-Werte fehlen
  static const String _fallbackApiKey = '3004d543963be32f5dbe4da2329e109c';
  static const String _fallbackSecretKey = 'e28fd899034aba79be3b9bf6627f2621';
  
  String _apiKey;
  String _secretKey;
  final String _toEmail;
  final EmailQueueService _queueService;
  final NetworkInfoFacade _networkInfo;
  final SecureHttpClient _httpClient = SecureHttpClient();
  
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
  })  : _apiKey = apiKey,
        _secretKey = secretKey,
        _toEmail = toEmail,
        _queueService = queueService,
        _networkInfo = networkInfo {
    // Überprüfe die Credentials und setze Fallback-Werte, falls nötig
    _validateAndFixCredentials();
    
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
    // API Key überprüfen und Fallback setzen wenn nötig
    if (_apiKey.isEmpty) {
      _log.warning('Mailjet API Key ist leer! Verwende Fallback-Wert.');
      _apiKey = _fallbackApiKey;
      _usingFallbackCredentials = true;
    } else {
      _log.info('Mailjet API Key ist vorhanden (Länge: ${_apiKey.length})');
    }
    
    // Secret Key überprüfen und Fallback setzen wenn nötig
    if (_secretKey.isEmpty) {
      _log.warning('Mailjet Secret Key ist leer! Verwende Fallback-Wert.');
      _secretKey = _fallbackSecretKey;
      _usingFallbackCredentials = true;
    } else {
      _log.info('Mailjet Secret Key ist vorhanden (Länge: ${_secretKey.length})');
    }
    
    if (_usingFallbackCredentials) {
      _log.warning('Verwende Fallback-Credentials für Mailjet! Dies sollte nur vorübergehend sein.');
    }
  }
  
  /// Erstellt den Authorization-Header für die Mailjet API
  String _createAuthHeader() {
    final credentials = '$_apiKey:$_secretKey';
    final encodedCredentials = base64Encode(utf8.encode(credentials));
    return 'Basic $encodedCredentials';
  }
  
  /// Aktualisiert den Authorization-Header für die API-Anfrage
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': _createAuthHeader(),
    };
  }
  
  /// Lädt die Absender-Informationen aus AppConfig
  Future<void> _loadSenderInfo() async {
    // Aktualisiere die Absender-E-Mail auf die neue Adresse
    _cachedSenderEmail = "julian.scherer@nextvision.agency";
    _cachedSenderName = await AppConfig.senderName;
    _log.info('Absender-Informationen geladen: $_cachedSenderName <$_cachedSenderEmail>');
  }
  
  /// Gibt die Absender-E-Mail zurück
  Future<String> get _senderEmail async {
    if (_cachedSenderEmail == null || _cachedSenderEmail!.isEmpty) {
      await _loadSenderInfo();
    }
    return _cachedSenderEmail ?? 'julian.scherer@nextvision.agency';
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
      
      // Validiere erforderliche Felder
      if (email.toEmail.isEmpty || email.subject.isEmpty || email.body.isEmpty) {
        _log.severe('Fehler beim Senden der einfachen E-Mail: Erforderliche Felder fehlen');
        return false;
      }
      
      final headers = _getHeaders();
      _log.info('Auth-Header erstellt (Länge: ${headers['Authorization']?.length ?? 0})');

      final Map<String, dynamic> emailData = {
        'Messages': [
          {
            'From': {
              'Email': email.fromEmail ?? await _senderEmail,
              'Name': email.fromName ?? await _senderName,
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
      final response = await _httpClient.post(
        '$_baseUrl/send',
        headers: headers,
        body: jsonEncode(emailData),
      );

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
            await AppConfig.setApiKey(ConfigKeys.mailjetApiKey, _fallbackApiKey);
            await AppConfig.setApiKey(ConfigKeys.mailjetSecretKey, _fallbackSecretKey);
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
      _log.info('Sende Störungsmeldung für: ${form.name} <${form.email}>');
      
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

      // Nur gültige Anhänge verwenden
      final validAttachments = attachments.where((a) => a != null).toList();
      
      // Service E-Mail Template
      final serviceHtmlBody = '''
        <h2>Neue Störungsmeldung</h2>
        <h3>Art des Anliegens</h3>
        <p><strong>Typ:</strong> ${form.type.label}</p>
        <p><strong>Dringlichkeit:</strong> ${form.urgencyLevel.label}</p>
        
        <h3>Kontaktdaten</h3>
        <p><strong>Name:</strong> ${form.name}</p>
        <p><strong>E-Mail:</strong> ${form.email}</p>
        ${form.phone != null ? '<p><strong>Telefon:</strong> ${form.phone}</p>' : ''}
        ${form.address != null ? '<p><strong>Adresse:</strong> ${form.address}</p>' : ''}
        
        <h3>Gerätedaten</h3>
        ${form.deviceModel != null ? '<p><strong>Gerätemodell:</strong> ${form.deviceModel}</p>' : ''}
        ${form.manufacturer != null ? '<p><strong>Hersteller:</strong> ${form.manufacturer}</p>' : ''}
        ${form.serialNumber != null ? '<p><strong>Seriennummer:</strong> ${form.serialNumber}</p>' : ''}
        ${form.errorCode != null ? '<p><strong>Fehlercode:</strong> ${form.errorCode}</p>' : ''}
        ${form.occurrenceDate != null ? '<p><strong>Datum des Vorfalls:</strong> ${DateFormat('dd.MM.yyyy').format(form.occurrenceDate!)}</p>' : ''}
        
        <h3>Service-Informationen</h3>
        <p><strong>Wartungsvertrag:</strong> ${form.hasMaintenanceContract ? 'Ja' : 'Nein'}</p>
        ${form.serviceHistory != null ? '<p><strong>Servicehistorie:</strong> ${form.serviceHistory}</p>' : ''}
        ${form.energySources.isNotEmpty ? '<p><strong>Energiequellen:</strong> ${form.energySources.join(', ')}</p>' : ''}
        
        <h3>Problembeschreibung</h3>
        <p>${form.description}</p>
        
        ${images.isNotEmpty ? '<h3>Angehängte Bilder</h3><p>${images.length} Bild${images.length == 1 ? '' : 'er'} angehängt</p>' : ''}
      ''';

      // Kunden E-Mail Template
      final customerHtmlBody = '''
        <h2>Bestätigung Ihrer Störungsmeldung</h2>
        
        <p>Sehr geehrte(r) ${form.name},</p>
        
        <p>vielen Dank für Ihre Störungsmeldung. Wir haben Ihre Meldung erfolgreich erhalten und werden uns zeitnah mit Ihnen in Verbindung setzen.</p>
        
        <p>Nachfolgend finden Sie eine Zusammenfassung Ihrer Meldung:</p>
        
        <div style="background-color: #f5f5f5; padding: 20px; border-radius: 8px; margin: 20px 0;">
          <h3 style="color: #1976D2;">Details Ihrer Meldung</h3>
          
          <p><strong>Meldungstyp:</strong> ${form.type.label}</p>
          <p><strong>Dringlichkeit:</strong> ${form.urgencyLevel.label}</p>
          <p><strong>Beschreibung:</strong> ${form.description}</p>
          
          ${form.deviceModel != null ? '<p><strong>Gerätemodell:</strong> ${form.deviceModel}</p>' : ''}
          ${form.manufacturer != null ? '<p><strong>Hersteller:</strong> ${form.manufacturer}</p>' : ''}
          ${form.serialNumber != null ? '<p><strong>Seriennummer:</strong> ${form.serialNumber}</p>' : ''}
          
          ${images.isNotEmpty ? '<p><strong>Angehängte Bilder:</strong> ${images.length} Bild${images.length == 1 ? '' : 'er'}</p>' : ''}
        </div>
        
        <p>Sollten Sie weitere Fragen haben oder zusätzliche Informationen bereitstellen möchten, antworten Sie bitte auf diese E-Mail oder kontaktieren Sie uns telefonisch.</p>
        
        <p>Mit freundlichen Grüßen,<br>
        Ihr Lebedew Haustechnik Team</p>
      ''';
      
      // Datums- und Zeitformat für den Betreff
      final dateTime = DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now());
      
      // Erstelle die Service-E-Mail-Daten
      final serviceEmailData = {
        'Messages': [
          {
            'From': {
              'Email': await _senderEmail,
              'Name': await _senderName,
            },
            'To': [
              {
                'Email': _toEmail,
                'Name': 'Service Team',
              }
            ],
            'Subject': 'Neue Störungsmeldung von ${form.name} ($dateTime)',
            'HTMLPart': serviceHtmlBody,
            'Attachments': validAttachments,
          }
        ]
      };
      
      // Erstelle die Kunden-E-Mail-Daten (ohne Anhänge)
      final customerEmailData = {
        'Messages': [
          {
            'From': {
              'Email': await _senderEmail,
              'Name': await _senderName,
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

      // Aktualisierte Header-Methode verwenden
      final headers = _getHeaders();
      _log.info('Auth-Header erstellt (Länge: ${headers['Authorization']?.length ?? 0})');

      _log.info('Sende Service-E-Mail an: $_toEmail');
      
      // Sende die Service-E-Mail
      final serviceResponse = await _httpClient.post(
        '$_baseUrl/send',
        headers: headers,
        body: jsonEncode(serviceEmailData),
      );

      // Spezielle Behandlung für 401-Fehler bei der Service-Email
      if (serviceResponse.statusCode == 401) {
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
            body: jsonEncode(serviceEmailData),
          );
          
          if (_httpClient.isSuccessful(retryResponse)) {
            _log.info('Service-E-Mail mit Fallback-Credentials erfolgreich gesendet');
            
            // Wenn die Service-E-Mail erfolgreich gesendet wurde, senden wir auch die Kunden-E-Mail
            _log.info('Sende Bestätigungs-E-Mail an Kunden: ${form.email}');
            final customerRetryResponse = await _httpClient.post(
              '$_baseUrl/send',
              headers: fallbackHeaders,
              body: jsonEncode(customerEmailData),
            );
            
            if (!_httpClient.isSuccessful(customerRetryResponse)) {
              _log.severe('Fehler beim Senden der Kunden-E-Mail: '
                  '${customerRetryResponse.statusCode} - ${customerRetryResponse.body}');
            } else {
              _log.info('Kunden-E-Mail erfolgreich gesendet');
            }
            
            // Fehler in AppConfig persistieren
            try {
              await AppConfig.setApiKey(ConfigKeys.mailjetApiKey, _fallbackApiKey);
              await AppConfig.setApiKey(ConfigKeys.mailjetSecretKey, _fallbackSecretKey);
              _log.info('Fallback-Credentials in AppConfig gespeichert');
            } catch (e) {
              _log.warning('Fehler beim Speichern der Fallback-Credentials: $e');
            }
            
            return true; // Wir geben true zurück, da die Service-E-Mail erfolgreich gesendet wurde
          } else {
            _log.severe('Fehler beim Senden der Service-E-Mail auch mit Fallback-Credentials: '
                '${retryResponse.statusCode} - ${retryResponse.body}');
            return false;
          }
        }
        
        return false;
      }

      if (!_httpClient.isSuccessful(serviceResponse)) {
        _log.severe('Fehler beim Senden der Service-E-Mail: ${serviceResponse.statusCode} - ${serviceResponse.body}');
        return false;
      }
      
      _log.info('Service-E-Mail erfolgreich gesendet');
      _log.info('Sende Bestätigungs-E-Mail an Kunden: ${form.email}');

      // Sende die Kunden-E-Mail
      final customerResponse = await _httpClient.post(
        '$_baseUrl/send',
        headers: headers,
        body: jsonEncode(customerEmailData),
      );

      if (!_httpClient.isSuccessful(customerResponse)) {
        _log.severe('Fehler beim Senden der Kunden-E-Mail: ${customerResponse.statusCode} - ${customerResponse.body}');
        // Wir geben trotzdem true zurück, da die Service-E-Mail erfolgreich gesendet wurde
        return true;
      }

      _log.info('Kunden-E-Mail erfolgreich gesendet');
      return true;
    } catch (e, stackTrace) {
      _log.severe('Fehler beim Senden der E-Mail: $e', e, stackTrace);
      return false;
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
      
      // Validiere erforderliche Felder
      if (subject.isEmpty || body.isEmpty || toEmail.isEmpty) {
        _log.severe('Fehler beim Senden der E-Mail: Erforderliche Felder fehlen');
        return false;
      }
      
      // Prüfe, ob eine Netzwerkverbindung besteht
      final isConnected = await _networkInfo.isCurrentlyConnected;
      if (!isConnected) {
        _log.info('Keine Netzwerkverbindung. E-Mail wird in die Warteschlange gestellt.');
        
        // Füge die E-Mail zur Warteschlange hinzu
        await _queueService.addSimpleEmailToQueue(
          EmailQueueItem(
            subject: subject,
            body: body,
            toEmail: toEmail,
            fromEmail: fromEmail ?? await _senderEmail,
            fromName: fromName ?? await _senderName,
            attachmentPaths: attachmentPaths,
          ),
        );
        
        return true; // Wir geben true zurück, da die E-Mail in die Warteschlange gestellt wurde
      }
      
      // Erstelle die E-Mail-Anfrage
      final emailData = {
        'Messages': [
          {
            'From': {
              'Email': fromEmail ?? await _senderEmail,
              'Name': fromName ?? await _senderName,
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
      
      // Füge Anhänge hinzu, falls vorhanden
      if (attachmentPaths != null && attachmentPaths.isNotEmpty) {
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
            } else {
              _log.warning('Anhang existiert nicht: $path');
            }
          } catch (e) {
            _log.severe('Fehler beim Hinzufügen des Anhangs: $e');
          }
        }
        
        if (attachments.isNotEmpty) {
          emailData['Messages']![0]['Attachments'] = attachments;
        }
      }
      
      // Aktualisierte Header-Methode verwenden
      final headers = _getHeaders();
      _log.info('Auth-Header erstellt (Länge: ${headers['Authorization']?.length ?? 0})');
      
      _log.info('Sende E-Mail-Anfrage an Mailjet API');
      
      // Sende die E-Mail
      final response = await _httpClient.post(
        '$_baseUrl/send',
        headers: headers,
        body: jsonEncode(emailData),
      );
      
      // Spezielle Behandlung für 401-Fehler
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
            _log.info('E-Mail mit Fallback-Credentials erfolgreich gesendet an: $toEmail');
          } else {
            _log.severe('Fehler beim Senden der E-Mail auch mit Fallback-Credentials: '
                '${retryResponse.statusCode} - ${retryResponse.body}');
          }
          
          return isSuccess;
        }
        
        // Fehler in AppConfig persistieren
        if (_usingFallbackCredentials) {
          try {
            await AppConfig.setApiKey(ConfigKeys.mailjetApiKey, _fallbackApiKey);
            await AppConfig.setApiKey(ConfigKeys.mailjetSecretKey, _fallbackSecretKey);
            _log.info('Fallback-Credentials in AppConfig gespeichert');
          } catch (e) {
            _log.warning('Fehler beim Speichern der Fallback-Credentials: $e');
          }
        }
        
        return false;
      }
      
      final isSuccess = _httpClient.isSuccessful(response);
      if (isSuccess) {
        _log.info('E-Mail erfolgreich gesendet an: $toEmail');
      } else {
        _log.severe('Fehler beim Senden der E-Mail: ${response.statusCode} - ${response.body}');
      }
      
      return isSuccess;
    } catch (e, stackTrace) {
      _log.severe('Fehler beim Senden der E-Mail: $e', e, stackTrace);
      return false;
    }
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
} 