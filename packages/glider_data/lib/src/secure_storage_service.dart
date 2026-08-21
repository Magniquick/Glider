import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class const SecureStorageService(
  final FlutterSecureStorage _flutterSecureStorage,
) {
  static const String _userCookieKey = 'userCookie';

  Future<String?> getUserCookie() =>
      _flutterSecureStorage.read(key: _userCookieKey);

  Future<void> setUserCookie(String value) =>
      _flutterSecureStorage.write(key: _userCookieKey, value: value);

  Future<void> clearUserCookie() =>
      _flutterSecureStorage.delete(key: _userCookieKey);
}
