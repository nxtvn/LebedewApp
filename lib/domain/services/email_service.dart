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
} 