import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:image_picker/image_picker.dart';

/// Hilfsmethoden für die Bildverarbeitung und -optimierung
class ImageUtils {
  static final _log = Logger('ImageUtils');
  
  /// Optimiert ein Bild für den Upload
  /// 
  /// Reduziert die Größe und Qualität des Bildes, um die Übertragungszeit zu verkürzen
  /// und den Speicherplatz zu reduzieren.
  /// 
  /// Parameter:
  /// - originalImage: Die ursprüngliche Bilddatei
  /// - maxWidth: Maximale Breite des optimierten Bildes (Standard: 1080px)
  /// - maxHeight: Maximale Höhe des optimierten Bildes (Standard: 1080px)
  /// - quality: JPEG-Qualität (0-100, Standard: 80)
  /// 
  /// Gibt die optimierte Bilddatei zurück.
  static Future<File> optimizeImage(File originalImage, {
    int maxWidth = 1080,
    int maxHeight = 1080,
    int quality = 80,
  }) async {
    _log.info('Optimiere Bild: ${originalImage.path}');
    final tempDir = await getTemporaryDirectory();
    final targetPath = '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    // Process image in background thread
    final optimizedBytes = await compute(
      _processImage,
      _ImageProcessParams(
        bytes: await originalImage.readAsBytes(),
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      ),
    );
    
    // Save optimized image
    final optimizedFile = File(targetPath);
    await optimizedFile.writeAsBytes(optimizedBytes);
    
    final originalSize = await originalImage.length();
    final optimizedSize = await optimizedFile.length();
    final compressionRatio = (1 - (optimizedSize / originalSize)) * 100;
    
    _log.info('Bild optimiert: ${originalSize ~/ 1024}KB -> ${optimizedSize ~/ 1024}KB (${compressionRatio.toStringAsFixed(1)}% Reduktion)');
    
    return optimizedFile;
  }

  /// Verarbeitet ein Bild im Hintergrund-Thread
  /// 
  /// Diese Methode wird von compute() aufgerufen und läuft in einem separaten Isolate.
  static Uint8List _processImage(_ImageProcessParams params) {
    // Decode image
    final image = img.decodeImage(params.bytes);
    if (image == null) return params.bytes;
    
    // Resize if needed
    img.Image resized = image;
    if (image.width > params.maxWidth || image.height > params.maxHeight) {
      resized = img.copyResize(
        image,
        width: image.width > image.height ? params.maxWidth : null,
        height: image.height >= image.width ? params.maxHeight : null,
      );
    }
    
    // Compress and encode as JPEG (removes EXIF data)
    return Uint8List.fromList(img.encodeJpg(resized, quality: params.quality));
  }
  
  /// Optimiert mehrere Bilder für den Upload
  /// 
  /// Verarbeitet eine Liste von Bildern parallel und gibt die optimierten Dateien zurück.
  static Future<List<File>> optimizeImages(List<File> images, {
    int maxWidth = 1080,
    int maxHeight = 1080,
    int quality = 80,
  }) async {
    _log.info('Optimiere ${images.length} Bilder');
    
    final optimizedImages = await Future.wait(
      images.map((image) => optimizeImage(
        image,
        maxWidth: maxWidth,
        maxHeight: maxHeight,
        quality: quality,
      )),
    );
    
    return optimizedImages;
  }
  
  /// Wählt ein Bild aus der Galerie oder Kamera aus
  /// 
  /// Parameter:
  /// - source: Die Quelle des Bildes (Kamera oder Galerie)
  /// - shouldOptimize: Ob das Bild automatisch optimiert werden soll (Standard: true)
  /// 
  /// Gibt die ausgewählte Bilddatei zurück oder null, wenn keine Auswahl getroffen wurde.
  static Future<File?> pickImage(ImageSource source, {bool shouldOptimize = true}) async {
    _log.info('Wähle Bild aus ${source == ImageSource.camera ? "Kamera" : "Galerie"}');
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      final imageFile = File(pickedFile.path);
      
      if (shouldOptimize) {
        return await optimizeImage(imageFile);
      }
      
      return imageFile;
    }
    
    _log.info('Keine Bildauswahl getroffen');
    return null;
  }
  
  /// Wählt mehrere Bilder aus der Galerie aus
  /// 
  /// Parameter:
  /// - shouldOptimize: Ob die Bilder automatisch optimiert werden sollen (Standard: true)
  /// 
  /// Gibt die ausgewählten Bilddateien zurück oder eine leere Liste, wenn keine Auswahl getroffen wurde.
  static Future<List<File>> pickMultipleImages({bool shouldOptimize = true}) async {
    _log.info('Wähle mehrere Bilder aus der Galerie');
    final picker = ImagePicker();
    final pickedFiles = await picker.pickMultiImage();
    
    if (pickedFiles.isEmpty) {
      _log.info('Keine Bilder ausgewählt');
      return [];
    }
    
    final imageFiles = pickedFiles.map((xFile) => File(xFile.path)).toList();
    
    if (shouldOptimize) {
      return await optimizeImages(imageFiles);
    }
    
    return imageFiles;
  }
}

class _ImageProcessParams {
  final Uint8List bytes;
  final int maxWidth;
  final int maxHeight;
  final int quality;
  
  _ImageProcessParams({
    required this.bytes,
    required this.maxWidth,
    required this.maxHeight,
    required this.quality,
  });
} 