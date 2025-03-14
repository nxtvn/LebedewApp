import 'dart:io';
import '../entities/trouble_report.dart';

/// Interface für den E-Mail-Service
abstract class EmailService {
  /// Sendet eine Störungsmeldung per E-Mail
  /// 
  /// [form] enthält die Daten der Störungsmeldung
  /// [images] enthält optionale Bildanhänge
  /// 
  /// Gibt true zurück, wenn der Versand erfolgreich war
  Future<bool> sendTroubleReport({
    required TroubleReport form,
    required List<File> images,
  });

  Future<bool> sendEmail({
    required String subject,
    required String body,
    required String toEmail,
    String? fromEmail,
    String? fromName,
    List<String>? attachmentPaths,
  });
  
  /// Gibt alle Ressourcen frei und löscht sensible Daten aus dem Speicher
  /// 
  /// Diese Methode sollte aufgerufen werden, wenn der Service nicht mehr benötigt wird,
  /// z.B. wenn die Anwendung geschlossen wird oder der Benutzer sich abmeldet.
  void dispose();
} 