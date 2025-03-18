import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:path/path.dart' as path;
import '../../domain/services/image_storage_service.dart';

/// Implementierung des Bilderspeicher-Services
/// 
/// Diese Klasse ist verantwortlich für die Speicherung und Verwaltung von Bildern,
/// die mit Störungsmeldungen verbunden sind.
class ImageStorageServiceImpl implements ImageStorageService {
  final Uuid _uuid = const Uuid();
  
  @override
  Future<String> saveImage(File imageFile) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/trouble_images');
      
      // Erstelle das Verzeichnis, falls es noch nicht existiert
      if (!await imagesDir.exists()) {
        await imagesDir.create(recursive: true);
      }
      
      // Generiere einen eindeutigen Dateinamen
      final fileName = '${_uuid.v4()}${path.extension(imageFile.path)}';
      final savedImagePath = '${imagesDir.path}/$fileName';
      
      // Kopiere die Datei
      await imageFile.copy(savedImagePath);
      
      return savedImagePath;
    } catch (e) {
      // Bei einem Fehler Standardpfad zurückgeben
      return 'error_saving_image';
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
      return null;
    }
  }
  
  @override
  Future<bool> deleteImage(String imagePath) async {
    try {
      final file = File(imagePath);
      if (await file.exists()) {
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<List<String>> getAllImagePaths() async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final imagesDir = Directory('${directory.path}/trouble_images');
      
      if (!await imagesDir.exists()) {
        return [];
      }
      
      final List<FileSystemEntity> entities = await imagesDir.list().toList();
      return entities
          .whereType<File>()
          .map((e) => e.path)
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  @override
  Future<bool> securelyDeleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        // Überschreibe Datei vor dem Löschen für sicheres Löschen
        final length = await file.length();
        final randomData = List<int>.filled(length, 0)..fillRange(0, length, 255); // Mit 0xFF füllen
        await file.writeAsBytes(randomData, flush: true);
        await file.delete();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  @override
  Future<bool> securelyDeleteAllImages() async {
    try {
      final paths = await getAllImagePaths();
      for (final path in paths) {
        await securelyDeleteImage(path);
      }
      return true;
    } catch (e) {
      return false;
    }
  }
  
  @override
  void dispose() {
    // Keine Ressourcen zu bereinigen
  }
} 