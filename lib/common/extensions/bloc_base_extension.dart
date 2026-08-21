import 'package:bloc/bloc.dart';

extension BlocBaseExtension<T> on BlocBase<T> {
  void safeEmit(T state) {
    // `emit` is protected so that only the bloc itself calls it. This helper
    // exists precisely to centralise the closed-bloc guard around it, so the
    // protection is deliberately bypassed here.
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    if (!isClosed) emit(state);
  }
}
