class const UserDto({
  required final String id,
  required final int created,
  required final int karma,
  final String? about,
  final List<int>? submitted,
}) {
  factory fromMap(Map<String, dynamic> json) => UserDto(
    id: json['id'] as String,
    created: json['created'] as int,
    karma: json['karma'] as int,
    about: json['about'] as String?,
    submitted: (json['submitted'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList(growable: false),
  );
}
