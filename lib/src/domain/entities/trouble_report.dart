import '../enums/request_type.dart';
import '../enums/urgency_level.dart';

class TroubleReport {
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

  TroubleReport({
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
  });

  Map<String, dynamic> toJson() => {
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
  };

  factory TroubleReport.fromJson(Map<String, dynamic> json) => TroubleReport(
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
  );
} 