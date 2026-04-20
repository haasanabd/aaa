import 'dart:io';
import 'package:archive/archive_io.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

class BackupService {
  /// إنشاء نسخة احتياطية كاملة (قاعدة البيانات + المجلد المخفي)
  static Future<String?> createBackup() async {
    try {
      final dbPath = await getDatabasesPath();
      final dbFile = File(p.join(dbPath, 'haa_backup_v2.db'));
      
      final appDir = await getApplicationDocumentsDirectory();
      final vaultDir = Directory(p.join(appDir.path, '.safe_vault'));

      final backupFileName = 'haa_vault_backup_${DateTime.now().millisecondsSinceEpoch}.zip';
      final tempDir = await getTemporaryDirectory();
      final backupPath = p.join(tempDir.path, backupFileName);

      await compute(_runBackupCompression, {
        'backupPath': backupPath,
        'dbFilePath': dbFile.path,
        'vaultDirPath': vaultDir.path,
      });

      final result = await Share.shareXFiles(
        [XFile(backupPath)],
        text: 'نسخة احتياطية آمنة من Haa Backup',
      );

      if (result.status == ShareResultStatus.success) {
        return backupPath;
      }
      return null;
    } catch (e) {
      debugPrint('Backup error: $e');
      rethrow;
    }
  }

  static void _runBackupCompression(Map<String, String> params) {
    final encoder = ZipFileEncoder();
    encoder.create(params['backupPath']!);
    
    // إضافة قاعدة البيانات
    final dbFile = File(params['dbFilePath']!);
    if (dbFile.existsSync()) {
      encoder.addFile(dbFile, 'database.db');
    }
    
    // إضافة محتويات المجلد المخفي
    final vaultDir = Directory(params['vaultDirPath']!);
    if (vaultDir.existsSync()) {
      _addDirectoryToZipSync(encoder, vaultDir, 'vault');
    }
    
    encoder.close();
  }

  static void _addDirectoryToZipSync(ZipFileEncoder encoder, Directory dir, String zipPath) {
    final files = dir.listSync(recursive: false);
    for (final file in files) {
      final fileName = p.basename(file.path);
      if (file is File) {
        encoder.addFile(file, p.join(zipPath, fileName));
      }
    }
  }

  static Future<bool> pickAndRestoreBackup() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['zip'],
      );

      if (result != null && result.files.single.path != null) {
        return await restoreBackup(result.files.single.path!);
      }
      return false;
    } catch (e) {
      debugPrint('Pick error: $e');
      return false;
    }
  }

  static Future<bool> restoreBackup(String zipPath) async {
    try {
      final dbPath = await getDatabasesPath();
      final targetDbPath = p.join(dbPath, 'haa_backup_v2.db');
      
      final appDir = await getApplicationDocumentsDirectory();
      final targetVaultPath = p.join(appDir.path, '.safe_vault');

      final success = await compute(_runRestoreDecompression, {
        'zipPath': zipPath,
        'targetDbPath': targetDbPath,
        'targetVaultPath': targetVaultPath,
      });

      return success;
    } catch (e) {
      debugPrint('Restore error: $e');
      return false;
    }
  }

  static bool _runRestoreDecompression(Map<String, String> params) {
    try {
      final bytes = File(params['zipPath']!).readAsBytesSync();
      final archive = ZipDecoder().decodeBytes(bytes);
      
      final targetDbPath = params['targetDbPath']!;
      final targetVaultPath = params['targetVaultPath']!;

      // تنظيف المجلد القديم قبل الاستعادة
      final vaultDir = Directory(targetVaultPath);
      if (vaultDir.existsSync()) {
        vaultDir.deleteSync(recursive: true);
      }
      vaultDir.createSync(recursive: true);

      for (final file in archive) {
        final data = file.content as List<int>;
        if (file.name == 'database.db') {
          File(targetDbPath)
            ..createSync(recursive: true)
            ..writeAsBytesSync(data);
        } else if (file.name.startsWith('vault/')) {
          final fileName = p.basename(file.name);
          if (fileName.isNotEmpty && fileName != '.safe_vault') {
            File(p.join(targetVaultPath, fileName))
              ..createSync(recursive: true)
              ..writeAsBytesSync(data);
          }
        }
      }
      
      // التأكد من وجود ملف .nomedia بعد الاستعادة
      final noMedia = File(p.join(targetVaultPath, '.nomedia'));
      if (!noMedia.existsSync()) {
        noMedia.createSync();
      }
      
      return true;
    } catch (e) {
      debugPrint('Decompression error: $e');
      return false;
    }
  }
}
