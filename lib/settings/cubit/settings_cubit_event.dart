part of 'settings_cubit.dart';

sealed class SettingsPresentationEvent();

final class const SettingsActionFailedEvent()
    implements SettingsPresentationEvent;
