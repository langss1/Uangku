import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageHelper {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: false,
      resetOnError: true,
    ),
  );

  static const String _keyToken = 'token';
  static const String _keyUserName = 'user_name';
  static const String _keyUserEmail = 'user_email';
  static const String _keyDbPassword = 'db_password';

  // Save JWT Token securely
  static Future<void> saveToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  // Get JWT Token securely
  static Future<String?> getToken() async {
    return await _storage.read(key: _keyToken);
  }

  // Delete JWT Token securely
  static Future<void> deleteToken() async {
    await _storage.delete(key: _keyToken);
  }

  // Save profile information securely
  static Future<void> saveUserData({required String name, required String email}) async {
    await _storage.write(key: _keyUserName, value: name);
    await _storage.write(key: _keyUserEmail, value: email);
  }

  // Get User Name securely
  static Future<String?> getUserName() async {
    return await _storage.read(key: _keyUserName);
  }

  // Get User Email securely
  static Future<String?> getUserEmail() async {
    return await _storage.read(key: _keyUserEmail);
  }

  // Save database encryption password securely
  static Future<void> saveDbPassword(String password) async {
    await _storage.write(key: _keyDbPassword, value: password);
  }

  // Get database encryption password securely
  static Future<String?> getDbPassword() async {
    return await _storage.read(key: _keyDbPassword);
  }

  // Clear all secure storage data (on Logout) but preserve the database password key
  static Future<void> clearAll() async {
    final dbPassword = await _storage.read(key: _keyDbPassword);
    await _storage.deleteAll();
    if (dbPassword != null) {
      await _storage.write(key: _keyDbPassword, value: dbPassword);
    }
  }
}
