import 'dart:io';

abstract class ImageStorageService {
  Future<String> saveImage(File image);
  Future<File?> getImage(String path);
  Future<bool> deleteImage(String path);
  Future<List<String>> getAllImagePaths();
  
  /// Löscht ein Bild sicher, indem es vor dem Löschen überschrieben wird
  Future<bool> securelyDeleteImage(String path);
  
  /// Löscht alle Bilder sicher, die im lokalen Speicher gehalten werden
  Future<bool> securelyDeleteAllImages();
  
  /// Gibt alle Ressourcen frei und bereinigt den Speicher
  void dispose();
} 