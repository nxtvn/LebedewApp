import 'dart:io';
import '../domain/enums/request_type.dart';
import '../domain/enums/urgency_level.dart';

class TroubleReportForm {
  String? name;
  String? email;
  String? phone;
  String? address;
  RequestType? requestType;
  String? description;
  List<File> images = [];
  Set<String> energySources = {};
  bool hasMaintenanceContract = false;
  String? deviceModel;
  String? manufacturer;
  String? serialNumber;
  String? errorCode;
  DateTime? occurrenceDate;
  String? serviceHistory;
  String? previousIssues;
  UrgencyLevel? urgencyLevel;

  TroubleReportForm({
    this.name,
    this.email,
    this.phone,
    this.address,
    this.requestType,
    this.description,
    List<File>? images,
    Set<String>? energySources,
    this.hasMaintenanceContract = false,
    this.deviceModel,
    this.manufacturer,
    this.serialNumber,
    this.errorCode,
    this.occurrenceDate,
    this.serviceHistory,
    this.previousIssues,
    this.urgencyLevel,
  }) : 
    images = images ?? [],
    energySources = energySources ?? {};
} 