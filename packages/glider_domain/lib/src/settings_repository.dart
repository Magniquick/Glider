import 'dart:ui';

import 'package:glider_data/glider_data.dart';
import 'package:glider_domain/src/entities/theme_mode.dart';
import 'package:material_color_utilities/dynamiccolor/variant.dart';

class const SettingsRepository(
  final SharedPreferencesService _sharedPreferencesService,
) {
  Future<ThemeMode?> getThemeMode() async {
    final value = await _sharedPreferencesService.getThemeMode();
    return value != null ? ThemeMode.values.byName(value) : null;
  }

  Future<bool> setThemeMode({required ThemeMode value}) =>
      _sharedPreferencesService.setThemeMode(value: value.name);

  Future<bool?> getUseDynamicTheme() =>
      _sharedPreferencesService.getUseDynamicTheme();

  Future<bool> setUseDynamicTheme({required bool value}) =>
      _sharedPreferencesService.setUseDynamicTheme(value: value);

  Future<Color?> getThemeColor() async {
    final value = await _sharedPreferencesService.getThemeColor();
    return value != null ? Color(value) : null;
  }

  Future<bool> setThemeColor({required Color value}) =>
      _sharedPreferencesService.setThemeColor(value: value.toARGB32());

  Future<Variant?> getThemeVariant() async {
    final value = await _sharedPreferencesService.getThemeVariant();
    return value != null ? Variant.values.byName(value) : null;
  }

  Future<bool> setThemeVariant({required Variant value}) =>
      _sharedPreferencesService.setThemeVariant(value: value.name);

  Future<bool?> getUsePureBackground() =>
      _sharedPreferencesService.getUsePureBackground();

  Future<bool> setUsePureBackground({required bool value}) =>
      _sharedPreferencesService.setUsePureBackground(value: value);

  Future<String?> getFont() => _sharedPreferencesService.getFont();

  Future<bool> setFont({required String value}) =>
      _sharedPreferencesService.setFont(value: value);

  Future<int?> getStoryLines() => _sharedPreferencesService.getStoryLines();

  Future<bool> setStoryLines({required int value}) =>
      _sharedPreferencesService.setStoryLines(value: value);

  Future<bool?> getUseLargeStoryStyle() =>
      _sharedPreferencesService.getUseLargeStoryStyle();

  Future<bool> setUseLargeStoryStyle({required bool value}) =>
      _sharedPreferencesService.setUseLargeStoryStyle(value: value);

  Future<bool?> getShowFavicons() =>
      _sharedPreferencesService.getShowFavicons();

  Future<bool> setShowFavicons({required bool value}) =>
      _sharedPreferencesService.setShowFavicons(value: value);

  Future<bool?> getShowStoryMetadata() =>
      _sharedPreferencesService.getShowStoryMetadata();

  Future<bool> setShowStoryMetadata({required bool value}) =>
      _sharedPreferencesService.setShowStoryMetadata(value: value);

  Future<bool?> getShowUserAvatars() =>
      _sharedPreferencesService.getShowUserAvatars();

  Future<bool> setShowUserAvatars({required bool value}) =>
      _sharedPreferencesService.setShowUserAvatars(value: value);

  Future<bool?> getUseActionButtons() =>
      _sharedPreferencesService.getUseActionButtons();

  Future<bool> setUseActionButtons({required bool value}) =>
      _sharedPreferencesService.setUseActionButtons(value: value);

  Future<bool?> getShowJobs() => _sharedPreferencesService.getShowJobs();

  Future<bool> setShowJobs({required bool value}) =>
      _sharedPreferencesService.setShowJobs(value: value);

  Future<bool?> getUseThreadNavigation() =>
      _sharedPreferencesService.getUseThreadNavigation();

  Future<bool> setUseThreadNavigation({required bool value}) =>
      _sharedPreferencesService.setUseThreadNavigation(value: value);

  Future<bool?> getEnableDownvoting() =>
      _sharedPreferencesService.getEnableDownvoting();

  Future<bool> setEnableDownvoting({required bool value}) =>
      _sharedPreferencesService.setEnableDownvoting(value: value);

  Future<bool?> getUseInAppBrowser() =>
      _sharedPreferencesService.getUseInAppBrowser();

  Future<bool> setUseInAppBrowser({required bool value}) =>
      _sharedPreferencesService.setUseInAppBrowser(value: value);

  Future<bool?> getUseNavigationDrawer() =>
      _sharedPreferencesService.getUseNavigationDrawer();

  Future<bool> setUseNavigationDrawer({required bool value}) =>
      _sharedPreferencesService.setUseNavigationDrawer(value: value);

  Future<Set<String>?> getWordFilters() async =>
      (await _sharedPreferencesService.getWordFilters())?.toSet();

  Future<bool> setWordFilter({required String value, required bool filter}) =>
      _sharedPreferencesService.setWordFilter(value: value, filter: filter);

  Future<Set<String>?> getDomainFilters() async =>
      (await _sharedPreferencesService.getDomainFilters())?.toSet();

  Future<bool> setDomainFilter({required String value, required bool filter}) =>
      _sharedPreferencesService.setDomainFilter(value: value, filter: filter);
}
