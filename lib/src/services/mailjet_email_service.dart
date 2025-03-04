import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import 'package:image/image.dart' as img;
import '../domain/entities/trouble_report.dart';
import '../domain/services/email_service.dart';
import '../core/config/env.dart';
import 'package:intl/intl.dart';
import 'email_queue_service.dart';

/// Implementierung des E-Mail-Services mit Mailjet
class MailjetEmailService implements EmailService {
  static final _log = Logger('MailjetEmailService');
  static const String _baseUrl = 'https://api.mailjet.com/v3.1';
  final String _apiKey;
  final String _secretKey;
  final String _toEmail;
  final EmailQueueService _queueService;
  
  MailjetEmailService({
    required String apiKey,
    required String secretKey,
    required String toEmail,
    required EmailQueueService queueService,
  })  : _apiKey = apiKey,
        _secretKey = secretKey,
        _toEmail = toEmail,
        _queueService = queueService {
    // Queue beim Start initialisieren und verarbeiten
    _initializeQueue();
  }

  Future<void> _initializeQueue() async {
    await _queueService.initialize();
    _processQueue();
  }

  Future<void> _processQueue() async {
    await _queueService.processQueue(_sendEmail);
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
      _log.warning('Fehler bei der Bildkomprimierung: $e');
      return imageFile.readAsBytesSync();
    }
  }

  Future<bool> _sendEmail(TroubleReport form, List<File> images) async {
    try {
      // Basis64-kodierte Authentifizierung
      final auth = base64Encode(utf8.encode('$_apiKey:$_secretKey'));
      
      // Bildanhänge vorbereiten
      final attachments = await Future.wait(
        images.map((file) async {
          final bytes = await _compressImage(file);
          return {
            'ContentType': 'image/jpeg',
            'Filename': file.path.split('/').last,
            'Base64Content': base64Encode(bytes),
          };
        }),
      );

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
          ${form.occurrenceDate != null ? '<p><strong>Datum des Vorfalls:</strong> ${DateFormat('dd.MM.yyyy').format(form.occurrenceDate!)}</p>' : ''}
          
          <h4 style="color: #1976D2; margin-top: 15px;">Ihre Kontaktdaten</h4>
          <p><strong>Name:</strong> ${form.name}</p>
          <p><strong>E-Mail:</strong> ${form.email}</p>
          ${form.phone != null ? '<p><strong>Telefon:</strong> ${form.phone}</p>' : ''}
          ${form.address != null ? '<p><strong>Adresse:</strong> ${form.address}</p>' : ''}
          
          <h4 style="color: #1976D2; margin-top: 15px;">Geräteinformationen</h4>
          ${form.deviceModel != null ? '<p><strong>Gerätemodell:</strong> ${form.deviceModel}</p>' : ''}
          ${form.manufacturer != null ? '<p><strong>Hersteller:</strong> ${form.manufacturer}</p>' : ''}
          ${form.serialNumber != null ? '<p><strong>Seriennummer:</strong> ${form.serialNumber}</p>' : ''}
          ${form.errorCode != null ? '<p><strong>Fehlercode:</strong> ${form.errorCode}</p>' : ''}
          
          <h4 style="color: #1976D2; margin-top: 15px;">Ihre Problembeschreibung</h4>
          <p>${form.description}</p>
          
          ${images.isNotEmpty ? '<p><strong>Angehängte Bilder:</strong> ${images.length} Bild${images.length == 1 ? '' : 'er'}</p>' : ''}
        </div>
        
        <p>Wir werden Ihre Meldung schnellstmöglich bearbeiten. Bei dringenden Fällen werden wir uns umgehend mit Ihnen in Verbindung setzen.</p>
        
        <p>Mit freundlichen Grüßen<br>Ihr Lebedew Haustechnik Service-Team</p>
      ''';

      // Service E-Mail Text
      final serviceTextBody = '''
        Neue Störungsmeldung

        Art des Anliegens:
        Typ: ${form.type.label}
        Dringlichkeit: ${form.urgencyLevel.label}
        
        Kontaktdaten:
        Name: ${form.name}
        E-Mail: ${form.email}
        ${form.phone != null ? 'Telefon: ${form.phone}\n' : ''}
        ${form.address != null ? 'Adresse: ${form.address}\n' : ''}
        
        Gerätedaten:
        ${form.deviceModel != null ? 'Gerätemodell: ${form.deviceModel}\n' : ''}
        ${form.manufacturer != null ? 'Hersteller: ${form.manufacturer}\n' : ''}
        ${form.serialNumber != null ? 'Seriennummer: ${form.serialNumber}\n' : ''}
        ${form.errorCode != null ? 'Fehlercode: ${form.errorCode}\n' : ''}
        ${form.occurrenceDate != null ? 'Datum des Vorfalls: ${DateFormat('dd.MM.yyyy').format(form.occurrenceDate!)}\n' : ''}
        
        Service-Informationen:
        Wartungsvertrag: ${form.hasMaintenanceContract ? 'Ja' : 'Nein'}
        ${form.serviceHistory != null ? 'Servicehistorie: ${form.serviceHistory}\n' : ''}
        ${form.energySources.isNotEmpty ? 'Energiequellen: ${form.energySources.join(', ')}\n' : ''}
        
        Problembeschreibung:
        ${form.description}
        
        ${images.isNotEmpty ? '\nAngehängte Bilder: ${images.length} Bild${images.length == 1 ? '' : 'er'}\n' : ''}
      ''';

      // Kunden E-Mail Text
      final customerTextBody = '''
        Bestätigung Ihrer Störungsmeldung

        Sehr geehrte(r) ${form.name},

        vielen Dank für Ihre Störungsmeldung. Wir haben Ihre Meldung erfolgreich erhalten und werden uns zeitnah mit Ihnen in Verbindung setzen.

        Nachfolgend finden Sie eine Zusammenfassung Ihrer Meldung:

        Details Ihrer Meldung:
        Meldungstyp: ${form.type.label}
        Dringlichkeit: ${form.urgencyLevel.label}
        ${form.occurrenceDate != null ? 'Datum des Vorfalls: ${DateFormat('dd.MM.yyyy').format(form.occurrenceDate!)}\n' : ''}

        Ihre Kontaktdaten:
        Name: ${form.name}
        E-Mail: ${form.email}
        ${form.phone != null ? 'Telefon: ${form.phone}\n' : ''}
        ${form.address != null ? 'Adresse: ${form.address}\n' : ''}

        Geräteinformationen:
        ${form.deviceModel != null ? 'Gerätemodell: ${form.deviceModel}\n' : ''}
        ${form.manufacturer != null ? 'Hersteller: ${form.manufacturer}\n' : ''}
        ${form.serialNumber != null ? 'Seriennummer: ${form.serialNumber}\n' : ''}
        ${form.errorCode != null ? 'Fehlercode: ${form.errorCode}\n' : ''}

        Ihre Problembeschreibung:
        ${form.description}

        ${images.isNotEmpty ? 'Angehängte Bilder: ${images.length} Bild${images.length == 1 ? '' : 'er'}\n' : ''}

        Wir werden Ihre Meldung schnellstmöglich bearbeiten. Bei dringenden Fällen werden wir uns umgehend mit Ihnen in Verbindung setzen.

        Mit freundlichen Grüßen
        Ihr Lebedew Haustechnik Service-Team
      ''';

      // API-Request für Service E-Mail
      final serviceResponse = await http.post(
        Uri.parse('$_baseUrl/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $auth',
        },
        body: json.encode({
          'Messages': [
            {
              'From': {
                'Email': Env.senderEmail,
                'Name': Env.senderName,
              },
              'To': [
                {
                  'Email': _toEmail,
                  'Name': 'Service',
                }
              ],
              'Subject': 'Neue Störungsmeldung von ${form.name}',
              'TextPart': serviceTextBody,
              'HTMLPart': serviceHtmlBody,
              if (attachments.isNotEmpty) 'Attachments': attachments,
            }
          ],
        }),
      );

      // API-Request für Kunden E-Mail
      final customerResponse = await http.post(
        Uri.parse('$_baseUrl/send'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $auth',
        },
        body: json.encode({
          'Messages': [
            {
              'From': {
                'Email': Env.senderEmail,
                'Name': Env.senderName,
              },
              'To': [
                {
                  'Email': form.email,
                  'Name': form.name,
                }
              ],
              'Subject': 'Bestätigung Ihrer Störungsmeldung',
              'TextPart': customerTextBody,
              'HTMLPart': customerHtmlBody,
              if (attachments.isNotEmpty) 'Attachments': attachments,
            }
          ],
        }),
      );

      return serviceResponse.statusCode == 200 && customerResponse.statusCode == 200;
    } catch (e) {
      _log.severe('Fehler beim E-Mail-Versand', e);
      return false;
    }
  }

  @override
  Future<bool> sendTroubleReport({
    required TroubleReport form,
    required List<File> images,
  }) async {
    try {
      final success = await _sendEmail(form, images);
      
      if (!success) {
        // Bei Fehler zur Queue hinzufügen
        await _queueService.addToQueue(
          form,
          images.map((file) => file.path).toList(),
        );
        return false;
      }
      
      return true;
    } catch (e) {
      // Bei Netzwerkfehlern zur Queue hinzufügen
      await _queueService.addToQueue(
        form,
        images.map((file) => file.path).toList(),
      );
      return false;
    }
  }
} 