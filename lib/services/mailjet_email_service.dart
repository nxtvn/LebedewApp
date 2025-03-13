import 'dart:convert';
import 'package:logging/logging.dart';
import '../core/config/app_config.dart';
import '../core/network/secure_http_client.dart';
import '../models/trouble_report.dart';

/// Service zum Versenden von E-Mails über die Mailjet API
class MailjetEmailService {
  static final _log = Logger('MailjetEmailService');
  final SecureHttpClient _httpClient = SecureHttpClient();
  
  /// Sendet eine E-Mail-Benachrichtigung über einen neuen Störungsbericht
  Future<bool> sendTroubleReportNotification(TroubleReport report) async {
    try {
      final apiKey = await AppConfig.mailjetApiKey;
      final secretKey = await AppConfig.mailjetSecretKey;
      final serviceEmail = await AppConfig.serviceEmail;
      final senderEmail = await AppConfig.senderEmail;
      final senderName = await AppConfig.senderName;
      
      // Überprüfe, ob alle erforderlichen Konfigurationswerte vorhanden sind
      if (apiKey.isEmpty || secretKey.isEmpty || serviceEmail.isEmpty || 
          senderEmail.isEmpty || senderName.isEmpty) {
        _log.severe('E-Mail-Konfiguration unvollständig');
        return false;
      }
      
      // Erstelle den E-Mail-Inhalt
      final emailContent = _createEmailContent(report);
      
      // Erstelle den Request-Body
      final body = jsonEncode({
        'Messages': [
          {
            'From': {
              'Email': senderEmail,
              'Name': senderName
            },
            'To': [
              {
                'Email': serviceEmail,
                'Name': 'Service Team'
              }
            ],
            'Subject': 'Neue Störungsmeldung: ${report.title}',
            'TextPart': emailContent,
            'HTMLPart': _createHtmlContent(report),
            'CustomID': 'TroubleReport-${report.id}'
          }
        ]
      });
      
      // Erstelle die Authentifizierung
      final auth = base64.encode(utf8.encode('$apiKey:$secretKey'));
      
      // Sende die Anfrage
      final response = await _httpClient.post(
        'https://api.mailjet.com/v3.1/send',
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Basic $auth',
        },
        body: body,
      );
      
      // Überprüfe die Antwort
      if (_httpClient.isSuccessful(response)) {
        _log.info('E-Mail-Benachrichtigung erfolgreich gesendet');
        return true;
      } else {
        _log.warning('Fehler beim Senden der E-Mail: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      _log.severe('Fehler beim Senden der E-Mail-Benachrichtigung: $e');
      return false;
    }
  }
  
  /// Erstellt den E-Mail-Inhalt für einen Störungsbericht
  String _createEmailContent(TroubleReport report) {
    final buffer = StringBuffer();
    
    buffer.writeln('Neue Störungsmeldung eingegangen:');
    buffer.writeln();
    buffer.writeln('Titel: ${report.title}');
    buffer.writeln('Beschreibung: ${report.description}');
    buffer.writeln('Priorität: ${report.priority}');
    buffer.writeln('Kategorie: ${report.category}');
    buffer.writeln('Gemeldet von: ${report.reporterName}');
    buffer.writeln('Kontakt: ${report.contactInfo}');
    buffer.writeln('Gemeldet am: ${report.reportDate}');
    
    if (report.location.isNotEmpty) {
      buffer.writeln('Ort: ${report.location}');
    }
    
    if (report.attachmentUrls.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('Anlagen:');
      for (final url in report.attachmentUrls) {
        buffer.writeln('- $url');
      }
    }
    
    buffer.writeln();
    buffer.writeln('Diese Meldung wurde über die Lebedew Haustechnik App gesendet.');
    
    return buffer.toString();
  }
  
  /// Erstellt den HTML-Inhalt für einen Störungsbericht
  String _createHtmlContent(TroubleReport report) {
    final buffer = StringBuffer();
    
    buffer.writeln('<html><body>');
    buffer.writeln('<h2>Neue Störungsmeldung eingegangen</h2>');
    buffer.writeln('<table style="border-collapse: collapse; width: 100%;">');
    
    // Tabellenstil
    const thStyle = 'text-align: left; padding: 8px; background-color: #f2f2f2; border: 1px solid #ddd;';
    const tdStyle = 'text-align: left; padding: 8px; border: 1px solid #ddd;';
    
    // Tabellenzeilen
    buffer.writeln('<tr><th style="$thStyle">Titel</th><td style="$tdStyle">${_escapeHtml(report.title)}</td></tr>');
    buffer.writeln('<tr><th style="$thStyle">Beschreibung</th><td style="$tdStyle">${_escapeHtml(report.description)}</td></tr>');
    buffer.writeln('<tr><th style="$thStyle">Priorität</th><td style="$tdStyle">${_escapeHtml(report.priority)}</td></tr>');
    buffer.writeln('<tr><th style="$thStyle">Kategorie</th><td style="$tdStyle">${_escapeHtml(report.category)}</td></tr>');
    buffer.writeln('<tr><th style="$thStyle">Gemeldet von</th><td style="$tdStyle">${_escapeHtml(report.reporterName)}</td></tr>');
    buffer.writeln('<tr><th style="$thStyle">Kontakt</th><td style="$tdStyle">${_escapeHtml(report.contactInfo)}</td></tr>');
    buffer.writeln('<tr><th style="$thStyle">Gemeldet am</th><td style="$tdStyle">${_escapeHtml(report.reportDate.toString())}</td></tr>');
    
    if (report.location.isNotEmpty) {
      buffer.writeln('<tr><th style="$thStyle">Ort</th><td style="$tdStyle">${_escapeHtml(report.location)}</td></tr>');
    }
    
    buffer.writeln('</table>');
    
    if (report.attachmentUrls.isNotEmpty) {
      buffer.writeln('<h3>Anlagen</h3>');
      buffer.writeln('<ul>');
      for (final url in report.attachmentUrls) {
        buffer.writeln('<li><a href="${_escapeHtml(url)}">${_escapeHtml(url)}</a></li>');
      }
      buffer.writeln('</ul>');
    }
    
    buffer.writeln('<p><em>Diese Meldung wurde über die Lebedew Haustechnik App gesendet.</em></p>');
    buffer.writeln('</body></html>');
    
    return buffer.toString();
  }
  
  /// Escapes HTML special characters to prevent XSS
  String _escapeHtml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#039;');
  }
} 