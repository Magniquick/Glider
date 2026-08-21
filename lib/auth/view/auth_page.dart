import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:glider/app/container/app_container.dart';
import 'package:glider/app/models/app_route.dart';
import 'package:glider/auth/cubit/auth_cubit.dart';
import 'package:glider/common/constants/app_spacing.dart';
import 'package:glider/common/extensions/uri_extension.dart';
import 'package:glider/common/extensions/widget_list_extension.dart';
import 'package:glider/l10n/extensions/app_localizations_extension.dart';
import 'package:glider/settings/cubit/settings_cubit.dart';
import 'package:glider/user/view/user_page.dart';
import 'package:go_router/go_router.dart';

class const AuthPage(
  final AuthCubit _authCubit,
  final SettingsCubit _settingsCubit,
  final UserCubitFactory _userCubitFactory,
  final ItemCubitFactory _itemCubitFactory,
  final UserItemSearchBlocFactory _userItemSearchBlocFactory, {
  super.key,
}) extends StatefulWidget {
  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState() extends State<AuthPage> {
  @override
  void initState() {
    super.initState();
    unawaited(widget._authCubit.init());
  }

  @override
  Widget build(BuildContext context) => BlocConsumer<AuthCubit, AuthState>(
    listenWhen: (previous, current) => current.isLoggedIn,
    listener: (context, state) async {
      final bool? confirm = await context.push<bool>(
        AppRoute.confirmDialog.location(),
        extra: (
          title: context.l10n.synchronize,
          text: context.l10n.synchronizeDescription,
        ),
      );
      if (confirm ?? false) {
        await widget._userCubitFactory(state.username!).synchronize();
      }
    },
    bloc: widget._authCubit,
    builder: (context, state) => state.isLoggedIn
        ? UserPage(
            widget._userCubitFactory,
            widget._itemCubitFactory,
            widget._userItemSearchBlocFactory,
            widget._authCubit,
            widget._settingsCubit,
            username: state.username!,
          )
        : Scaffold(
            body: CustomScrollView(
              slivers: [
                const SliverAppBar(),
                SliverSafeArea(
                  top: false,
                  // The form must not be forced to fill the viewport: the
                  // software keyboard shrinks it and the content overflows.
                  sliver: SliverToBoxAdapter(
                    child: _AuthBody(widget._authCubit, widget._settingsCubit),
                  ),
                ),
              ],
            ),
          ),
  );
}

class const _AuthBody(
  final AuthCubit _authCubit,
  final SettingsCubit _settingsCubit,
) extends StatefulWidget {
  @override
  State<_AuthBody> createState() => _AuthBodyState();
}

class _AuthBodyState() extends State<_AuthBody> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  var _obscurePassword = true;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    await widget._authCubit.logIn(
      username: _usernameController.text.trim(),
      password: _passwordController.text,
    );
  }

  String? _errorText(BuildContext context, AuthStatus status) =>
      switch (status) {
        AuthStatus.badCredentials => context.l10n.badCredentialsError,
        AuthStatus.rejected => context.l10n.loginRejectedError,
        AuthStatus.challengeRequired => context.l10n.loginChallengeError,
        AuthStatus.failure => context.l10n.loginFailedError,
        _ => null,
      };

  @override
  Widget build(BuildContext context) => BlocBuilder<AuthCubit, AuthState>(
    bloc: widget._authCubit,
    builder: (context, state) {
      final inProgress = state.status == AuthStatus.inProgress;
      final String? errorText = _errorText(context, state.status);
      return Padding(
        padding: AppSpacing.defaultTilePadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(context.l10n.authDescription),
              TextFormField(
                controller: _usernameController,
                enabled: !inProgress,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.next,
                autofillHints: const [AutofillHints.username],
                decoration: InputDecoration(
                  labelText: context.l10n.username,
                  border: const OutlineInputBorder(),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? context.l10n.emptyError
                    : null,
              ),
              TextFormField(
                controller: _passwordController,
                enabled: !inProgress,
                obscureText: _obscurePassword,
                autocorrect: false,
                enableSuggestions: false,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onFieldSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  labelText: context.l10n.password,
                  border: const OutlineInputBorder(),
                  errorText: errorText,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                validator: (value) => value == null || value.isEmpty
                    ? context.l10n.emptyError
                    : null,
              ),
              FilledButton.icon(
                onPressed: inProgress ? null : _submit,
                icon: inProgress
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.login_outlined),
                label: Text(context.l10n.login),
              ),
              _AuthLinks(widget._settingsCubit),
            ].spaced(height: AppSpacing.m),
          ),
        ),
      );
    },
  );
}

class const _AuthLinks(final SettingsCubit _settingsCubit)
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => TextButtonTheme(
    data: TextButtonThemeData(
      style: TextButton.styleFrom(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    ),
    child: OverflowBar(
      alignment: MainAxisAlignment.end,
      spacing: AppSpacing.s,
      children: [
        TextButton(
          onPressed: () =>
              Uri.https(
                'github.com',
                'Mosc/Glider/blob/master/PRIVACY.md',
              ).tryLaunch(
                context,
                useInAppBrowser: _settingsCubit.state.useInAppBrowser,
              ),
          child: Text(context.l10n.privacyPolicy),
        ),
        TextButton(
          onPressed: () => Uri.https('www.ycombinator.com', 'legal')
              .replace(fragment: 'privacy')
              .tryLaunch(
                context,
                useInAppBrowser: _settingsCubit.state.useInAppBrowser,
              ),
          child: Text(context.l10n.privacyPolicyYc),
        ),
        TextButton(
          onPressed: () => Uri.https('www.ycombinator.com', 'legal')
              .replace(fragment: 'tou')
              .tryLaunch(
                context,
                useInAppBrowser: _settingsCubit.state.useInAppBrowser,
              ),
          child: Text(context.l10n.termsOfUseYc),
        ),
      ],
    ),
  );
}
