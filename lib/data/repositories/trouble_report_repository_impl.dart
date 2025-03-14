import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/trouble_report_repository.dart';
import '../../domain/entities/trouble_report.dart';
import '../../domain/services/email_service.dart';
import '../../domain/services/image_storage_service.dart';
import '../../core/utils/image_utils.dart';

class TroubleReportRepositoryImpl implements TroubleReportRepository {
  final EmailService _emailService;
  final ImageStorageService _imageStorageService;

  TroubleReportRepositoryImpl(this._emailService, this._imageStorageService);

  @override
  Future<bool> submitReport(TroubleReport report, List<File> images) async {
    try {
      // Optimiere Bilder
      final optimizedImages = <File>[];
      for (final image in images) {
        try {
          final optimizedImage = await ImageUtils.optimizeImage(image);
          optimizedImages.add(optimizedImage);
        } catch (e) {
          // Bei Fehler das Original verwenden
          optimizedImages.add(image);
          debugPrint('Fehler bei der Bildoptimierung: $e');
        }
      }

      // Verwende die sendTroubleReport-Methode anstelle von sendEmail,
      // damit sowohl die Service-E-Mail als auch die Kunden-E-Mail gesendet werden
      final success = await _emailService.sendTroubleReport(
        form: report,
        images: optimizedImages,
      );
      
      if (!success) {
        debugPrint('❌ Störungsmeldung konnte nicht gesendet werden');
      } else {
        debugPrint('✅ Störungsmeldung erfolgreich gesendet (Service-E-Mail und Kunden-E-Mail)');
      }
      
      return success;
    } on SocketException catch (e) {
      debugPrint('Netzwerkfehler beim Senden der Störungsmeldung: $e');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('Zeitüberschreitung beim Senden der Störungsmeldung: $e');
      return false;
    } catch (e) {
      debugPrint('Fehler beim Senden der Störungsmeldung: $e');
      return false;
    }
  }

  @override
  Future<String> saveImage(File image) async {
    return await _imageStorageService.saveImage(image);
  }

  @override
  Future<bool> submitTroubleReport(TroubleReport report) async {
    try {
      // Erstelle eine Liste von File-Objekten aus den Pfaden
      final images = <File>[];
      for (final imagePath in report.imagesPaths) {
        try {
          final image = File(imagePath);
          if (await image.exists()) {
            images.add(image);
          } else {
            debugPrint('Bild existiert nicht: $imagePath');
          }
        } catch (e) {
          debugPrint('Fehler beim Laden des Bildes: $e');
        }
      }

      // Verwende die sendTroubleReport-Methode anstelle von sendEmail,
      // damit sowohl die Service-E-Mail als auch die Kunden-E-Mail gesendet werden
      final success = await _emailService.sendTroubleReport(
        form: report,
        images: images,
      );
      
      if (!success) {
        debugPrint('❌ Störungsmeldung konnte nicht gesendet werden');
      } else {
        debugPrint('✅ Störungsmeldung erfolgreich gesendet (Service-E-Mail und Kunden-E-Mail)');
      }
      
      return success;
    } on SocketException catch (e) {
      debugPrint('Netzwerkfehler beim Senden der Störungsmeldung: $e');
      return false;
    } on TimeoutException catch (e) {
      debugPrint('Zeitüberschreitung beim Senden der Störungsmeldung: $e');
      return false;
    } catch (e) {
      debugPrint('Fehler beim Senden der Störungsmeldung: $e');
      return false;
    }
  }

} 