part of 'auth_cubit.dart';

enum AuthStatus() {
  initial,
  inProgress,
  success,
  badCredentials,
  rejected,
  failure
}

class const AuthState({
  this.isLoggedIn = false,
  this.username,
  this.status = AuthStatus.initial,
}) with EquatableMixin {
  final bool isLoggedIn;
  final String? username;
  final AuthStatus status;

  AuthState copyWith({
    bool Function()? isLoggedIn,
    String? Function()? username,
    AuthStatus Function()? status,
  }) => AuthState(
    isLoggedIn: isLoggedIn != null ? isLoggedIn() : this.isLoggedIn,
    username: username != null ? username() : this.username,
    status: status != null ? status() : this.status,
  );

  @override
  List<Object?> get props => [isLoggedIn, username, status];
}
