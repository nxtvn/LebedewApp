import 'dart:io';
import '../entities/trouble_report.dart';

abstract class TroubleReportRepository {
  /// Sendet eine Störungsmeldung
  /// 
  /// [report] enthält die Daten der Störungsmeldung
  /// [images] enthält die ausgewählten Bilder
  Future<bool> submitReport(TroubleReport report, List<File> images);

  /// Speichert ein Bild temporär
  Future<String> saveImage(File image);
} 