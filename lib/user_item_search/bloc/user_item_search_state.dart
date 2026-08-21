part of 'user_item_search_bloc.dart';

class const UserItemSearchState({
  @override final Status status = Status.initial,
  @override final List<int>? data,
  final String? searchText,
  @override final Object? exception,
}) with DataMixin<List<int>>, EquatableMixin {
  UserItemSearchState copyWith({
    Status Function()? status,
    List<int>? Function()? data,
    String? Function()? searchText,
    Object? Function()? exception,
  }) => UserItemSearchState(
    status: status != null ? status() : this.status,
    data: data != null ? data() : this.data,
    searchText: searchText != null ? searchText() : this.searchText,
    exception: exception != null ? exception() : this.exception,
  );

  @override
  List<Object?> get props => [status, data, searchText, exception];
}
