import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:glider/common/extensions/bloc_base_extension.dart';
import 'package:glider_domain/glider_domain.dart';

part 'auth_state.dart';

class AuthCubit(this._authRepository, this._itemInteractionRepository)
    extends Cubit<AuthState> {
  this : super(const AuthState());

  final AuthRepository _authRepository;
  final ItemInteractionRepository _itemInteractionRepository;

  Future<void> init() async {
    await _updateLoggedIn();
  }

  Future<void> logIn({
    required String username,
    required String password,
  }) async {
    safeEmit(state.copyWith(status: () => AuthStatus.inProgress));
    final LogInResult result;

    try {
      result = await _authRepository.logIn(
        username: username,
        password: password,
      );
    } on Object {
      safeEmit(state.copyWith(status: () => AuthStatus.failure));
      return;
    }

    switch (result) {
      case LogInResult.success:
        await _updateLoggedIn();
        safeEmit(state.copyWith(status: () => AuthStatus.success));
      case LogInResult.badCredentials:
        safeEmit(state.copyWith(status: () => AuthStatus.badCredentials));
      case LogInResult.rejected:
        safeEmit(state.copyWith(status: () => AuthStatus.rejected));
    }
  }

  Future<void> logout() async {
    await _authRepository.logout();
    await _itemInteractionRepository.getUpvotedIds();
    await _itemInteractionRepository.getFavoritedIds();
    await _itemInteractionRepository.getFlaggedIds();
    await _updateLoggedIn();
  }

  Future<void> _updateLoggedIn() async {
    final (username, userCookie) = await _authRepository.getUserAuth();
    safeEmit(
      state.copyWith(
        isLoggedIn: () => userCookie != null,
        username: () => username,
      ),
    );
  }
}
