import 'dart:io';

import '../../domain/entities/trouble_report.dart';

/// Status der Berichtsübermittlung
enum SubmissionStatus {
  none,
  sentSuccess,
  queuedOffline,
  error
}

/// Zustand für die Störungsmeldungs-Features
/// Diese Klasse wird normalerweise mit Freezed generiert.
/// Da wir vorübergehend keine Code-Generierung haben, implementieren wir sie manuell.
class TroubleReportState {
  final TroubleReport report;
  final List<File> images;
  final bool isLoading;
  final bool validationAttempted;
  final SubmissionStatus submissionStatus; 
  final String? errorMessage;
  
  const TroubleReportState({
    required this.report,
    this.images = const [],
    this.isLoading = false,
    this.validationAttempted = false,
    this.submissionStatus = SubmissionStatus.none,
    this.errorMessage,
  });
  
  /// Prüft, ob alle erforderlichen Felder ausgefüllt sind
  bool get isValid {
    return report.name.isNotEmpty &&
           report.email.isNotEmpty &&
           report.description.isNotEmpty &&
           report.hasAcceptedTerms;
  }
  
  /// Prüft, ob genug Informationen für eine hilfreiche Störungsmeldung vorhanden sind
  bool get isDetailedEnough {
    // Basis-Validierung
    if (!isValid) return false;
    
    // Erweiterte Validierung
    int score = 0;
    
    // Bewerte optional ausgefüllte Felder
    if (report.phone != null && report.phone!.isNotEmpty) score++;
    if (report.address != null && report.address!.isNotEmpty) score++;
    if (report.deviceModel != null && report.deviceModel!.isNotEmpty) score++;
    if (report.manufacturer != null && report.manufacturer!.isNotEmpty) score++;
    if (report.serialNumber != null && report.serialNumber!.isNotEmpty) score++;
    if (report.errorCode != null && report.errorCode!.isNotEmpty) score++;
    if (report.energySources.isNotEmpty) score++;
    if (report.occurrenceDate != null) score++;
    if (report.imagesPaths.isNotEmpty) score++;
    
    // Erfordere mindestens 3 zusätzliche Informationen
    return score >= 3;
  }
  
  /// Erstellt einen leeren State für eine neue Störungsmeldung
  factory TroubleReportState.initial() => TroubleReportState(
    report: TroubleReport.create(),
  );
  
  /// Erstellt eine Kopie des Zustands mit aktualisierten Werten
  TroubleReportState copyWith({
    TroubleReport? report,
    List<File>? images,
    bool? isLoading,
    bool? validationAttempted,
    SubmissionStatus? submissionStatus,
    String? errorMessage,
  }) {
    return TroubleReportState(
      report: report ?? this.report,
      images: images ?? this.images,
      isLoading: isLoading ?? this.isLoading,
      validationAttempted: validationAttempted ?? this.validationAttempted,
      submissionStatus: submissionStatus ?? this.submissionStatus,
      errorMessage: errorMessage,
    );
  }
  
  /// Erstellt eine JSON-Map aus dem Zustand
  Map<String, dynamic> toJson() {
    return {
      'report': report.toJson(),
      'isLoading': isLoading,
      'validationAttempted': validationAttempted,
      'submissionStatus': submissionStatus.toString(),
      'errorMessage': errorMessage,
    };
  }
  
  /// Erstellt einen Zustand aus einer JSON-Map
  factory TroubleReportState.fromJson(Map<String, dynamic> json) {
    return TroubleReportState(
      report: TroubleReport.fromJson(json['report'] as Map<String, dynamic>),
      isLoading: json['isLoading'] as bool? ?? false,
      validationAttempted: json['validationAttempted'] as bool? ?? false,
      submissionStatus: _parseSubmissionStatus(json['submissionStatus'] as String?),
      errorMessage: json['errorMessage'] as String?,
    );
  }
  
  /// Hilfsmethode zum Parsen des SubmissionStatus aus einem String
  static SubmissionStatus _parseSubmissionStatus(String? status) {
    if (status == null) return SubmissionStatus.none;
    
    for (var value in SubmissionStatus.values) {
      if (value.toString() == status) {
        return value;
      }
    }
    
    return SubmissionStatus.none;
  }
} 