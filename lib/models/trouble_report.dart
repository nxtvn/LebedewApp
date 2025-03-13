import 'package:uuid/uuid.dart';

/// Vereinfachtes Modell für Störungsberichte
class TroubleReport {
  final String id;
  final String title;
  final String description;
  final String priority;
  final String category;
  final String reporterName;
  final String contactInfo;
  final DateTime reportDate;
  final String location;
  final List<String> attachmentUrls;

  TroubleReport({
    String? id,
    required this.title,
    required this.description,
    required this.priority,
    required this.category,
    required this.reporterName,
    required this.contactInfo,
    DateTime? reportDate,
    this.location = '',
    this.attachmentUrls = const [],
  }) : 
    id = id ?? const Uuid().v4(),
    reportDate = reportDate ?? DateTime.now();

  /// Erstellt eine Kopie dieses Berichts mit optionalen Änderungen
  TroubleReport copyWith({
    String? id,
    String? title,
    String? description,
    String? priority,
    String? category,
    String? reporterName,
    String? contactInfo,
    DateTime? reportDate,
    String? location,
    List<String>? attachmentUrls,
  }) {
    return TroubleReport(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      reporterName: reporterName ?? this.reporterName,
      contactInfo: contactInfo ?? this.contactInfo,
      reportDate: reportDate ?? this.reportDate,
      location: location ?? this.location,
      attachmentUrls: attachmentUrls ?? this.attachmentUrls,
    );
  }

  /// Konvertiert den Bericht in ein JSON-Objekt
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'priority': priority,
      'category': category,
      'reporterName': reporterName,
      'contactInfo': contactInfo,
      'reportDate': reportDate.toIso8601String(),
      'location': location,
      'attachmentUrls': attachmentUrls,
    };
  }

  /// Erstellt einen Bericht aus einem JSON-Objekt
  factory TroubleReport.fromJson(Map<String, dynamic> json) {
    return TroubleReport(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      priority: json['priority'],
      category: json['category'],
      reporterName: json['reporterName'],
      contactInfo: json['contactInfo'],
      reportDate: DateTime.parse(json['reportDate']),
      location: json['location'] ?? '',
      attachmentUrls: List<String>.from(json['attachmentUrls'] ?? []),
    );
  }
} 