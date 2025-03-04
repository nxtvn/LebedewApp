import 'dart:io';

abstract class ImageStorageService {
  Future<String> saveImage(File image);
  Future<void> deleteImage(String path);
} 