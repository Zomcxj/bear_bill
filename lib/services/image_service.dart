import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// Image management service - copies images into the app private directory so paths stay valid
class ImageService {
  static final ImageService instance = ImageService._();
  ImageService._();

  final ImagePicker _picker = ImagePicker();

  Future<Directory> get _imageDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${appDir.path}/record_images');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Copy an image into the app private directory and return the new path
  Future<String> copyImageToAppDir(String sourcePath) async {
    final dir = await _imageDir;
    final ext = sourcePath.split('.').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), 'jpg');
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_randomSuffix()}.$ext';
    final destPath = '${dir.path}/$fileName';
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  /// Pick images from the gallery and copy them into the app directory
  Future<List<String>> pickAndCopyImages() async {
    final files = await FilePicker.pickFiles(
      type: FileType.image,
    );
    if (files.isEmpty) return [];
    final paths = <String>[];
    for (final file in files) {
      if (file.path != null) {
        try {
          paths.add(await copyImageToAppDir(file.path!));
        } catch (_) {
          // Skip files that failed to copy
        }
      }
    }
    return paths;
  }

  /// Take a photo and copy it into the app directory
  Future<String?> captureFromCamera() async {
    final xFile = await _picker.pickImage(source: ImageSource.camera);
    if (xFile == null) return null;
    try {
      return await copyImageToAppDir(xFile.path);
    } catch (_) {
      return null;
    }
  }

  /// Delete an image file
  Future<void> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // ignore
    }
  }

  /// Delete images in bulk
  Future<void> deleteImages(List<String> paths) async {
    for (final path in paths) {
      await deleteImage(path);
    }
  }

  /// Migrate legacy images: copy images at their original platform paths into the app directory
  /// Returns an {old path: new path} map; failed entries are omitted
  Future<Map<String, String>> migrateOldImages(List<String> oldPaths) async {
    final mapping = <String, String>{};
    for (final oldPath in oldPaths) {
      if (oldPath.isEmpty) continue;
      // Skip images that are already in the app directory
      if (oldPath.contains('record_images')) {
        mapping[oldPath] = oldPath;
        continue;
      }
      try {
        final file = File(oldPath);
        if (await file.exists()) {
          final newPath = await copyImageToAppDir(oldPath);
          mapping[oldPath] = newPath;
        }
      } catch (_) {
        // Skip files that cannot be copied
      }
    }
    return mapping;
  }

  String _randomSuffix() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final rng = Random();
    return List.generate(6, (_) => chars[rng.nextInt(chars.length)]).join();
  }
}
