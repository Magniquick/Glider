part of 'user_cubit.dart';

class const UserState({
  @override final Status status = Status.initial,
  @override final User? data,
  final ParsedData? parsedAbout,
  final bool blocked = false,
  final bool synchronizing = false,
  @override final Object? exception,
}) with DataMixin<User>, EquatableMixin {
  factory fromMap(Map<String, dynamic> json) => UserState(
    status: Status.values.byName(json['status'] as String),
    data: User.fromMap(json['data'] as Map<String, dynamic>),
    blocked: json['blocked'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'status': status.name,
    'data': data?.toMap(),
    'blocked': blocked,
  };

  UserState copyWith({
    Status Function()? status,
    User? Function()? data,
    ParsedData? Function()? parsedAbout,
    bool Function()? blocked,
    bool Function()? synchronizing,
    Object? Function()? exception,
  }) => UserState(
    status: status != null ? status() : this.status,
    data: data != null ? data() : this.data,
    parsedAbout: parsedAbout != null ? parsedAbout() : this.parsedAbout,
    blocked: blocked != null ? blocked() : this.blocked,
    synchronizing: synchronizing != null ? synchronizing() : this.synchronizing,
    exception: exception != null ? exception() : this.exception,
  );

  @override
  List<Object?> get props => [
    status,
    data,
    parsedAbout,
    blocked,
    synchronizing,
    exception,
  ];
}
