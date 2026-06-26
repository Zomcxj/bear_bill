import 'dart:convert';
import 'dart:io';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

import '../services/database_service.dart';

/// 数据库备份服务 - 完整数据导出/导入（数据库 + 图片 + 头像 + 打卡）
class DatabaseBackupService {
  static final DatabaseBackupService instance = DatabaseBackupService._();
  DatabaseBackupService._();
  static const MethodChannel _fileChannel = MethodChannel('bear_bill/files');

  /// 完整备份：数据库 + 图片 + 头像 → ZIP 文件
  Future<bool> exportDatabase(BuildContext context) async {
    try {
      final dbPath = await DatabaseService.instance.databasePath;
      final dbFile = File(dbPath);

      if (!await dbFile.exists()) {
        if (!context.mounted) return false;
        _showSnackBar(context, '数据库文件不存在', isError: true);
        return false;
      }

      if (!context.mounted) return false;
      _showSnackBar(context, '正在打包数据...');

      // 创建临时目录
      final tempDir = await getTemporaryDirectory();
      final exportDir = Directory('${tempDir.path}/bear_bill_export');
      if (await exportDir.exists()) await exportDir.delete(recursive: true);
      await exportDir.create(recursive: true);

      // 1. 复制数据库文件
      await dbFile.copy('${exportDir.path}/bear_bill.db');
      for (final suffix in ['-wal', '-shm']) {
        final f = File('$dbPath$suffix');
        if (await f.exists()) {
          await f.copy('${exportDir.path}/bear_bill.db$suffix');
        }
      }

      // 2. 收集所有图片路径并复制
      final imageMapping = <String, String>{};
      try {
        final db = await DatabaseService.instance.database;
        final records = await db.query('records', columns: ['images']);
        int imgIndex = 0;
        for (final row in records) {
          final imagesStr = row['images'] as String?;
          if (imagesStr == null || imagesStr.isEmpty) continue;
          for (final imgPath in imagesStr.split(',')) {
            final trimmed = imgPath.trim();
            if (trimmed.isEmpty) continue;
            final srcFile = File(trimmed);
            if (await srcFile.exists()) {
              final ext = path.extension(trimmed);
              final newName = 'img_${imgIndex++}$ext';
              await srcFile.copy('${exportDir.path}/$newName');
              imageMapping[trimmed] = newName;
            }
          }
        }
      } catch (_) {}

      // 3. 复制头像
      String? avatarNewName;
      try {
        final db = await DatabaseService.instance.database;
        final users = await db.query('users', columns: ['avatar'], limit: 1);
        if (users.isNotEmpty) {
          final avatarPath = users.first['avatar'] as String?;
          if (avatarPath != null && avatarPath.isNotEmpty) {
            final avatarFile = File(avatarPath);
            if (await avatarFile.exists()) {
              final ext = path.extension(avatarPath);
              avatarNewName = 'avatar$ext';
              await avatarFile.copy('${exportDir.path}/$avatarNewName');
            }
          }
        }
      } catch (_) {}

      // 4. 复制 StorageService 的 key-value 文件
      try {
        final docsDir = await getApplicationDocumentsDirectory();
        final files = docsDir.listSync().whereType<File>();
        for (final f in files) {
          if (path.basename(f.path).startsWith('bear_bill_') &&
              f.path.endsWith('.txt')) {
            await f.copy(
              '${exportDir.path}/${path.basename(f.path)}',
            );
          }
        }
      } catch (_) {}

      // 5. 创建清单文件
      final manifest = {
        'version': 1,
        'app': 'bear_bill',
        'timestamp': DateTime.now().toIso8601String(),
        'imageMapping': imageMapping,
        'avatar': avatarNewName,
      };
      await File('${exportDir.path}/manifest.json')
          .writeAsString(jsonEncode(manifest));

      // 6. 打包为 ZIP
      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final zipFileName = 'bear_bill_backup_$timestamp.zip';
      final zipPath = '${tempDir.path}/$zipFileName';

      await _createZip(exportDir.path, zipPath);

      // 7. 通过系统文件选择器保存
      final targetPath = await _exportFile(
        sourcePath: zipPath,
        suggestedFileName: zipFileName,
      );

      // 清理临时文件
      try {
        await exportDir.delete(recursive: true);
        await File(zipPath).delete();
      } catch (_) {}

      if (targetPath == null || targetPath.isEmpty) return false;

      if (!context.mounted) return false;
      _showSnackBar(context, '备份成功！\n文件位置：$targetPath');
      return true;
    } catch (e) {
      if (!context.mounted) return false;
      _showSnackBar(context, '备份失败：$e', isError: true);
      return false;
    }
  }

  /// 从 ZIP 导入完整数据
  Future<bool> importDatabase(BuildContext context) async {
    try {
      final sourcePath = await _pickImportFile();
      if (!context.mounted) return false;
      if (sourcePath == null || sourcePath.isEmpty) {
        _showSnackBar(context, '未选择文件', isError: true);
        return false;
      }

      final sourceFile = File(sourcePath);
      if (!await sourceFile.exists()) {
        if (!context.mounted) return false;
        _showSnackBar(context, '所选文件不存在', isError: true);
        return false;
      }

      if (!context.mounted) return false;
      final fileName = path.basename(sourcePath).toLowerCase();
      final isZip = fileName.endsWith('.zip');
      final isDb = fileName.endsWith('.db') ||
          fileName.endsWith('.sqlite') ||
          fileName.endsWith('.sqlite3');

      if (!isZip && !isDb) {
        _showSnackBar(context, '请选择 .zip 或 .db 备份文件', isError: true);
        return false;
      }

      // 旧版 .db 文件直接导入
      if (isDb) {
        return await _importLegacyDb(context, sourceFile);
      }

      // 新版 .zip 文件完整导入
      return await _importZip(context, sourceFile);
    } catch (e) {
      if (!context.mounted) return false;
      _showSnackBar(context, '导入失败：${e.toString()}', isError: true);
      return false;
    }
  }

  /// 导入旧版 .db 文件（兼容）
  Future<bool> _importLegacyDb(BuildContext context, File sourceFile) async {
    final fileSize = await sourceFile.length();
    if (!context.mounted) return false;
    if (fileSize == 0) {
      _showSnackBar(context, '所选文件为空', isError: true);
      return false;
    }

    if (!context.mounted) return false;
    final confirmed = await _confirmImport(context, sourceFile, isLegacy: true);
    if (confirmed != true) return false;

    final dbPath = await DatabaseService.instance.databasePath;
    await DatabaseService.instance.close();
    await Future.delayed(const Duration(milliseconds: 300));

    // 备份当前数据库
    final dbFile = File(dbPath);
    if (await dbFile.exists()) {
      try {
        final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        await dbFile.copy('$dbPath.old_$ts');
      } catch (_) {}
    }

    await dbFile.parent.create(recursive: true);
    await dbFile.writeAsBytes(await sourceFile.readAsBytes(), flush: true);
    DatabaseService.instance.resetConnection();

    if (!context.mounted) return true;
    _showSnackBar(context, '导入成功！请重启应用以生效。', duration: const Duration(seconds: 3));
    return true;
  }

  /// 导入新版 .zip 文件（完整恢复）
  Future<bool> _importZip(BuildContext context, File sourceFile) async {
    final confirmed = await _confirmImport(context, sourceFile);
    if (confirmed != true) return false;

    // 解压 ZIP
    final bytes = await sourceFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory('${tempDir.path}/bear_bill_import');
    if (await extractDir.exists()) await extractDir.delete(recursive: true);
    await extractDir.create(recursive: true);

    for (final file in archive) {
      if (file.isFile) {
        // 防止 Zip Slip 路径穿越攻击
        final fileName = file.name;
        if (fileName.contains('..') || fileName.startsWith('/') || fileName.startsWith('\\')) {
          continue; // 跳过可疑路径
        }
        final outFile = File('${extractDir.path}/$fileName');
        final canonicalOut = outFile.path;
        if (!canonicalOut.startsWith(extractDir.path)) {
          continue; // 路径逃逸，跳过
        }
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }

    // 读取清单
    final manifestFile = File('${extractDir.path}/manifest.json');
    Map<String, dynamic> manifest = {};
    if (await manifestFile.exists()) {
      manifest = jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
    }
    final imageMapping = manifest['imageMapping'] as Map<String, dynamic>? ?? {};
    final avatarName = manifest['avatar'] as String?;

    // 关闭当前数据库
    await DatabaseService.instance.close();
    await Future.delayed(const Duration(milliseconds: 300));

    final dbPath = await DatabaseService.instance.databasePath;
    final dbFile = File(dbPath);

    // 备份当前数据库
    if (await dbFile.exists()) {
      try {
        final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        await dbFile.copy('$dbPath.old_$ts');
      } catch (_) {}
    }

    // 1. 恢复数据库
    final exportedDb = File('${extractDir.path}/bear_bill.db');
    if (await exportedDb.exists()) {
      await dbFile.parent.create(recursive: true);
      await dbFile.writeAsBytes(await exportedDb.readAsBytes(), flush: true);
    }

    // 2. 恢复图片文件
    final docsDir = await getApplicationDocumentsDirectory();
    final imagesDir = Directory('${docsDir.path}/bear_bill_images');
    if (!await imagesDir.exists()) await imagesDir.create(recursive: true);

    for (final entry in imageMapping.entries) {
      final newName = entry.value as String;
      final srcFile = File('${extractDir.path}/$newName');
      if (await srcFile.exists()) {
        final destFile = File('${imagesDir.path}/$newName');
        await srcFile.copy(destFile.path);
      }
    }

    // 3. 恢复头像
    if (avatarName != null) {
      final srcAvatar = File('${extractDir.path}/$avatarName');
      if (await srcAvatar.exists()) {
        final destAvatar = File('${imagesDir.path}/$avatarName');
        await srcAvatar.copy(destAvatar.path);
      }
    }

    // 4. 恢复 StorageService 文件
    for (final file in archive) {
      if (file.isFile && file.name.startsWith('bear_bill_') && file.name.endsWith('.txt')) {
        final outFile = File('${docsDir.path}/${file.name}');
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }

    // 5. 更新数据库中的图片路径和头像路径
    DatabaseService.instance.resetConnection();
    try {
      final db = await DatabaseService.instance.database;

      // 更新记录中的图片路径
      if (imageMapping.isNotEmpty) {
        final records = await db.query('records', columns: ['id', 'images']);
        for (final row in records) {
          final id = row['id'] as String;
          final imagesStr = row['images'] as String?;
          if (imagesStr == null || imagesStr.isEmpty) continue;

          final newPaths = <String>[];
          for (final oldPath in imagesStr.split(',')) {
            final trimmed = oldPath.trim();
            if (trimmed.isEmpty) continue;
            final newName = imageMapping[trimmed];
            if (newName != null) {
              newPaths.add('${imagesDir.path}/$newName');
            } else {
              newPaths.add(trimmed);
            }
          }
          await db.update('records', {'images': newPaths.join(',')},
              where: 'id = ?', whereArgs: [id]);
        }
      }

      // 更新头像路径
      if (avatarName != null) {
        await db.update('users', {'avatar': '${imagesDir.path}/$avatarName'});
      }
    } catch (_) {}

    // 清理
    try {
      await extractDir.delete(recursive: true);
    } catch (_) {}

    if (!context.mounted) return true;
    _showSnackBar(context, '导入成功！请重启应用以生效。', duration: const Duration(seconds: 3));
    return true;
  }

  Future<bool?> _confirmImport(BuildContext context, File file, {bool isLegacy = false}) async {
    final fileSize = await file.length();
    if (!context.mounted) return null;
    final fileName = path.basename(file.path);
    final desc = isLegacy ? '导入数据库将覆盖当前所有数据' : '导入将恢复数据库、图片和头像数据';

    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('确认导入'),
        content: Text(
          '文件：$fileName\n大小：${(fileSize / 1024).toStringAsFixed(1)} KB\n\n$desc，此操作不可撤销。\n\n确定继续？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('确认导入'),
          ),
        ],
      ),
    );
  }

  /// 创建 ZIP 文件
  Future<void> _createZip(String sourceDir, String zipPath) async {
    final archive = Archive();
    final dir = Directory(sourceDir);

    await for (final entity in dir.list(recursive: true)) {
      if (entity is File) {
        final relativePath = path.relative(entity.path, from: sourceDir);
        final bytes = await entity.readAsBytes();
        archive.addFile(ArchiveFile(relativePath, bytes.length, bytes));
      }
    }

    final zipData = ZipEncoder().encode(archive);
    if (zipData != null) {
      await File(zipPath).writeAsBytes(zipData);
    }
  }

  Future<String?> _exportFile({
    required String sourcePath,
    required String suggestedFileName,
  }) async {
    if (Platform.isAndroid) {
      return _fileChannel.invokeMethod<String>(
        'exportFile',
        {'sourcePath': sourcePath, 'suggestedFileName': suggestedFileName},
      );
    }

    final targetPath = await FilePicker.platform.saveFile(
      dialogTitle: '选择导出位置',
      fileName: suggestedFileName,
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (targetPath == null || targetPath.isEmpty) return null;

    await File(sourcePath).copy(targetPath);
    return targetPath;
  }

  Future<String?> _pickImportFile() async {
    if (Platform.isAndroid) {
      return _fileChannel.invokeMethod<String>('pickFile');
    }

    final result = await FilePicker.platform.pickFiles(
      dialogTitle: '选择备份文件',
      type: FileType.any,
      allowMultiple: false,
    );
    return result?.files.first.path;
  }

  void _showSnackBar(
    BuildContext context,
    String message, {
    bool isError = false,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : const Color(0xFF6BCB77),
        duration: duration,
      ),
    );
  }
}
