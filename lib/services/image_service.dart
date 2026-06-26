import 'dart:io';
import 'dart:math';

import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

/// 图片管理服务 - 复制图片到 app 私有目录，确保路径持久有效
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

  /// 复制图片到 app 私有目录，返回新路径
  Future<String> copyImageToAppDir(String sourcePath) async {
    final dir = await _imageDir;
    final ext = sourcePath.split('.').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), 'jpg');
    final fileName = '${DateTime.now().millisecondsSinceEpoch}_${_randomSuffix()}.$ext';
    final destPath = '${dir.path}/$fileName';
    await File(sourcePath).copy(destPath);
    return destPath;
  }

  /// 从相册选择图片并复制到 app 目录
  Future<List<String>> pickAndCopyImages() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: true,
    );
    if (result == null || result.files.isEmpty) return [];
    final paths = <String>[];
    for (final file in result.files) {
      if (file.path != null) {
        try {
          paths.add(await copyImageToAppDir(file.path!));
        } catch (_) {
          // 跳过复制失败的文件
        }
      }
    }
    return paths;
  }

  /// 拍照并复制到 app 目录
  Future<String?> captureFromCamera() async {
    final xFile = await _picker.pickImage(source: ImageSource.camera);
    if (xFile == null) return null;
    try {
      return await copyImageToAppDir(xFile.path);
    } catch (_) {
      return null;
    }
  }

  /// 删除图片文件
  Future<void> deleteImage(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // ignore
    }
  }

  /// 批量删除图片
  Future<void> deleteImages(List<String> paths) async {
    for (final path in paths) {
      await deleteImage(path);
    }
  }

  /// 迁移旧图片：将原始平台路径的图片复制到 app 目录
  /// 返回 {旧路径: 新路径} 映射，失败的不包含
  Future<Map<String, String>> migrateOldImages(List<String> oldPaths) async {
    final mapping = <String, String>{};
    for (final oldPath in oldPaths) {
      if (oldPath.isEmpty) continue;
      // 跳过已经在 app 目录中的图片
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
        // 跳过无法复制的文件
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
