import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:riverpod/riverpod.dart';
import 'dart:io';
import 'dart:async';

import '../../domain/repositories/trouble_report_repository.dart';
import '../../domain/services/image_storage_service.dart';
import '../../domain/entities/trouble_report.dart';

part 'trouble_report_notifier.g.dart';

/// Status der Einreichung einer Störungsmeldung
enum SubmissionStatus {
  initial,
  submitting,
  success,
  error,
}

/// Mock-Implementation des ImageStorageService für den TroubleReportNotifier
class MockImageStorageService implements ImageStorageService {
  @override
  Future<String> saveImage(File image) async {
    // Mock-Implementation, die einen Dateipfad zurückgibt
    return 'mock_image_path_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
  
  @override
  Future<File?> getImage(String path) async {
    return null;
  }
  
  @override
  Future<bool> deleteImage(String path) async {
    // Keine Aktion in der Mock-Implementation
    return true;
  }
  
  @override
  Future<List<String>> getAllImagePaths() async {
    return [];
  }
  
  @override
  Future<bool> securelyDeleteImage(String path) async {
    // Keine Aktion in der Mock-Implementation
    return true;
  }
  
  @override
  Future<bool> securelyDeleteAllImages() async {
    // Keine Aktion in der Mock-Implementation
    return true;
  }
  
  @override
  void dispose() {
    // Keine Aktion in der Mock-Implementation
  }
}

/// Mock-Implementation des TroubleReportRepository
class MockTroubleReportRepository implements TroubleReportRepository {
  @override
  Future<bool> submitReport(TroubleReport report, List<File> images) async {
    // Mock-Implementation, gibt Erfolg zurück
    return true;
  }
  
  @override
  Future<String> saveImage(File image) async {
    // Mock-Implementation, die einen Dateipfad zurückgibt
    return 'mock_image_path_${DateTime.now().millisecondsSinceEpoch}.jpg';
  }
  
  @override
  Future<bool> submitTroubleReport(TroubleReport report) async {
    // Mock-Implementation, gibt Erfolg zurück
    return true;
  }
}

/// Zustand des TroubleReport
class TroubleReportState {
  final SubmissionStatus status;
  final String? errorMessage;
  final List<String> imagePaths;
  
  const TroubleReportState({
    this.status = SubmissionStatus.initial,
    this.errorMessage,
    this.imagePaths = const [],
  });
  
  TroubleReportState copyWith({
    SubmissionStatus? status,
    String? errorMessage,
    List<String>? imagePaths,
  }) {
    return TroubleReportState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      imagePaths: imagePaths ?? this.imagePaths,
    );
  }
}

/// TroubleReportNotifier verwaltet den Status der Störungsmeldung
class TroubleReportNotifier extends StateNotifier<TroubleReportState> {
  final ImageStorageService _imageStorageService;
  final TroubleReportRepository _repository;
  final ImagePicker _picker = ImagePicker();
  
  TroubleReportNotifier(this._imageStorageService, this._repository)
      : super(const TroubleReportState());
  
  /// Lädt ein Bild von der Galerie oder Kamera
  Future<void> pickImage(ImageSource source, BuildContext context) async {
    try {
      final pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );
      
      if (pickedFile != null) {
        final imagePath = await _imageStorageService.saveImage(File(pickedFile.path));
        final updatedPaths = [...state.imagePaths, imagePath];
        state = state.copyWith(imagePaths: updatedPaths);
      }
    } catch (e) {
      state = state.copyWith(
        status: SubmissionStatus.error,
        errorMessage: 'Fehler beim Laden des Bildes: $e',
      );
    }
  }
  
  /// Sendet die Störungsmeldung ab
  Future<void> submitReport(TroubleReport report, List<File> images) async {
    try {
      state = state.copyWith(status: SubmissionStatus.submitting);
      final success = await _repository.submitReport(report, images);
      if (success) {
        state = state.copyWith(status: SubmissionStatus.success);
      } else {
        state = state.copyWith(
          status: SubmissionStatus.error,
          errorMessage: 'Absenden der Störungsmeldung fehlgeschlagen',
        );
      }
    } catch (e) {
      state = state.copyWith(
        status: SubmissionStatus.error,
        errorMessage: 'Fehler beim Absenden der Störungsmeldung: $e',
      );
    }
  }
} 