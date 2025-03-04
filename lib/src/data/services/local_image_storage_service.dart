import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../../domain/services/image_storage_service.dart';

class LocalImageStorageService implements ImageStorageService {
  final _uuid = const Uuid();

  @override
  Future<String> saveImage(File image) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = '${_uuid.v4()}.jpg';
    final savedImage = await image.copy('${directory.path}/$fileName');
    return savedImage.path;
  }

  @override
  Future<void> deleteImage(String path) async {
    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }
} 