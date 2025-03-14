import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:logging/logging.dart';
import '../../domain/services/image_storage_service.dart';
import 'package:flutter/foundation.dart';

class LocalImageStorageService implements ImageStorageService {
  final _uuid = const Uuid();
  static const String _imageDirectory = 'trouble_report_images';
  final _log = Logger('LocalImageStorageService');

  Future<Directory> get _getImageDirectory async {
    final appDir = await getApplicationDocumentsDirectory();
    final directory = Directory('${appDir.path}/$_imageDirectory');
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  @override
  Future<String> saveImage(File image) async {
    try {
      final directory = await _getImageDirectory;
      final fileName = '${_uuid.v4()}.jpg';
      final savedImage = await image.copy('${directory.path}/$fileName');
      return savedImage.path;
    } catch (e) {
      debugPrint('Fehler beim Speichern des Bildes: $e');
      rethrow;
    }
  }

  @override
  Future<File?> getImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('Fehler beim Laden des Bildes: $e');
      return null;
    }
  }

  @override
  Future<bool> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      _log.warning('Fehler beim Löschen des Bildes: $e');
      return false;
    }
  }

  @override
  Future<List<String>> getAllImagePaths() async {
    try {
      final directory = await _getImageDirectory;
      final List<FileSystemEntity> entities = await directory.list().toList();
      return entities
          .whereType<File>()
          .map((file) => file.path)
          .toList();
    } catch (e) {
      _log.warning('Fehler beim Abrufen aller Bildpfade: $e');
      return [];
    }
  }

  /// Löscht eine Datei sicher durch Überschreiben mit zufälligen Daten
  /// bevor sie gelöscht wird
  Future<void> _securelyWipeFile(File file) async {
    try {
      if (await file.exists()) {
        _log.info('Lösche Datei sicher: ${file.path}');
        
        // Hole die Dateigröße
        final fileSize = await file.length();
        
        // Erstelle einen Block mit zufälligen Daten
        final random = List.generate(
          fileSize > 1024 ? 1024 : fileSize.toInt(), 
          (index) => (DateTime.now().microsecondsSinceEpoch % 256)
        );
        
        // Überschreibe die Datei mehrmals mit zufälligen Daten
        for (int i = 0; i < 3; i++) {
          final sink = file.openWrite(mode: FileMode.writeOnly);
          
          // Bei großen Dateien überschreiben wir in Blöcken
          for (int offset = 0; offset < fileSize; offset += 1024) {
            sink.add(random);
          }
          
          await sink.flush();
          await sink.close();
        }
        
        _log.info('Datei erfolgreich überschrieben: ${file.path}');
      }
    } catch (e) {
      _log.warning('Fehler beim sicheren Überschreiben der Datei ${file.path}: $e');
    }
  }
  
  @override
  Future<bool> securelyDeleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        // Überschreibe die Datei mit zufälligen Daten
        await _securelyWipeFile(file);
        
        // Lösche die Datei
        await file.delete();
        _log.info('Bild sicher gelöscht: $path');
        return true;
      }
      return false;
    } catch (e) {
      _log.warning('Fehler beim sicheren Löschen des Bildes: $e');
      // Versuche, die Datei dennoch zu löschen
      try {
        return await deleteImage(path);
      } catch (_) {
        return false;
      }
    }
  }
  
  @override
  Future<bool> securelyDeleteAllImages() async {
    try {
      final imagePaths = await getAllImagePaths();
      var allSuccessful = true;
      
      for (final path in imagePaths) {
        final success = await securelyDeleteImage(path);
        if (!success) {
          allSuccessful = false;
        }
      }
      
      return allSuccessful;
    } catch (e) {
      _log.severe('Fehler beim sicheren Löschen aller Bilder: $e');
      return false;
    }
  }
  
  @override
  void dispose() {
    _log.info('Bereinige ImageStorageService-Ressourcen');
    // Starte einen asynchronen Prozess, der alle temporären Dateien bereinigt
    securelyDeleteAllImages().then((success) {
      if (success) {
        _log.info('Alle Bilder wurden sicher gelöscht');
      } else {
        _log.warning('Einige Bilder konnten nicht sicher gelöscht werden');
      }
    });
  }
} 