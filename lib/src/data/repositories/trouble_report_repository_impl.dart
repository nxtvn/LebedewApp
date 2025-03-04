import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/trouble_report_repository.dart';
import '../../domain/entities/trouble_report.dart';
import '../../domain/services/email_service.dart';
import '../../domain/services/image_storage_service.dart';

class TroubleReportRepositoryImpl implements TroubleReportRepository {
  final EmailService _emailService;
  final ImageStorageService _imageStorage;

  TroubleReportRepositoryImpl(this._emailService, this._imageStorage);

  @override
  Future<bool> submitReport(TroubleReport report, List<File> images) async {
    try {
      return await _emailService.sendTroubleReport(
        form: report,
        images: images,
      );
    } catch (e) {
      debugPrint('Error submitting report: $e');
      return false;
    }
  }

  @override
  Future<String> saveImage(File image) async {
    return await _imageStorage.saveImage(image);
  }
} 