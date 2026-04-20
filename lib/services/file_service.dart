import 'dart:io';
import 'dart:typed_data';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../data/database_helper.dart';

class FileService {
  /// الحصول على مسار المجلد الخاص والمخفي داخل التطبيق
  static Future<String> get _privateMediaFolder async {
    final directory = await getApplicationDocumentsDirectory();
    final path = p.join(directory.path, '.safe_vault'); // مجلد يبدأ بنقطة ليكون مخفياً في أنظمة لينكس/أندرويد
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      // إضافة ملف .nomedia لضمان عدم قيام المعرض بمسح المجلد
      final noMedia = File(p.join(path, '.nomedia'));
      if (!await noMedia.exists()) {
        await noMedia.create();
      }
    }
    return path;
  }

  /// معالجة وحفظ الملف في المجلد الخاص وتسجيله في قاعدة البيانات
  static Future<bool> processAndSaveMedia(File sourceFile, String type) async {
    try {
      final folderPath = await _privateMediaFolder;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = p.extension(sourceFile.path);
      
      // اسم ملف مشفر (غير واضح المحتوى)
      final internalFileName = 'data_${timestamp}_${(timestamp % 1000).toString()}$extension';
      final targetPath = p.join(folderPath, internalFileName);

      // نسخ الملف الأصلي للمجلد الخاص
      await sourceFile.copy(targetPath);

      Uint8List? thumbnailData;
      if (type == 'image') {
        // إنشاء صورة مصغرة فائقة الضغط (WebP إذا أمكن أو JPEG بجودة منخفضة)
        thumbnailData = await FlutterImageCompress.compressWithList(
          await sourceFile.readAsBytes(),
          minHeight: 150,
          minWidth: 150,
          quality: 40,
          format: CompressFormat.jpeg,
        );
      }

      await DatabaseHelper.instance.insertMedia({
        'file_name': p.basename(sourceFile.path),
        'internal_path': internalFileName,
        'thumbnail_data': thumbnailData,
        'type': type,
        'created_at': DateTime.now().toIso8601String(),
        'original_path': sourceFile.path,
      });

      return true;
    } catch (e) {
      debugPrint('Error processing media: $e');
      return false;
    }
  }

  /// الحصول على الملف الأصلي من المجلد الخاص (للعرض أو التنزيل)
  static Future<File?> getMediaFile(String internalFileName) async {
    try {
      final folderPath = await _privateMediaFolder;
      final file = File(p.join(folderPath, internalFileName));
      if (await file.exists()) {
        return file;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting media file: $e');
      return null;
    }
  }

  /// حذف الملف من المجلد الخاص ومن قاعدة البيانات
  static Future<void> deleteMedia(int id, String internalFileName) async {
    try {
      final folderPath = await _privateMediaFolder;
      final file = File(p.join(folderPath, internalFileName));
      if (await file.exists()) {
        await file.delete();
      }
      await DatabaseHelper.instance.deleteMedia(id);
    } catch (e) {
      debugPrint('Error deleting media: $e');
    }
  }
}
