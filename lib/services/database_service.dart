import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';
import 'package:logging/logging.dart';
import '../models/user.dart' as app_user;

class AppNotification {
  final int id;
  final String userId;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  AppNotification({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.timestamp,
    required this.isRead,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'is_read': isRead ? 1 : 0,
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map) {
    return AppNotification(
      id: map['id'] as int,
      userId: map['user_id'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: map['is_read'] == 1,
    );
  }
}

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  static Database? _database;
  final _logger = Logger('DatabaseService');

  factory DatabaseService() {
    return _instance;
  }

  DatabaseService._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    try {
      // Используем getDatabasesPath() для получения базового пути
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'bus_app.db');
      _logger.info('Database path: $path');

      return await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate: _createDb,
          onOpen: (db) {
            _logger.info('Database opened successfully');
          },
          onConfigure: (db) async {
            // Включаем поддержку внешних ключей
            await db.execute('PRAGMA foreign_keys = ON');
          },
        ),
      );
    } catch (e, stackTrace) {
      _logger.severe('Error initializing database', e, stackTrace);
      rethrow;
    }
  }

  Future<void> _createDb(Database db, int version) async {
    try {
      await db.transaction((txn) async {
        // Создаем таблицу пользователей
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS users (
            id TEXT PRIMARY KEY,
            email TEXT UNIQUE NOT NULL,
            firstName TEXT NOT NULL,
            lastName TEXT NOT NULL,
            phoneNumber TEXT,
            birthDate TEXT
          )
        ''');

        // Создаем таблицу паролей
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS passwords (
            userId TEXT PRIMARY KEY,
            hashedPassword TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        // Создаем таблицу избранного
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS favorites (
            id TEXT PRIMARY KEY,
            userId TEXT NOT NULL,
            routeId TEXT NOT NULL,
            createdAt TEXT NOT NULL,
            FOREIGN KEY (userId) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');

        // Создаем таблицу уведомлений
        await txn.execute('''
          CREATE TABLE IF NOT EXISTS notifications (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id TEXT NOT NULL,
            title TEXT NOT NULL,
            message TEXT NOT NULL,
            timestamp TEXT NOT NULL,
            is_read INTEGER DEFAULT 0,
            FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
          )
        ''');
      });
      _logger.info('Database tables created successfully');
    } catch (e) {
      _logger.severe('Error creating database tables', e);
      rethrow;
    }
  }

  // User operations
  Future<void> insertUser(app_user.User user) async {
    try {
      final db = await database;
      await db.insert(
        'users',
        user.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _logger.severe('Error inserting user', e);
      rethrow;
    }
  }

  Future<app_user.User?> getUser(String id) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );

      if (maps.isEmpty) return null;
      return app_user.User.fromMap(maps.first);
    } catch (e) {
      _logger.severe('Error getting user', e);
      rethrow;
    }
  }

  Future<app_user.User?> getUserByEmail(String email) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'users',
        where: 'email = ?',
        whereArgs: [email],
      );

      if (maps.isEmpty) return null;
      return app_user.User.fromMap(maps.first);
    } catch (e) {
      _logger.severe('Error getting user by email', e);
      rethrow;
    }
  }

  Future<void> updateUser(app_user.User user) async {
    try {
      final db = await database;
      await db.update(
        'users',
        user.toMap(),
        where: 'id = ?',
        whereArgs: [user.id],
      );
    } catch (e) {
      _logger.severe('Error updating user', e);
      rethrow;
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      final db = await database;
      await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      _logger.severe('Error deleting user', e);
      rethrow;
    }
  }

  // Password operations
  Future<void> storePassword(String userId, String hashedPassword) async {
    try {
      final db = await database;
      await db.insert(
        'passwords',
        {
          'userId': userId,
          'hashedPassword': hashedPassword,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _logger.severe('Error storing password', e);
      rethrow;
    }
  }

  Future<String?> getHashedPassword(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'passwords',
        where: 'userId = ?',
        whereArgs: [userId],
      );

      if (maps.isEmpty) return null;
      return maps.first['hashedPassword'] as String;
    } catch (e) {
      _logger.severe('Error getting hashed password', e);
      rethrow;
    }
  }

  // Favorites operations
  Future<void> addFavorite(String userId, String routeId) async {
    try {
      final db = await database;
      await db.insert(
        'favorites',
        {
          'id': DateTime.now().millisecondsSinceEpoch.toString(),
          'userId': userId,
          'routeId': routeId,
          'createdAt': DateTime.now().toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _logger.severe('Error adding favorite', e);
      rethrow;
    }
  }

  Future<void> removeFavorite(String userId, String routeId) async {
    try {
      final db = await database;
      await db.delete(
        'favorites',
        where: 'userId = ? AND routeId = ?',
        whereArgs: [userId, routeId],
      );
    } catch (e) {
      _logger.severe('Error removing favorite', e);
      rethrow;
    }
  }

  Future<List<String>> getFavorites(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'favorites',
        where: 'userId = ?',
        whereArgs: [userId],
      );

      return maps.map((map) => map['routeId'] as String).toList();
    } catch (e) {
      _logger.severe('Error getting favorites', e);
      rethrow;
    }
  }

  // Notification operations
  Future<void> insertNotification(Map<String, dynamic> notification) async {
    try {
      final db = await database;
      await db.insert(
        'notifications',
        notification,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _logger.severe('Error inserting notification', e);
      rethrow;
    }
  }

  Future<void> createTables(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS users (
        id TEXT PRIMARY KEY,
        email TEXT UNIQUE,
        name TEXT,
        created_at TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorites (
        user_id TEXT,
        route_id TEXT,
        created_at TEXT,
        PRIMARY KEY (user_id, route_id),
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS passwords (
        user_id TEXT PRIMARY KEY,
        password_hash TEXT,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id TEXT NOT NULL,
        title TEXT NOT NULL,
        message TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        is_read INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');
  }

  // Notification methods
  Future<List<AppNotification>> getNotifications(String userId) async {
    try {
      final db = await database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notifications',
        where: 'user_id = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
      );

      return List.generate(maps.length, (i) {
        return AppNotification.fromMap(maps[i]);
      });
    } catch (e) {
      _logger.severe('Error getting notifications', e);
      rethrow;
    }
  }

  Future<void> addNotification(AppNotification notification) async {
    try {
      final db = await database;
      await db.insert(
        'notifications',
        notification.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    } catch (e) {
      _logger.severe('Error adding notification', e);
      rethrow;
    }
  }

  Future<void> markNotificationAsRead(int notificationId) async {
    try {
      final db = await database;
      await db.update(
        'notifications',
        {'is_read': 1},
        where: 'id = ?',
        whereArgs: [notificationId],
      );
    } catch (e) {
      _logger.severe('Error marking notification as read', e);
      rethrow;
    }
  }

  Future<void> deleteNotification(int notificationId) async {
    try {
      final db = await database;
      await db.delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [notificationId],
      );
    } catch (e) {
      _logger.severe('Error deleting notification', e);
      rethrow;
    }
  }

  Future<void> clearNotifications(String userId) async {
    try {
      final db = await database;
      await db.delete(
        'notifications',
        where: 'user_id = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      _logger.severe('Error clearing notifications', e);
      rethrow;
    }
  }
} 