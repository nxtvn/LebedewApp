import 'package:uuid/uuid.dart';
import '../enums/request_type.dart';
import '../enums/urgency_level.dart';

/// Datenklasse für Störungsmeldungen
/// 
/// Diese Klasse wird normalerweise mit Freezed generiert.
/// Da wir vorübergehend keine Code-Generierung haben, implementieren wir sie manuell.
class TroubleReport {
  // ID und Status
  final String id;
  final bool isSynced;
  
  // Anfrageinformationen
  final RequestType type;
  final UrgencyLevel urgencyLevel;
  final String description;
  final Set<String> energySources;
  final DateTime? occurrenceDate;
  
  // Kontaktdaten
  final String name;
  final String email;
  final String? phone;
  final String? address;
  
  // Vertragsinformationen
  final bool hasMaintenanceContract;
  final String? customerNumber;
  
  // Geräteinformationen
  final String? deviceModel;
  final String? manufacturer;
  final String? serialNumber;
  final String? errorCode;
  final String? serviceHistory;
  final String? previousIssues;
  
  // Bilder und Anhänge
  final List<String> imagesPaths;
  
  // Datenschutz und Nutzungsbedingungen
  final bool hasAcceptedTerms;

  const TroubleReport({
    required this.id,
    this.isSynced = false,
    required this.type,
    required this.urgencyLevel,
    this.description = '',
    this.energySources = const {},
    this.occurrenceDate,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.hasMaintenanceContract = false,
    this.customerNumber,
    this.deviceModel,
    this.manufacturer,
    this.serialNumber,
    this.errorCode,
    this.serviceHistory,
    this.previousIssues,
    this.imagesPaths = const [],
    this.hasAcceptedTerms = false,
  });

  /// Erstellt eine neue leere Störungsmeldung mit einer eindeutigen ID
  factory TroubleReport.create() => TroubleReport(
    id: const Uuid().v4(),
    type: RequestType.trouble,
    urgencyLevel: UrgencyLevel.medium,
    name: '',
    email: '',
  );

  /// Erstellt eine Kopie mit aktualisierten Werten
  TroubleReport copyWith({
    String? id,
    bool? isSynced,
    RequestType? type,
    UrgencyLevel? urgencyLevel,
    String? description,
    Set<String>? energySources,
    DateTime? occurrenceDate,
    String? name,
    String? email,
    String? phone,
    String? address,
    bool? hasMaintenanceContract,
    String? customerNumber,
    String? deviceModel,
    String? manufacturer,
    String? serialNumber,
    String? errorCode,
    String? serviceHistory,
    String? previousIssues,
    List<String>? imagesPaths,
    bool? hasAcceptedTerms,
  }) {
    return TroubleReport(
      id: id ?? this.id,
      isSynced: isSynced ?? this.isSynced,
      type: type ?? this.type,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      description: description ?? this.description,
      energySources: energySources ?? this.energySources,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      hasMaintenanceContract: hasMaintenanceContract ?? this.hasMaintenanceContract,
      customerNumber: customerNumber ?? this.customerNumber,
      deviceModel: deviceModel ?? this.deviceModel,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumber: serialNumber ?? this.serialNumber,
      errorCode: errorCode ?? this.errorCode,
      serviceHistory: serviceHistory ?? this.serviceHistory,
      previousIssues: previousIssues ?? this.previousIssues,
      imagesPaths: imagesPaths ?? this.imagesPaths,
      hasAcceptedTerms: hasAcceptedTerms ?? this.hasAcceptedTerms,
    );
  }

  /// Erstellt eine Map aus dieser Instanz für die JSON-Serialisierung
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'isSynced': isSynced,
      'type': type.toString(),
      'urgencyLevel': urgencyLevel.toString(),
      'description': description,
      'energySources': energySources.toList(),
      'occurrenceDate': occurrenceDate?.toIso8601String(),
      'name': name,
      'email': email,
      'phone': phone,
      'address': address,
      'hasMaintenanceContract': hasMaintenanceContract,
      'customerNumber': customerNumber,
      'deviceModel': deviceModel,
      'manufacturer': manufacturer,
      'serialNumber': serialNumber,
      'errorCode': errorCode,
      'serviceHistory': serviceHistory,
      'previousIssues': previousIssues,
      'imagesPaths': imagesPaths,
      'hasAcceptedTerms': hasAcceptedTerms,
    };
  }

  /// Erstellt eine Instanz aus einer JSON-Map
  factory TroubleReport.fromJson(Map<String, dynamic> json) {
    return TroubleReport(
      id: json['id'] as String,
      isSynced: json['isSynced'] as bool? ?? false,
      type: RequestType.values.firstWhere(
        (e) => e.toString() == json['type'],
        orElse: () => RequestType.trouble,
      ),
      urgencyLevel: UrgencyLevel.values.firstWhere(
        (e) => e.toString() == json['urgencyLevel'],
        orElse: () => UrgencyLevel.medium,
      ),
      description: json['description'] as String? ?? '',
      energySources: (json['energySources'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toSet() ?? {},
      occurrenceDate: json['occurrenceDate'] != null
          ? DateTime.parse(json['occurrenceDate'] as String)
          : null,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String?,
      address: json['address'] as String?,
      hasMaintenanceContract: json['hasMaintenanceContract'] as bool? ?? false,
      customerNumber: json['customerNumber'] as String?,
      deviceModel: json['deviceModel'] as String?,
      manufacturer: json['manufacturer'] as String?,
      serialNumber: json['serialNumber'] as String?,
      errorCode: json['errorCode'] as String?,
      serviceHistory: json['serviceHistory'] as String?,
      previousIssues: json['previousIssues'] as String?,
      imagesPaths: (json['imagesPaths'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ?? [],
      hasAcceptedTerms: json['hasAcceptedTerms'] as bool? ?? false,
    );
  }
} 