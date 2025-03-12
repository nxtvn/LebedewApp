import 'package:image_picker/image_picker.dart';
import 'dart:io';

class ImageHelper {
  static Future<File?> pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    
    if (pickedFile != null) {
      return File(pickedFile.path);
    }
    return null;
  }
} 