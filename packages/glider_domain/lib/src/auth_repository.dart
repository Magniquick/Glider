import 'package:glider_data/glider_data.dart';

export 'package:glider_data/glider_data.dart' show LogInResult;

class AuthRepository {
  const AuthRepository(
    this._hackerNewsWebsiteService,
    this._secureStorageService,
    this._sharedPreferencesService,
  );

  final HackerNewsWebsiteService _hackerNewsWebsiteService;
  final SecureStorageService _secureStorageService;
  final SharedPreferencesService _sharedPreferencesService;

  Future<(String? username, String? userCookie)> getUserAuth() async {
    final userCookie = await _secureStorageService.getUserCookie();
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
