import 'dart:io';
import '../../domain/services/email_service.dart';
import '../services/email_queue_service.dart';
import '../../core/network/network_info_facade.dart';
import '../../domain/entities/trouble_report.dart';

/// Implementierung des E-Mail-Services
/// 
/// Diese Klasse ist verantwortlich für das Senden von E-Mails, einschließlich
/// der Störungsmeldungen.
class EmailServiceImpl implements EmailService {
  final NetworkInfoFacade _networkInfo;
  final EmailQueueService _emailQueueService;
  
  EmailServiceImpl(this._networkInfo, this._emailQueueService);
  
  @override
  Future<bool> sendEmail({
    required String toEmail,
    required String subject,
    required String body,
    String? fromEmail,
    String? fromName,
    List<String>? attachmentPaths,
  }) async {
    // Prüfe Netzwerkverbindung
    final isConnected = await _networkInfo.isCurrentlyConnected;
    
    if (isConnected) {
      // Hier würde die tatsächliche E-Mail-Versand-Logik stehen
      // z.B. mit einem SMTP-Client
      return true;
    } else {
      // Wenn keine Verbindung besteht, E-Mail zur Warteschlange hinzufügen
      _emailQueueService.enqueueEmail(
        to: toEmail,
        subject: subject,
        body: body,
        attachmentPaths: attachmentPaths ?? [],
      );
      return false;
    }
  }
  
  @override
  Future<bool> sendTroubleReport({
    required TroubleReport form,
    required List<File> images,
  }) async {
    final body = _createTroubleReportEmail(form);
    
    return sendEmail(
      toEmail: "support@example.com",
      subject: "Neue Störungsmeldung: ${form.type.displayName}",
      body: body,
      attachmentPaths: form.imagesPaths,
    );
  }
  
  String _createTroubleReportEmail(TroubleReport report) {
    // Hier würde die Formatierung der E-Mail stehen
    return """
    Neue Störungsmeldung von ${report.name}
    
    Typ: ${report.type.displayName}
    Dringlichkeit: ${report.urgencyLevel.displayName}
    Beschreibung: ${report.description}
    
    Kontakt:
    E-Mail: ${report.email}
    Telefon: ${report.phone ?? "Nicht angegeben"}
    
    Geräteinformationen:
    Modell: ${report.deviceModel ?? "Nicht angegeben"}
    Hersteller: ${report.manufacturer ?? "Nicht angegeben"}
    Seriennummer: ${report.serialNumber ?? "Nicht angegeben"}
    Fehlercode: ${report.errorCode ?? "Nicht angegeben"}
    
    Bilder: ${report.imagesPaths.isEmpty ? "Keine" : "${report.imagesPaths.length} Bilder angehängt"}
    """;
  }
  
  @override
  void dispose() {
    // Hier könnten Ressourcen freigegeben werden
  }
} 