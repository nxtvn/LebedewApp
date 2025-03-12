import 'dart:io';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

class ImageUtils {
  static Future<File> optimizeImage(File originalImage, {
    int maxWidth = 1080,
    int maxHeight = 1080,
    int quality = 80,
  }) async {
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
    
    return optimizedFile;
  }

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