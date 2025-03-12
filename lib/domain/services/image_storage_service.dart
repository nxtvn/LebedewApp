import 'dart:io';

abstract class ImageStorageService {
  Future<String> saveImage(File image);
  Future<File?> getImage(String path);
  Future<bool> deleteImage(String path);
  Future<List<String>> getAllImagePaths();
} 