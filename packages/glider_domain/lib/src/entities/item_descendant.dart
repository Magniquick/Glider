import 'package:equatable/equatable.dart';

class ItemDescendant({
  required final int id,
  final List<int> ancestorIds = const [],
  final bool isPart = false,
}) with EquatableMixin {
  factory fromMap(Map<String, dynamic> json) => ItemDescendant(
    id: json['id'] as int,
    ancestorIds:
        (json['ancestorIds'] as List<dynamic>?)
            ?.map((e) => e as int)
            .toList(growable: false) ??
        const [],
    isPart: json['isPart'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'ancestorIds': ancestorIds,
    'isPart': isPart,
  };

  @override
  List<Object?> get props => [id, ancestorIds, isPart];
}

extension ItemDescendantExtension on ItemDescendant {
  int get depth => ancestorIds.length;
}
