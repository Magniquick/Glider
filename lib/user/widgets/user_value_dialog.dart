import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glider/app/container/app_container.dart';
import 'package:glider/auth/cubit/auth_cubit.dart';
import 'package:glider/common/constants/app_spacing.dart';
import 'package:glider/settings/cubit/settings_cubit.dart';
import 'package:glider/user/cubit/user_cubit.dart';
import 'package:glider/user/models/user_value.dart';
import 'package:go_router/go_router.dart';

// The key is derived from a constructor parameter, so this constructor can
// never be const. The lint does not see the non-const super initialiser in
// primary-constructor syntax (false positive on Dart 3.13).
// ignore: prefer_const_constructors_in_immutables
class UserValueDialog(
  final UserCubitFactory _userCubitFactory,
  final AuthCubit _authCubit,
  final SettingsCubit _settingsCubit, {
  required final String username,
  final String? title,
}) extends StatefulWidget {
  this : super(key: ValueKey(username));

  @override
  State<UserValueDialog> createState() => _UserValueDialogState();
}

class _UserValueDialogState() extends State<UserValueDialog> {
  late final UserCubit _userCubit;

  @override
  void initState() {
    super.initState();
    _userCubit = widget._userCubitFactory(widget.username);
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<UserCubit, UserState>(
    bloc: _userCubit,
    builder: (context, state) => BlocBuilder<AuthCubit, AuthState>(
      bloc: widget._authCubit,
      builder: (context, authState) =>
          BlocBuilder<SettingsCubit, SettingsState>(
            bloc: widget._settingsCubit,
            builder: (context, settingsState) => AlertDialog(
              title: widget.title != null ? Text(widget.title!) : null,
              contentPadding: const EdgeInsets.all(AppSpacing.m),
              content: SizedBox(
                width: 0,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final value in UserValue.values)
                      if (value.isVisible(state, authState, settingsState))
                        ListTile(
                          leading: Icon(value.icon(state)),
                          title: Text(value.label(context, state)),
                          onTap: () => context.pop(value),
                        ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    MaterialLocalizations.of(context).cancelButtonLabel,
                  ),
                ),
              ],
            ),
          ),
    ),
  );
}
