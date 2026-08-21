part of 'user_cubit.dart';

sealed class UserPresentationEvent();

final class const UserActionFailedEvent() implements UserPresentationEvent;
