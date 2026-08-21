part of 'favorites_cubit.dart';

class const FavoritesState({
  @override final Status status = Status.initial,
  @override final List<int>? data,
  @override final Object? exception,
}) with DataMixin<List<int>>, EquatableMixin {
  factory fromMap(Map<String, dynamic> json) => FavoritesState(
    status: Status.values.byName(json['status'] as String),
    data: (json['data'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList(growable: false),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'status': status.name,
    'data': data,
  };

  FavoritesState copyWith({
    Status Function()? status,
    List<int>? Function()? data,
    Object? Function()? exception,
  }) => FavoritesState(
    status: status != null ? status() : this.status,
    data: data != null ? data() : this.data,
    exception: exception != null ? exception() : this.exception,
  );

  @override
  List<Object?> get props => [status, data, exception];
}
