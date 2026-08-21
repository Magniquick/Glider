part of 'settings_cubit.dart';

class const SettingsState({
  final ThemeMode themeMode = ThemeMode.system,
  final bool useDynamicTheme = true,
  final Color themeColor = const Color(0xff6750a4),
  final Variant themeVariant = Variant.tonalSpot,
  final bool usePureBackground = false,
  final String font = 'Noto Sans',
  final int storyLines = 2,
  final bool useLargeStoryStyle = true,
  final bool showFavicons = true,
  final bool useBrandIcons = true,
  final bool showStoryMetadata = true,
  final bool showUserAvatars = true,
  final bool useActionButtons = false,
  final bool showJobs = true,
  final bool useThreadNavigation = true,
  final bool enableDownvoting = false,
  final bool useInAppBrowser = false,
  final bool useNavigationDrawer = false,
  final Set<String> wordFilters = const {},
  final Set<String> domainFilters = const {},
  final Version? appVersion,
}) with EquatableMixin {
  SettingsState copyWith({
    ThemeMode Function()? themeMode,
    bool Function()? useDynamicTheme,
    Color Function()? themeColor,
    Variant Function()? themeVariant,
    bool Function()? usePureBackground,
    String Function()? font,
    int Function()? storyLines,
    bool Function()? useLargeStoryStyle,
    bool Function()? showFavicons,
    bool Function()? useBrandIcons,
    bool Function()? showStoryMetadata,
    bool Function()? showUserAvatars,
    bool Function()? useActionButtons,
    bool Function()? showJobs,
    bool Function()? useThreadNavigation,
    bool Function()? enableDownvoting,
    bool Function()? useInAppBrowser,
    bool Function()? useNavigationDrawer,
    Set<String> Function()? wordFilters,
    Set<String> Function()? domainFilters,
    Version? Function()? appVersion,
  }) => SettingsState(
    themeMode: themeMode != null ? themeMode() : this.themeMode,
    useDynamicTheme: useDynamicTheme != null
        ? useDynamicTheme()
        : this.useDynamicTheme,
    themeColor: themeColor != null ? themeColor() : this.themeColor,
    themeVariant: themeVariant != null ? themeVariant() : this.themeVariant,
    usePureBackground: usePureBackground != null
        ? usePureBackground()
        : this.usePureBackground,
    font: font != null ? font() : this.font,
    storyLines: storyLines != null ? storyLines() : this.storyLines,
    useLargeStoryStyle: useLargeStoryStyle != null
        ? useLargeStoryStyle()
        : this.useLargeStoryStyle,
    showFavicons: showFavicons != null ? showFavicons() : this.showFavicons,
    useBrandIcons: useBrandIcons != null ? useBrandIcons() : this.useBrandIcons,
    showStoryMetadata: showStoryMetadata != null
        ? showStoryMetadata()
        : this.showStoryMetadata,
    showUserAvatars: showUserAvatars != null
        ? showUserAvatars()
        : this.showUserAvatars,
    useActionButtons: useActionButtons != null
        ? useActionButtons()
        : this.useActionButtons,
    showJobs: showJobs != null ? showJobs() : this.showJobs,
    useThreadNavigation: useThreadNavigation != null
        ? useThreadNavigation()
        : this.useThreadNavigation,
    enableDownvoting: enableDownvoting != null
        ? enableDownvoting()
        : this.enableDownvoting,
    useInAppBrowser: useInAppBrowser != null
        ? useInAppBrowser()
        : this.useInAppBrowser,
    useNavigationDrawer: useNavigationDrawer != null
        ? useNavigationDrawer()
        : this.useNavigationDrawer,
    wordFilters: wordFilters != null ? wordFilters() : this.wordFilters,
    domainFilters: domainFilters != null ? domainFilters() : this.domainFilters,
    appVersion: appVersion != null ? appVersion() : this.appVersion,
  );

  @override
  List<Object?> get props => [
    themeMode,
    useDynamicTheme,
    themeColor,
    themeVariant,
    usePureBackground,
    font,
    storyLines,
    useLargeStoryStyle,
    showFavicons,
    showStoryMetadata,
    showUserAvatars,
    useActionButtons,
    showJobs,
    useThreadNavigation,
    enableDownvoting,
    useInAppBrowser,
    useNavigationDrawer,
    wordFilters,
    domainFilters,
    appVersion,
  ];
}
