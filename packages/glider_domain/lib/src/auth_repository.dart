import 'package:glider_data/glider_data.dart';

export 'package:glider_data/glider_data.dart' show LogInResult;

class const AuthRepository(
  final HackerNewsWebsiteService _hackerNewsWebsiteService,
  final SecureStorageService _secureStorageService,
  final SharedPreferencesService _sharedPreferencesService,
) {
  Future<(String? username, String? userCookie)> getUserAuth() async {
    // Secure storage can fail to decrypt: the AES key is wrapped by an Android
    // Keystore key that does not survive a cloud restore or device transfer,
    // and flutter_secure_storage 11 dropped the pre-v10 storage backend
    // outright. Either way the stored cookie is unrecoverable, so discard it
    // and present a logged-out app rather than letting the throw escape.
    final String? userCookie;
    try {
      userCookie = await _secureStorageService.getUserCookie();
    } on Object {
      await _secureStorageService.clearUserCookie();
      return (null, null);
    }
    final username = userCookie?.split('&').first;
    return (username, userCookie);
  }

  /// Authenticates against Hacker News and persists the session cookie.
  ///
  /// The password is forwarded to Hacker News only and is never stored.
  Future<LogInResult> logIn({
    required String username,
    required String password,
  }) async {
    final (result, userCookie) = await _hackerNewsWebsiteService.logIn(
      username: username,
      password: password,
    );
    if (userCookie != null) {
      await _secureStorageService.setUserCookie(userCookie);
    }
    return result;
  }

  Future<void> logout() async {
    await _secureStorageService.clearUserCookie();
    await _sharedPreferencesService.setUpvotedIds(ids: []);
    await _sharedPreferencesService.setFavoritedIds(ids: []);
    await _sharedPreferencesService.setFlaggedIds(ids: []);
  }
}
