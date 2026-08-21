part of 'user_item_search_bloc.dart';

sealed class const UserItemSearchEvent() with EquatableMixin;

final class const LoadUserItemSearchEvent() extends UserItemSearchEvent {
  @override
  List<Object?> get props => [];
}

final class const SetTextUserItemSearchEvent(this.text)
    extends UserItemSearchEvent {
  final String? text;

  @override
  List<Object?> get props => [text];
}
