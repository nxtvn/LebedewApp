import 'package:uuid/uuid.dart';
import '../enums/request_type.dart';
import '../enums/urgency_level.dart';

enum RequestType {
  heating,
  plumbing,
  other,
}

enum UrgencyLevel {
  low,
  normal,
  high,
}

class TroubleReport {
  final String id;
  final RequestType type;
  final String name;
  final String email;
  final String? phone;
  final String? address;
  final bool hasMaintenanceContract;
  final String description;
  final String? deviceModel;
  final String? manufacturer;
  final String? serialNumber;
  final String? errorCode;
  final Set<String> energySources;
  final DateTime? occurrenceDate;
  final String? serviceHistory;
  final UrgencyLevel urgencyLevel;
  final List<String> imagesPaths;
  final bool isSynced;

  TroubleReport({
    String? id,
    required this.type,
    required this.name,
    required this.email,
    this.phone,
    this.address,
    this.hasMaintenanceContract = false,
    required this.description,
    this.deviceModel,
    this.manufacturer,
    this.serialNumber,
    this.errorCode,
    this.energySources = const {},
    this.occurrenceDate,
    this.serviceHistory,
    required this.urgencyLevel,
    this.imagesPaths = const [],
    this.isSynced = false,
  }) : id = id ?? const Uuid().v4();

  TroubleReport copyWith({
    String? id,
    RequestType? type,
    String? name,
    String? email,
    String? phone,
    String? address,
    bool? hasMaintenanceContract,
    String? description,
    String? deviceModel,
    String? manufacturer,
    String? serialNumber,
    String? errorCode,
    Set<String>? energySources,
    DateTime? occurrenceDate,
    String? serviceHistory,
    UrgencyLevel? urgencyLevel,
    List<String>? imagesPaths,
    bool? isSynced,
  }) {
    return TroubleReport(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      hasMaintenanceContract: hasMaintenanceContract ?? this.hasMaintenanceContract,
      description: description ?? this.description,
      deviceModel: deviceModel ?? this.deviceModel,
      manufacturer: manufacturer ?? this.manufacturer,
      serialNumber: serialNumber ?? this.serialNumber,
      errorCode: errorCode ?? this.errorCode,
      energySources: energySources ?? this.energySources,
      occurrenceDate: occurrenceDate ?? this.occurrenceDate,
      serviceHistory: serviceHistory ?? this.serviceHistory,
      urgencyLevel: urgencyLevel ?? this.urgencyLevel,
      imagesPaths: imagesPaths ?? this.imagesPaths,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'name': name,
    'email': email,
    'phone': phone,
    'address': address,
    'hasMaintenanceContract': hasMaintenanceContract,
    'description': description,
    'deviceModel': deviceModel,
    'manufacturer': manufacturer,
    'serialNumber': serialNumber,
    'errorCode': errorCode,
    'energySources': energySources.toList(),
    'occurrenceDate': occurrenceDate?.toIso8601String(),
    'serviceHistory': serviceHistory,
    'urgencyLevel': urgencyLevel.name,
    'imagesPaths': imagesPaths,
    'isSynced': isSynced,
  };

  factory TroubleReport.fromJson(Map<String, dynamic> json) => TroubleReport(
    id: json['id'],
    type: RequestType.values.firstWhere((e) => e.name == json['type']),
    name: json['name'],
    email: json['email'],
    phone: json['phone'],
    address: json['address'],
    hasMaintenanceContract: json['hasMaintenanceContract'] ?? false,
    description: json['description'],
    deviceModel: json['deviceModel'],
    manufacturer: json['manufacturer'],
    serialNumber: json['serialNumber'],
    errorCode: json['errorCode'],
    energySources: Set<String>.from(json['energySources'] ?? []),
    occurrenceDate: json['occurrenceDate'] != null 
      ? DateTime.parse(json['occurrenceDate'])
      : null,
    serviceHistory: json['serviceHistory'],
    urgencyLevel: UrgencyLevel.values.firstWhere((e) => e.name == json['urgencyLevel']),
    imagesPaths: List<String>.from(json['imagesPaths'] ?? []),
    isSynced: json['isSynced'] ?? false,
  );
} 