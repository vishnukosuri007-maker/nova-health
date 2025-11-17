import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:uuid/uuid.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'database_service.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _storage = const FlutterSecureStorage();
  final _db = DatabaseService();
  final _uuid = const Uuid();

  static const String _keyPassword = 'user_password';
  static const String _keyEmail = 'user_email';

  // Hash password
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Sign up
  Future<AuthResult> signUp({
    required String email,
    required String password,
    required String username,
    String? fullName,
    String? gender,
    DateTime? dateOfBirth,
  }) async {
    try {
      // Check if user already exists
      final existingUsers = _db.getAllUsers();
      if (existingUsers.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
        return AuthResult(
          success: false,
          message: 'An account with this email already exists',
        );
      }

      if (existingUsers.any((u) => u.username.toLowerCase() == username.toLowerCase())) {
        return AuthResult(
          success: false,
          message: 'This username is already taken',
        );
      }

      // Create new user
      final userId = _uuid.v4();
      final now = DateTime.now();

      final user = UserModel(
        id: userId,
        email: email.trim().toLowerCase(),
        username: username.trim(),
        fullName: fullName?.trim(),
        gender: gender,
        dateOfBirth: dateOfBirth,
        createdAt: now,
        updatedAt: now,
        notificationPreferences: {
          'hydration': true,
          'workout': true,
          'meal': true,
          'period': true,
        },
      );

      // Save user to database
      await _db.saveUser(user);

      // Store credentials securely
      await _storage.write(key: '${_keyPassword}_$userId', value: _hashPassword(password));
      await _storage.write(key: '${_keyEmail}_$userId', value: email.toLowerCase());

      // Mark as logged in
      await _db.saveSetting(AppConstants.keyIsLoggedIn, true);
      await _db.saveSetting(AppConstants.keyUserId, userId);

      return AuthResult(
        success: true,
        message: 'Account created successfully',
        user: user,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to create account: ${e.toString()}',
      );
    }
  }

  // Login
  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      // Find user by email OR username
      final users = _db.getAllUsers();
      final user = users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase() ||
               u.username.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );

      // Verify password
      final storedPasswordHash = await _storage.read(key: '${_keyPassword}_${user.id}');
      final enteredPasswordHash = _hashPassword(password);

      if (storedPasswordHash != enteredPasswordHash) {
        return AuthResult(
          success: false,
          message: 'Invalid email or password',
        );
      }

      // Mark as logged in
      await _db.saveSetting(AppConstants.keyIsLoggedIn, true);
      await _db.saveSetting(AppConstants.keyUserId, user.id);

      return AuthResult(
        success: true,
        message: 'Login successful',
        user: user,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Invalid email or password',
      );
    }
  }

  // Logout
  Future<void> logout() async {
    await _db.saveSetting(AppConstants.keyIsLoggedIn, false);
    await _db.deleteSetting(AppConstants.keyUserId);
  }

  // Check if logged in
  bool isLoggedIn() {
    return _db.getSetting(AppConstants.keyIsLoggedIn, defaultValue: false) as bool;
  }

  // Get current user
  UserModel? getCurrentUser() {
    final userId = _db.getSetting(AppConstants.keyUserId);
    if (userId == null) return null;
    return _db.getUser(userId);
  }

  // Get current user ID
  String? getCurrentUserId() {
    return _db.getSetting(AppConstants.keyUserId);
  }

  // Update password
  Future<AuthResult> updatePassword({
    required String userId,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      // Verify old password
      final storedPasswordHash = await _storage.read(key: '${_keyPassword}_$userId');
      final oldPasswordHash = _hashPassword(oldPassword);

      if (storedPasswordHash != oldPasswordHash) {
        return AuthResult(
          success: false,
          message: 'Current password is incorrect',
        );
      }

      // Update password
      await _storage.write(key: '${_keyPassword}_$userId', value: _hashPassword(newPassword));

      return AuthResult(
        success: true,
        message: 'Password updated successfully',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to update password: ${e.toString()}',
      );
    }
  }

  // Delete account
  Future<AuthResult> deleteAccount(String userId, String password) async {
    try {
      // Verify password
      final storedPasswordHash = await _storage.read(key: '${_keyPassword}_$userId');
      final enteredPasswordHash = _hashPassword(password);

      if (storedPasswordHash != enteredPasswordHash) {
        return AuthResult(
          success: false,
          message: 'Password is incorrect',
        );
      }

      // Delete user data
      await _db.deleteUser(userId);
      await _storage.delete(key: '${_keyPassword}_$userId');
      await _storage.delete(key: '${_keyEmail}_$userId');

      // Logout
      await logout();

      return AuthResult(
        success: true,
        message: 'Account deleted successfully',
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: 'Failed to delete account: ${e.toString()}',
      );
    }
  }

  // Password reset (simplified - without email)
  Future<AuthResult> resetPassword({
    required String email,
  }) async {
    try {
      // Find user by email
      final users = _db.getAllUsers();
      users.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw Exception('User not found'),
      );

      // In a real app, you would send an email here
      // For now, we'll just return success
      return AuthResult(
        success: true,
        message: 'Password reset instructions sent to your email',
      );
    } catch (e) {
      // For security, don't reveal if email exists
      return AuthResult(
        success: true,
        message: 'If an account exists with this email, password reset instructions have been sent',
      );
    }
  }
}

// Auth result class
class AuthResult {
  final bool success;
  final String message;
  final UserModel? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}
