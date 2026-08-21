import 'package:shared_preferences/shared_preferences.dart';

class const SharedPreferencesService(
  final SharedPreferencesAsync _sharedPreferences,
) {
  static const String _themeModeKey = 'theme_mode';
  static const String _useDynamicThemeKey = 'use_dynamic_theme';
  static const String _themeColorKey = 'theme_color';
  static const String _themeVariantKey = 'theme_variant';
  static const String _usePureBackgroundKey = 'use_pure_background';
  static const String _fontKey = 'font';
  static const String _storyLinesKey = 'story_lines';
  static const String _useLargeStoryStyleKey = 'use_large_story_style';
  static const String _showFaviconsKey = 'show_favicons';
  static const String _useBrandIconsKey = 'use_brand_icons';
  static const String _showStoryMetadataKey = 'show_story_metadata';
  static const String _showUserAvatars = 'show_user_avatars';
  static const String _useActionButtonsKey = 'use_action_buttons';
  static const String _showJobsKey = 'show_jobs';
  static const String _useThreadNavigationKey = 'use_thread_navigation';
  static const String _enableDownvotingKey = 'enable_downvoting';
  static const String _useInAppBrowserKey = 'use_in_app_browser';
  static const String _useNavigationDrawerKey = 'use_navigation_drawer';
  static const String _wordFiltersKey = 'word_filters';
  static const String _domainFiltersKey = 'domain_filters';
  static const String _lastVersionKey = 'last_version';
  static const String _visitedKey = 'visited';
  static const String _upvotedKey = 'upvoted';
  static const String _downvotedKey = 'downvoted';
  static const String _favoritedKey = 'favorited';
  static const String _flaggedKey = 'flagged';
  static const String _blockedKey = 'blocked';

  Future<String?> getThemeMode() async =>
      _sharedPreferences.getString(_themeModeKey);

  Future<void> setThemeMode({required String value}) =>
      _sharedPreferences.setString(_themeModeKey, value);

  Future<bool?> getUseDynamicTheme() async =>
      _sharedPreferences.getBool(_useDynamicThemeKey);

  Future<void> setUseDynamicTheme({required bool value}) =>
      _sharedPreferences.setBool(_useDynamicThemeKey, value);

  Future<int?> getThemeColor() async =>
      _sharedPreferences.getInt(_themeColorKey);

  Future<void> setThemeColor({required int value}) =>
      _sharedPreferences.setInt(_themeColorKey, value);

  Future<String?> getThemeVariant() async =>
      _sharedPreferences.getString(_themeVariantKey);

  Future<void> setThemeVariant({required String value}) =>
      _sharedPreferences.setString(_themeVariantKey, value);

  Future<bool?> getUsePureBackground() async =>
      _sharedPreferences.getBool(_usePureBackgroundKey);

  Future<void> setUsePureBackground({required bool value}) =>
      _sharedPreferences.setBool(_usePureBackgroundKey, value);

  Future<String?> getFont() async => _sharedPreferences.getString(_fontKey);

  Future<void> setFont({required String value}) =>
      _sharedPreferences.setString(_fontKey, value);

  Future<int?> getStoryLines() async =>
      _sharedPreferences.getInt(_storyLinesKey);

  Future<void> setStoryLines({required int value}) =>
      _sharedPreferences.setInt(_storyLinesKey, value);

  Future<bool?> getUseLargeStoryStyle() async =>
      _sharedPreferences.getBool(_useLargeStoryStyleKey);

  Future<void> setUseLargeStoryStyle({required bool value}) =>
      _sharedPreferences.setBool(_useLargeStoryStyleKey, value);

  Future<bool?> getShowFavicons() async =>
      _sharedPreferences.getBool(_showFaviconsKey);

  Future<void> setShowFavicons({required bool value}) =>
      _sharedPreferences.setBool(_showFaviconsKey, value);

  Future<bool?> getUseBrandIcons() async =>
      _sharedPreferences.getBool(_useBrandIconsKey);

  Future<void> setUseBrandIcons({required bool value}) =>
      _sharedPreferences.setBool(_useBrandIconsKey, value);

  Future<bool?> getShowStoryMetadata() async =>
      _sharedPreferences.getBool(_showStoryMetadataKey);

  Future<void> setShowStoryMetadata({required bool value}) =>
      _sharedPreferences.setBool(_showStoryMetadataKey, value);

  Future<bool?> getShowUserAvatars() async =>
      _sharedPreferences.getBool(_showUserAvatars);

  Future<void> setShowUserAvatars({required bool value}) =>
      _sharedPreferences.setBool(_showUserAvatars, value);

  Future<bool?> getUseActionButtons() async =>
      _sharedPreferences.getBool(_useActionButtonsKey);

  Future<void> setUseActionButtons({required bool value}) =>
      _sharedPreferences.setBool(_useActionButtonsKey, value);

  Future<bool?> getShowJobs() async => _sharedPreferences.getBool(_showJobsKey);

  Future<void> setShowJobs({required bool value}) =>
      _sharedPreferences.setBool(_showJobsKey, value);

  Future<bool?> getUseThreadNavigation() async =>
      _sharedPreferences.getBool(_useThreadNavigationKey);

  Future<void> setUseThreadNavigation({required bool value}) =>
      _sharedPreferences.setBool(_useThreadNavigationKey, value);

  Future<bool?> getEnableDownvoting() async =>
      _sharedPreferences.getBool(_enableDownvotingKey);

  Future<void> setEnableDownvoting({required bool value}) =>
      _sharedPreferences.setBool(_enableDownvotingKey, value);

  Future<bool?> getUseInAppBrowser() async =>
      _sharedPreferences.getBool(_useInAppBrowserKey);

  Future<void> setUseInAppBrowser({required bool value}) =>
      _sharedPreferences.setBool(_useInAppBrowserKey, value);

  Future<bool?> getUseNavigationDrawer() async =>
      _sharedPreferences.getBool(_useNavigationDrawerKey);

  Future<void> setUseNavigationDrawer({required bool value}) =>
      _sharedPreferences.setBool(_useNavigationDrawerKey, value);

  Future<List<String>?> getWordFilters() async =>
      _sharedPreferences.getStringList(_wordFiltersKey);

  Future<void> setWordFilter({required String value, required bool filter}) {
    if (filter) {
      return _sharedPreferences.addElement(_wordFiltersKey, value);
    } else {
      return _sharedPreferences.removeElement(_wordFiltersKey, value);
    }
  }

  Future<List<String>?> getDomainFilters() async =>
      _sharedPreferences.getStringList(_domainFiltersKey);

  Future<void> setDomainFilter({required String value, required bool filter}) {
    if (filter) {
      return _sharedPreferences.addElement(_domainFiltersKey, value);
    } else {
      return _sharedPreferences.removeElement(_domainFiltersKey, value);
    }
  }

  Future<String?> getLastVersion() async =>
      _sharedPreferences.getString(_lastVersionKey);

  Future<void> setLastVersion({required String value}) =>
      _sharedPreferences.setString(_lastVersionKey, value);

  Future<bool> getVisited({required int id}) async =>
      _sharedPreferences.containsElement(_visitedKey, id.toString());

  Future<void> setVisited({required int id, required bool visit}) {
    if (visit) {
      return _sharedPreferences.addElement(_visitedKey, id.toString());
    } else {
      return _sharedPreferences.removeElement(_visitedKey, id.toString());
    }
  }

  Future<List<int>> getVisitedIds() async => [
    ...?(await _sharedPreferences.getStringList(_visitedKey))?.map(int.parse),
  ];

  Future<void> setVisitedIds({required Iterable<int> ids}) {
    return _sharedPreferences.setStringList(_visitedKey, [
      ...ids.map((id) => id.toString()),
    ]);
  }

  Future<bool> getUpvoted({required int id}) async =>
      _sharedPreferences.containsElement(_upvotedKey, id.toString());

  Future<void> setUpvoted({required int id, required bool upvote}) {
    if (upvote) {
      return _sharedPreferences.addElement(_upvotedKey, id.toString());
    } else {
      return _sharedPreferences.removeElement(_upvotedKey, id.toString());
    }
  }

  Future<List<int>> getUpvotedIds() async => [
    ...?(await _sharedPreferences.getStringList(_upvotedKey))?.map(int.parse),
  ];

  Future<void> setUpvotedIds({required Iterable<int> ids}) {
    return _sharedPreferences.setStringList(_upvotedKey, [
      ...ids.map((id) => id.toString()),
    ]);
  }

  Future<bool> getDownvoted({required int id}) async =>
      _sharedPreferences.containsElement(_downvotedKey, id.toString());

  Future<void> setDownvoted({required int id, required bool downvote}) {
    if (downvote) {
      return _sharedPreferences.addElement(_downvotedKey, id.toString());
    } else {
      return _sharedPreferences.removeElement(_downvotedKey, id.toString());
    }
  }

  Future<List<int>> getDownvotedIds() async => [
    ...?(await _sharedPreferences.getStringList(_downvotedKey))?.map(int.parse),
  ];

  Future<void> setDownvotedIds({required Iterable<int> ids}) {
    return _sharedPreferences.setStringList(_downvotedKey, [
      ...ids.map((id) => id.toString()),
    ]);
  }

  Future<bool> getFavorited({required int id}) async =>
      _sharedPreferences.containsElement(_favoritedKey, id.toString());

  Future<void> setFavorited({required int id, required bool favorite}) {
    if (favorite) {
      return _sharedPreferences.addElement(_favoritedKey, id.toString());
    } else {
      return _sharedPreferences.removeElement(_favoritedKey, id.toString());
    }
  }

  Future<List<int>> getFavoritedIds() async => [
    ...?(await _sharedPreferences.getStringList(_favoritedKey))?.map(int.parse),
  ];

  Future<void> setFavoritedIds({required Iterable<int> ids}) {
    return _sharedPreferences.setStringList(_favoritedKey, [
      ...ids.map((id) => id.toString()),
    ]);
  }

  Future<bool> getFlagged({required int id}) async =>
      _sharedPreferences.containsElement(_flaggedKey, id.toString());

  Future<void> setFlagged({required int id, required bool flagged}) {
    if (flagged) {
      return _sharedPreferences.addElement(_flaggedKey, id.toString());
    } else {
      return _sharedPreferences.removeElement(_flaggedKey, id.toString());
    }
  }

  Future<List<int>> getFlaggedIds() async => [
    ...?(await _sharedPreferences.getStringList(_flaggedKey))?.map(int.parse),
  ];

  Future<void> setFlaggedIds({required Iterable<int> ids}) {
    return _sharedPreferences.setStringList(_flaggedKey, [
      ...ids.map((id) => id.toString()),
    ]);
  }

  Future<List<String>> getBlockedUsernames() async => [
    ...?await _sharedPreferences.getStringList(_blockedKey),
  ];

  Future<bool> getBlocked({required String username}) async =>
      _sharedPreferences.containsElement(_blockedKey, username);

  Future<void> setBlocked({required String username, required bool block}) {
    if (block) {
      return _sharedPreferences.addElement(_blockedKey, username);
    } else {
      return _sharedPreferences.removeElement(_blockedKey, username);
    }
  }
}

extension on SharedPreferencesAsync {
  Future<bool> containsElement(String key, String element) async =>
      (await getStringList(key))?.contains(element) ?? false;

  Future<void> addElement(String key, String element) async =>
      setStringList(key, [element, ...await _getDistinctElements(key)]);

  Future<void> removeElement(String key, String element) async => setStringList(
    key,
    [...(await _getDistinctElements(key)).where((e) => e != element)],
  );

  Future<Set<String>> _getDistinctElements(String key) async => {
    ...?await getStringList(key),
  };
}
