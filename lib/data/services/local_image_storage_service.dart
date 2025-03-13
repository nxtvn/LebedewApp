import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../domain/services/image_storage_service.dart';
import 'package:flutter/foundation.dart';

class LocalImageStorageService implements ImageStorageService {
  final _uuid = const Uuid();
  static const String _imageDirectory = 'trouble_report_images';

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
      debugPrint('Fehler beim Löschen des Bildes: $e');
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
      debugPrint('Fehler beim Abrufen aller Bildpfade: $e');
      return [];
    }
  }
} 