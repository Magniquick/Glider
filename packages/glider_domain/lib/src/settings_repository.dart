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

  Future<void> setThemeMode({required ThemeMode value}) =>
      _sharedPreferencesService.setThemeMode(value: value.name);

  Future<bool?> getUseDynamicTheme() =>
      _sharedPreferencesService.getUseDynamicTheme();

  Future<void> setUseDynamicTheme({required bool value}) =>
      _sharedPreferencesService.setUseDynamicTheme(value: value);

  Future<Color?> getThemeColor() async {
    final value = await _sharedPreferencesService.getThemeColor();
    return value != null ? Color(value) : null;
  }

  Future<void> setThemeColor({required Color value}) =>
      _sharedPreferencesService.setThemeColor(value: value.toARGB32());

  Future<Variant?> getThemeVariant() async {
    final value = await _sharedPreferencesService.getThemeVariant();
    return value != null ? Variant.values.byName(value) : null;
  }

  Future<void> setThemeVariant({required Variant value}) =>
      _sharedPreferencesService.setThemeVariant(value: value.name);

  Future<bool?> getUsePureBackground() =>
      _sharedPreferencesService.getUsePureBackground();

  Future<void> setUsePureBackground({required bool value}) =>
      _sharedPreferencesService.setUsePureBackground(value: value);

  Future<String?> getFont() => _sharedPreferencesService.getFont();

  Future<void> setFont({required String value}) =>
      _sharedPreferencesService.setFont(value: value);

  Future<int?> getStoryLines() => _sharedPreferencesService.getStoryLines();

  Future<void> setStoryLines({required int value}) =>
      _sharedPreferencesService.setStoryLines(value: value);

  Future<bool?> getUseLargeStoryStyle() =>
      _sharedPreferencesService.getUseLargeStoryStyle();

  Future<void> setUseLargeStoryStyle({required bool value}) =>
      _sharedPreferencesService.setUseLargeStoryStyle(value: value);

  Future<bool?> getShowFavicons() =>
      _sharedPreferencesService.getShowFavicons();

  Future<void> setShowFavicons({required bool value}) =>
      _sharedPreferencesService.setShowFavicons(value: value);

  Future<bool?> getUseBrandIcons() =>
      _sharedPreferencesService.getUseBrandIcons();

  Future<void> setUseBrandIcons({required bool value}) =>
      _sharedPreferencesService.setUseBrandIcons(value: value);

  Future<bool?> getShowStoryMetadata() =>
      _sharedPreferencesService.getShowStoryMetadata();

  Future<void> setShowStoryMetadata({required bool value}) =>
      _sharedPreferencesService.setShowStoryMetadata(value: value);

  Future<bool?> getShowUserAvatars() =>
      _sharedPreferencesService.getShowUserAvatars();

  Future<void> setShowUserAvatars({required bool value}) =>
      _sharedPreferencesService.setShowUserAvatars(value: value);

  Future<bool?> getUseActionButtons() =>
      _sharedPreferencesService.getUseActionButtons();

  Future<void> setUseActionButtons({required bool value}) =>
      _sharedPreferencesService.setUseActionButtons(value: value);

  Future<bool?> getShowJobs() => _sharedPreferencesService.getShowJobs();

  Future<void> setShowJobs({required bool value}) =>
      _sharedPreferencesService.setShowJobs(value: value);

  Future<bool?> getUseThreadNavigation() =>
      _sharedPreferencesService.getUseThreadNavigation();

  Future<void> setUseThreadNavigation({required bool value}) =>
      _sharedPreferencesService.setUseThreadNavigation(value: value);

  Future<bool?> getEnableDownvoting() =>
      _sharedPreferencesService.getEnableDownvoting();

  Future<void> setEnableDownvoting({required bool value}) =>
      _sharedPreferencesService.setEnableDownvoting(value: value);

  Future<bool?> getUseInAppBrowser() =>
      _sharedPreferencesService.getUseInAppBrowser();

  Future<void> setUseInAppBrowser({required bool value}) =>
      _sharedPreferencesService.setUseInAppBrowser(value: value);

  Future<bool?> getUseNavigationDrawer() =>
      _sharedPreferencesService.getUseNavigationDrawer();

  Future<void> setUseNavigationDrawer({required bool value}) =>
      _sharedPreferencesService.setUseNavigationDrawer(value: value);

  Future<Set<String>?> getWordFilters() async =>
      (await _sharedPreferencesService.getWordFilters())?.toSet();

  Future<void> setWordFilter({required String value, required bool filter}) =>
      _sharedPreferencesService.setWordFilter(value: value, filter: filter);

  Future<Set<String>?> getDomainFilters() async =>
      (await _sharedPreferencesService.getDomainFilters())?.toSet();

  Future<void> setDomainFilter({required String value, required bool filter}) =>
      _sharedPreferencesService.setDomainFilter(value: value, filter: filter);
}
