import 'package:equatable/equatable.dart';
import 'package:glider_data/glider_data.dart';
import 'package:glider_domain/src/extensions/string_extension.dart';

class const User({
  required final String username,
  required final DateTime createdDateTime,
  required final int karma,
  final String? about,
  final List<int>? submittedIds,
}) with EquatableMixin {
  factory fromDto(UserDto dto) => User(
    username: dto.id,
    createdDateTime: DateTime.fromMillisecondsSinceEpoch(dto.created * 1000),
    karma: dto.karma,
    about: dto.about?.convertHtmlToHackerNews(),
    submittedIds: dto.submitted ?? const [],
  );

  factory fromMap(Map<String, dynamic> json) => User(
    username: json['username'] as String,
    createdDateTime: DateTime.fromMillisecondsSinceEpoch(
      json['createdDateTime'] as int,
    ),
    karma: json['karma'] as int,
    about: json['about'] as String?,
    submittedIds: (json['submittedIds'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList(growable: false),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'username': username,
    'createdDateTime': createdDateTime.millisecondsSinceEpoch,
    'karma': karma,
    'about': about,
    'submittedIds': submittedIds,
  };

  @override
  List<Object?> get props => [
    username,
    createdDateTime,
    karma,
    about,
    submittedIds,
  ];
}
