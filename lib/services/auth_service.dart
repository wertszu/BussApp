import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:logging/logging.dart';
import '../models/user.dart' as app_user;
import 'database_service.dart';
import 'dart:math';

class AuthService {
  final DatabaseService _db;
  final _logger = Logger('AuthService');
  app_user.User? _currentUser;

  AuthService(this._db);

  app_user.User? get currentUser => _currentUser;

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<app_user.User?> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
    DateTime? birthDate,
  }) async {
    try {
      // Check if user already exists
      final existingUser = await _db.getUserByEmail(email);
      if (existingUser != null) {
        throw Exception('User with this email already exists');
      }

      // Create new user
      final user = app_user.User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        firstName: firstName,
        lastName: lastName,
        phoneNumber: phoneNumber,
        birthDate: birthDate,
      );

      // Store user in database
      await _db.insertUser(user);

      // Store hashed password
      final hashedPassword = _hashPassword(password);
      await _db.storePassword(user.id, hashedPassword);

      _currentUser = user;
      return user;
    } catch (e) {
      _logger.severe('Error registering user', e);
      rethrow;
    }
  }

  Future<app_user.User?> signIn(String email, String password) async {
    try {
      final user = await _db.getUserByEmail(email);
      if (user == null) {
        throw Exception('User not found');
      }

      // Verify password
      final hashedPassword = _hashPassword(password);
      final storedHashedPassword = await _db.getHashedPassword(user.id);
      
      if (storedHashedPassword == null || storedHashedPassword != hashedPassword) {
        throw Exception('Invalid password');
      }

      _currentUser = user;
      return user;
    } catch (e) {
      _logger.severe('Error signing in', e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    _currentUser = null;
  }

  Future<void> resetPassword(String email) async {
    try {
      final user = await _db.getUserByEmail(email);
      if (user == null) {
        throw Exception('Пользователь с таким email не найден');
      }

      // Генерируем временный пароль
      final tempPassword = _generateTempPassword();
      final hashedPassword = _hashPassword(tempPassword);

      // Сохраняем новый пароль
      await _db.storePassword(user.id, hashedPassword);

      _logger.info('Временный пароль для ${user.email}: $tempPassword');

      // Добавляем уведомление о сбросе пароля
      await _db.addNotification(
        AppNotification(
          id: DateTime.now().millisecondsSinceEpoch,
          userId: user.id,
          title: 'Сброс пароля',
          message: 'Ваш пароль был сброшен. Пожалуйста, войдите в систему, используя временный пароль, и измените его в настройках профиля.',
          timestamp: DateTime.now(),
          isRead: false,
        ),
      );
    } catch (e) {
      _logger.severe('Ошибка при сбросе пароля', e);
      rethrow;
    }
  }

  String _generateTempPassword() {
    const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final random = Random.secure();
    return List.generate(8, (index) => chars[random.nextInt(chars.length)]).join();
  }

  Future<void> updateProfile(app_user.User user) async {
    try {
      await _db.updateUser(user);
      if (_currentUser?.id == user.id) {
        _currentUser = user;
      }
    } catch (e) {
      _logger.severe('Error updating profile', e);
      rethrow;
    }
  }
} 