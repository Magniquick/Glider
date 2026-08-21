part of 'item_tree_cubit.dart';

class ItemTreeState({
  @override final Status status = Status.initial,
  @override final List<ItemDescendant>? data,
  final List<ItemDescendant>? previousData,
  final Set<int> collapsedIds = const {},
  @override final Object? exception,
}) with DataMixin<List<ItemDescendant>>, EquatableMixin {
  factory fromMap(Map<String, dynamic> json) => ItemTreeState(
    status: Status.values.byName(json['status'] as String),
    data: (json['data'] as List<dynamic>?)
        ?.map((e) => ItemDescendant.fromMap(e as Map<String, dynamic>))
        .toList(growable: false),
    previousData: (json['previousData'] as List<dynamic>?)
        ?.map((e) => ItemDescendant.fromMap(e as Map<String, dynamic>))
        .toList(growable: false),
    collapsedIds: (json['collapsedIds'] as List<dynamic>)
        .map((e) => e as int)
        .toSet(),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'status': status.name,
    'data': data?.map((e) => e.toMap()).toList(growable: false),
    'previousData': previousData?.map((e) => e.toMap()).toList(growable: false),
    'collapsedIds': collapsedIds.toList(growable: false),
  };

  late final List<ItemDescendant>? viewableData = data
      ?.where((e) => !e.ancestorIds.any(collapsedIds.contains))
      .toList(growable: false);

  late final int newDescendantsCount = data != null && previousData != null
      ? {...?data}.difference({...?previousData}).length
      : 0;

  ItemTreeState copyWith({
    Status Function()? status,
    List<ItemDescendant>? Function()? data,
    List<ItemDescendant>? Function()? previousData,
    Set<int> Function()? collapsedIds,
    Object? Function()? exception,
  }) => ItemTreeState(
    status: status != null ? status() : this.status,
    data: data != null ? data() : this.data,
    previousData: previousData != null ? previousData() : this.previousData,
    collapsedIds: collapsedIds != null ? collapsedIds() : this.collapsedIds,
    exception: exception != null ? exception() : this.exception,
  );

  // viewableData and newDescendantsCount are memoised derivations of data and
  // previousData, which are already compared below.
  @override
  List<Object?> get props => [
    status,
    data,
    previousData,
    collapsedIds,
    exception,
  ];
}

extension ItemTreeStateExtension on ItemTreeState {
  List<ItemDescendant>? getDescendants(ItemDescendant descendant) => data
      ?.where((e) => e.ancestorIds.contains(descendant.id))
      .toList(growable: false);

  int? getPreviousRootChildIndex({required int index}) => viewableData?.indexed
      .take(index)
      .lastWhereOrNull((indexed) => indexed.$2.depth == 1)
      ?.$1;

  int? getNextRootChildIndex({required int index}) => viewableData?.indexed
      .skip(index + 1)
      .firstWhereOrNull((indexed) => indexed.$2.depth == 1)
      ?.$1;
}
