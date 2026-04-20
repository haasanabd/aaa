import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('haa_backup_v2.db'); // استخدام اسم جديد لضمان توافق البيانات الجديدة
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE media (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        file_name TEXT NOT NULL,
        internal_path TEXT NOT NULL,
        thumbnail_data BLOB,
        type TEXT NOT NULL,
        created_at TEXT NOT NULL,
        original_path TEXT
      )
    ''');
  }

  Future<int> insertMedia(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('media', row);
  }

  Future<List<Map<String, dynamic>>> queryAllMedia(String type) async {
    final db = await instance.database;
    return await db.query('media', 
      columns: ['id', 'file_name', 'internal_path', 'type', 'created_at', 'thumbnail_data'],
      where: 'type = ?', 
      whereArgs: [type], 
      orderBy: 'created_at DESC'
    );
  }

  Future<Map<String, dynamic>?> getMediaItem(int id) async {
    final db = await instance.database;
    final results = await db.query('media', where: 'id = ?', whereArgs: [id]);
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<int> deleteMedia(int id) async {
    final db = await instance.database;
    return await db.delete('media', where: 'id = ?', whereArgs: [id]);
  }

  Future close() async {
    final db = await instance.database;
    db.close();
  }
}
