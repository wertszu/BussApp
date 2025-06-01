import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

class DatabaseInitializer {
  static final _logger = Logger('DatabaseInitializer');
  static bool _initialized = false;

  static Future<void> initialize() async {
    if (_initialized) {
      _logger.info('Database already initialized');
      return;
    }
    
    try {
      if (!kIsWeb) {
        _logger.info('Initializing SQLite FFI');
        
        // Initialize FFI for SQLite
        sqfliteFfiInit();
        
        // Set the database factory
        databaseFactory = databaseFactoryFfi;
        
        _initialized = true;
        _logger.info('SQLite FFI initialized successfully');
      } else {
        _logger.info('Running on web platform, skipping SQLite initialization');
      }
    } catch (e) {
      _logger.severe('Error initializing SQLite FFI: $e');
      rethrow;
    }
  }
} 