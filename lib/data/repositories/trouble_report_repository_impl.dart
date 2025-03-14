import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../domain/repositories/trouble_report_repository.dart';
import '../../domain/entities/trouble_report.dart';
import '../../domain/services/email_service.dart';
import '../../domain/services/image_storage_service.dart';
import '../../core/utils/image_utils.dart';
import 'package:intl/intl.dart';

class TroubleReportRepositoryImpl implements TroubleReportRepository {
  final EmailService _emailService;
  final ImageStorageService _imageStorageService;
  final DateFormat _dateFormatter = DateFormat('dd.MM.yyyy');

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

  String _createEmailBody(TroubleReport report) {
    final buffer = StringBuffer();
    
    buffer.writeln('<h2>Neue Störungsmeldung</h2>');
    buffer.writeln('<p><strong>Art des Anliegens:</strong> ${report.type.label}</p>');
    buffer.writeln('<p><strong>Dringlichkeit:</strong> ${report.urgencyLevel.label}</p>');
    
    buffer.writeln('<h3>Kontaktdaten</h3>');
    buffer.writeln('<p><strong>Name:</strong> ${report.name}</p>');
    buffer.writeln('<p><strong>E-Mail:</strong> ${report.email}</p>');
    
    if (report.phone != null && report.phone!.isNotEmpty) {
      buffer.writeln('<p><strong>Telefon:</strong> ${report.phone}</p>');
    }
    
    if (report.address != null && report.address!.isNotEmpty) {
      buffer.writeln('<p><strong>Adresse:</strong> ${report.address}</p>');
    }
    
    buffer.writeln('<h3>Gerätedaten</h3>');
    
    if (report.deviceModel != null && report.deviceModel!.isNotEmpty) {
      buffer.writeln('<p><strong>Gerätemodell:</strong> ${report.deviceModel}</p>');
    }
    
    if (report.manufacturer != null && report.manufacturer!.isNotEmpty) {
      buffer.writeln('<p><strong>Hersteller:</strong> ${report.manufacturer}</p>');
    }
    
    if (report.serialNumber != null && report.serialNumber!.isNotEmpty) {
      buffer.writeln('<p><strong>Seriennummer:</strong> ${report.serialNumber}</p>');
    }
    
    if (report.errorCode != null && report.errorCode!.isNotEmpty) {
      buffer.writeln('<p><strong>Fehlercode:</strong> ${report.errorCode}</p>');
    }
    
    if (report.occurrenceDate != null) {
      buffer.writeln('<p><strong>Datum des Vorfalls:</strong> ${_dateFormatter.format(report.occurrenceDate!)}</p>');
    }
    
    if (report.serviceHistory != null && report.serviceHistory!.isNotEmpty) {
      buffer.writeln('<p><strong>Servicehistorie:</strong> ${report.serviceHistory}</p>');
    }
    
    buffer.writeln('<h3>Problembeschreibung</h3>');
    buffer.writeln('<p>${report.description}</p>');
    
    if (report.energySources.isNotEmpty) {
      buffer.writeln('<p><strong>Energiequellen:</strong> ${report.energySources.join(', ')}</p>');
    }
    
    buffer.writeln('<p><strong>Wartungsvertrag:</strong> ${report.hasMaintenanceContract ? 'Ja' : 'Nein'}</p>');
    
    if (report.imagesPaths.isNotEmpty) {
      buffer.writeln('<p><strong>Anzahl der Bilder:</strong> ${report.imagesPaths.length}</p>');
    }
    
    return buffer.toString();
  }
} 