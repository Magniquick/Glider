part of 'user_cubit.dart';

sealed class UserCubitEvent();

final class const UserActionFailedEvent() implements UserCubitEvent;
