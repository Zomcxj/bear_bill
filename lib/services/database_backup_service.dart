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
import '../widgets/glass_dialog_shell.dart';

/// Database backup service - full data export/import (database + images + avatar + check-in)
class DatabaseBackupService {
  static final DatabaseBackupService instance = DatabaseBackupService._();
  DatabaseBackupService._();
  static const MethodChannel _fileChannel = MethodChannel('bear_bill/files');

  /// Full backup: database + images + avatar -> ZIP file
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

      // Create a temporary directory
      final tempDir = await getTemporaryDirectory();
      final exportDir = Directory('${tempDir.path}/bear_bill_export');
      if (await exportDir.exists()) await exportDir.delete(recursive: true);
      await exportDir.create(recursive: true);

      // 1. Copy the database file
      await dbFile.copy('${exportDir.path}/bear_bill.db');
      for (final suffix in ['-wal', '-shm']) {
        final f = File('$dbPath$suffix');
        if (await f.exists()) {
          await f.copy('${exportDir.path}/bear_bill.db$suffix');
        }
      }

      // 2. Collect all image paths and copy them
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

      // 3. Copy the avatar
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

      // 4. Copy the StorageService key-value files
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

      // 5. Create the manifest file
      final manifest = {
        'version': 1,
        'app': 'bear_bill',
        'timestamp': DateTime.now().toIso8601String(),
        'imageMapping': imageMapping,
        'avatar': avatarNewName,
      };
      await File('${exportDir.path}/manifest.json')
          .writeAsString(jsonEncode(manifest));

      // 6. Pack into a ZIP
      final now = DateTime.now();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(now);
      final zipFileName = 'bear_bill_backup_$timestamp.zip';
      final zipPath = '${tempDir.path}/$zipFileName';

      await _createZip(exportDir.path, zipPath);

      // 7. Save through the system file picker
      final targetPath = await _exportFile(
        sourcePath: zipPath,
        suggestedFileName: zipFileName,
      );

      // Clean up temporary files
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

  /// Import full data from a ZIP
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

      // Legacy .db files are imported directly
      if (isDb) {
        return await _importLegacyDb(context, sourceFile);
      }

      // Full import for newer .zip files
      return await _importZip(context, sourceFile);
    } catch (e) {
      if (!context.mounted) return false;
      _showSnackBar(context, '导入失败：${e.toString()}', isError: true);
      return false;
    }
  }

  /// Import a legacy .db file (compatibility)
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

    // Back up the current database
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
    _showSnackBar(context, '导入成功！请重启应用以生效。',
        duration: const Duration(seconds: 3));
    return true;
  }

  /// Import a newer .zip file (full restore)
  Future<bool> _importZip(BuildContext context, File sourceFile) async {
    final confirmed = await _confirmImport(context, sourceFile);
    if (confirmed != true) return false;

    // Extract the ZIP
    final bytes = await sourceFile.readAsBytes();
    final archive = ZipDecoder().decodeBytes(bytes);

    final tempDir = await getTemporaryDirectory();
    final extractDir = Directory('${tempDir.path}/bear_bill_import');
    if (await extractDir.exists()) await extractDir.delete(recursive: true);
    await extractDir.create(recursive: true);

    for (final file in archive) {
      if (file.isFile) {
        // Guard against Zip Slip path traversal attacks
        final fileName = file.name;
        if (fileName.contains('..') ||
            fileName.startsWith('/') ||
            fileName.startsWith('\\')) {
          continue; // Skip suspicious paths
        }
        final outFile = File('${extractDir.path}/$fileName');
        final canonicalOut = outFile.path;
        if (!canonicalOut.startsWith(extractDir.path)) {
          continue; // Path escape; skip
        }
        await outFile.parent.create(recursive: true);
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }

    // Read the manifest
    final manifestFile = File('${extractDir.path}/manifest.json');
    Map<String, dynamic> manifest = {};
    if (await manifestFile.exists()) {
      manifest =
          jsonDecode(await manifestFile.readAsString()) as Map<String, dynamic>;
    }
    final imageMapping =
        manifest['imageMapping'] as Map<String, dynamic>? ?? {};
    final avatarName = manifest['avatar'] as String?;

    // Close the current database
    await DatabaseService.instance.close();
    await Future.delayed(const Duration(milliseconds: 300));

    final dbPath = await DatabaseService.instance.databasePath;
    final dbFile = File(dbPath);

    // Back up the current database
    if (await dbFile.exists()) {
      try {
        final ts = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        await dbFile.copy('$dbPath.old_$ts');
      } catch (_) {}
    }

    // 1. Restore the database
    final exportedDb = File('${extractDir.path}/bear_bill.db');
    if (await exportedDb.exists()) {
      await dbFile.parent.create(recursive: true);
      await dbFile.writeAsBytes(await exportedDb.readAsBytes(), flush: true);
    }

    // 2. Restore image files
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

    // 3. Restore the avatar
    if (avatarName != null) {
      final srcAvatar = File('${extractDir.path}/$avatarName');
      if (await srcAvatar.exists()) {
        final destAvatar = File('${imagesDir.path}/$avatarName');
        await srcAvatar.copy(destAvatar.path);
      }
    }

    // 4. Restore StorageService files
    for (final file in archive) {
      if (file.isFile &&
          file.name.startsWith('bear_bill_') &&
          file.name.endsWith('.txt')) {
        final outFile = File('${docsDir.path}/${file.name}');
        await outFile.writeAsBytes(file.content as List<int>);
      }
    }

    // 5. Update image and avatar paths in the database
    DatabaseService.instance.resetConnection();
    try {
      final db = await DatabaseService.instance.database;

      // Update image paths in records
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

      // Update the avatar path
      if (avatarName != null) {
        await db.update('users', {'avatar': '${imagesDir.path}/$avatarName'});
      }
    } catch (_) {}

    // Clean up
    try {
      await extractDir.delete(recursive: true);
    } catch (_) {}

    if (!context.mounted) return true;
    _showSnackBar(context, '导入成功！请重启应用以生效。',
        duration: const Duration(seconds: 3));
    return true;
  }

  Future<bool?> _confirmImport(BuildContext context, File file,
      {bool isLegacy = false}) async {
    final fileSize = await file.length();
    if (!context.mounted) return null;
    final fileName = path.basename(file.path);
    final desc = isLegacy ? '导入数据库将覆盖当前所有数据' : '导入将恢复数据库、图片和头像数据';

    return await showGlassDialog<bool>(
      context: context,
      title: '确认导入',
      maxWidth: 320,
      content: Text(
        '文件：$fileName\n大小：${(fileSize / 1024).toStringAsFixed(1)} KB\n\n$desc，此操作不可撤销。\n\n确定继续？',
      ),
      buildActions: (ctx) => [
        GlassDialogButton(
          label: '取消',
          onPressed: () => Navigator.pop(ctx, false),
        ),
        GlassDialogButton(
          label: '确认导入',
          isDestructive: true,
          onPressed: () => Navigator.pop(ctx, true),
        ),
      ],
    );
  }

  /// Creates a ZIP file
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

    // file_picker 13: saveFile requires bytes directly and returns a Uri?
    final bytes = await File(sourcePath).readAsBytes();
    final targetUri = await FilePicker.saveFile(
      dialogTitle: '选择导出位置',
      fileName: suggestedFileName,
      bytes: bytes,
      type: FileType.custom,
      allowedExtensions: ['zip'],
    );
    if (targetUri == null) return null;

    return targetUri.toFilePath();
  }

  Future<String?> _pickImportFile() async {
    if (Platform.isAndroid) {
      return _fileChannel.invokeMethod<String>('pickFile');
    }

    // file_picker 13: use pickFile for single selection (pickFiles is multi-select and has no allowMultiple parameter)
    final file = await FilePicker.pickFile(
      dialogTitle: '选择备份文件',
      type: FileType.any,
    );
    return file?.path;
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
