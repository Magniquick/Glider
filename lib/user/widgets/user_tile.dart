import 'package:bloc_presentation/bloc_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glider/app/router/app_router.dart';
import 'package:glider/auth/cubit/auth_cubit.dart';
import 'package:glider/common/constants/app_animation.dart';
import 'package:glider/common/constants/app_spacing.dart';
import 'package:glider/common/mixins/data_mixin.dart';
import 'package:glider/l10n/extensions/app_localizations_extension.dart';
import 'package:glider/settings/cubit/settings_cubit.dart';
import 'package:glider/user/cubit/user_cubit.dart';
import 'package:glider/user/models/user_style.dart';
import 'package:glider/user/typedefs/user_typedefs.dart';
import 'package:glider/user/widgets/user_bottom_sheet.dart';
import 'package:glider/user/widgets/user_data_tile.dart';
import 'package:glider/user/widgets/user_loading_tile.dart';
import 'package:glider_domain/glider_domain.dart';

// The key is derived from a constructor parameter, so this constructor can
// never be const. The lint does not see the non-const super initialiser in
// primary-constructor syntax (false positive on Dart 3.13).
// ignore: prefer_const_constructors_in_immutables
class UserTile(
  final UserCubit _userCubit,
  final AuthCubit _authCubit,
  final SettingsCubit _settingsCubit, {
  final UserStyle style = UserStyle.full,
  final EdgeInsets padding = AppSpacing.defaultTilePadding,
  final UserCallback? onTap,
}) extends StatelessWidget {
  this : super(key: ValueKey(_userCubit.username));

  @override
  Widget build(BuildContext context) =>
      BlocPresentationListener<UserCubit, UserPresentationEvent>(
        bloc: _userCubit,
        listener: (context, event) => switch (event) {
          UserActionFailedEvent() => ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(context.l10n.failure))),
        },
        child: BlocBuilder<UserCubit, UserState>(
          bloc: _userCubit,
          builder: (context, state) =>
              BlocBuilder<SettingsCubit, SettingsState>(
                bloc: _settingsCubit,
                buildWhen: (previous, current) =>
                    previous.useInAppBrowser != current.useInAppBrowser,
                builder: (context, settingsState) => AnimatedSize(
                  alignment: Alignment.topCenter,
                  duration: AppAnimation.emphasized.duration,
                  curve: AppAnimation.emphasized.easing,
                  child: state.whenOrDefaultWidgets(
                    loading: () =>
                        UserLoadingTile(style: style, padding: padding),
                    success: () {
                      final User user = state.data!;
                      return UserDataTile(
                        user,
                        parsedAbout: state.parsedAbout,
                        blocked: state.blocked,
                        style: style,
                        padding: padding,
                        useInAppBrowser: settingsState.useInAppBrowser,
                        onTap: onTap,
                        onLongPress: (context, item) =>
                            showModalBottomSheet<void>(
                              context: rootNavigatorKey.currentContext!,
                              builder: (context) => UserBottomSheet(
                                _userCubit,
                                _authCubit,
                                _settingsCubit,
                              ),
                            ),
                      );
                    },
                    failure: SizedBox.shrink,
                  ),
                ),
              ),
        ),
      );
}
