import 'package:equatable/equatable.dart';
import 'package:glider_data/glider_data.dart';
import 'package:glider_domain/src/extensions/string_extension.dart';

class Item({
  required final int id,
  final bool isDeleted = false,
  final ItemType? type,
  final String? username,
  final DateTime? dateTime,
  final String? text,
  final bool isDead = false,
  final int? parentId,
  final int? pollId,
  final List<int>? childIds,
  final Uri? url,
  final int? score,
  final String? title,
  final List<int>? partIds,
  final int? descendantCount,
}) with EquatableMixin {
  factory fromDto(ItemDto dto) => Item(
    id: dto.id,
    isDeleted: dto.deleted ?? false,
    type: dto.type != null ? ItemType.tryParse(dto.type!) : null,
    username: dto.by,
    dateTime: dto.time != null
        ? DateTime.fromMillisecondsSinceEpoch(dto.time! * 1000)
        : null,
    text: dto.text?.convertHtmlToHackerNews(),
    isDead: dto.dead ?? false,
    parentId: dto.parent,
    pollId: dto.poll,
    childIds: dto.kids ?? const [],
    url: dto.url != null && dto.url!.isNotEmpty ? Uri.tryParse(dto.url!) : null,
    score: dto.score,
    title: dto.title,
    partIds: dto.parts ?? const [],
    descendantCount: dto.descendants,
  );

  factory fromAlgoliaSearchHitDto(AlgoliaSearchHitDto dto) => Item(
    id: int.parse(dto.objectId),
    username: dto.author,
    dateTime: dto.createdAtI != null
        ? DateTime.fromMillisecondsSinceEpoch(dto.createdAtI! * 1000)
        : null,
    text: (dto.storyText ?? dto.commentText)?.convertHtmlToHackerNews(),
    parentId: dto.parentId,
    url: dto.url != null && dto.url!.isNotEmpty ? Uri.tryParse(dto.url!) : null,
    score: dto.points,
    title: dto.title,
    descendantCount: dto.numComments,
  );

  /// Builds an item from one row parsed off a Hacker News item page.
  ///
  /// [childIds] cannot come from the row itself. The page expresses the tree
  /// through indentation, so a row's children are the rows that follow it one
  /// level deeper, which only the caller walking the whole list can know.
  /// `ItemAction.delete` gates on this being non-null and empty, so leaving it
  /// out would silently remove the delete action.
  ///
  /// `descendantCount` is deliberately not set from the row's subtree size,
  /// even though the page carries one. Firebase only reports it for stories,
  /// so populating it here would put a reply-count badge on every comment,
  /// which is a change to how the list looks rather than to how fast it loads.
  factory fromItemPageRowDto(
    ItemPageRowDto dto, {
    required List<int> childIds,
  }) => Item(
    id: dto.id,
    type: dto.isPart ? ItemType.pollopt : ItemType.comment,
    username: dto.by,
    // `fromDto` builds a local DateTime out of the Firebase epoch, and `isUtc`
    // counts towards DateTime equality, so the page's trailing `Z` has to be
    // converted rather than carried through as UTC.
    dateTime: switch (dto.timeIso) {
      final String iso => DateTime.tryParse(iso)?.toLocal(),
      _ => null,
    },
    text: dto.textHtml?.convertHtmlToHackerNews(),
    isDead: dto.isDead,
    parentId: dto.parentId,
    childIds: childIds,
    partIds: const [],
  );

  factory fromMap(Map<String, dynamic> json) => Item(
    id: json['id'] as int,
    isDeleted: json['isDeleted'] as bool? ?? false,
    type: json['type'] != null
        ? ItemType.values.byName(json['type'] as String)
        : null,
    username: json['username'] as String?,
    dateTime: json['dateTime'] != null
        ? DateTime.fromMillisecondsSinceEpoch(json['dateTime'] as int)
        : null,
    text: json['text'] as String?,
    isDead: json['isDead'] as bool? ?? false,
    parentId: json['parentId'] as int?,
    pollId: json['pollId'] as int?,
    childIds: (json['childIds'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList(growable: false),
    url: json['url'] != null && (json['url'] as String).isNotEmpty
        ? Uri.tryParse(json['url'] as String)
        : null,
    score: json['score'] as int?,
    title: json['title'] as String?,
    partIds: (json['partIds'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList(growable: false),
    descendantCount: json['descendantCount'] as int?,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'id': id,
    'isDeleted': isDeleted,
    'type': type?.name,
    'username': username,
    'dateTime': dateTime?.millisecondsSinceEpoch,
    'text': text,
    'isDead': isDead,
    'parentId': parentId,
    'pollId': pollId,
    'childIds': childIds,
    'url': url?.toString(),
    'score': score,
    'title': title,
    'partIds': partIds,
    'descendantCount': descendantCount,
  };

  Item copyWith({
    int Function()? id,
    bool Function()? isDeleted,
    ItemType? Function()? type,
    String? Function()? username,
    DateTime? Function()? dateTime,
    String? Function()? text,
    bool Function()? isDead,
    int? Function()? parentId,
    int? Function()? pollId,
    List<int> Function()? childIds,
    Uri? Function()? url,
    int? Function()? score,
    String? Function()? title,
    List<int> Function()? partIds,
    int? Function()? descendantCount,
  }) => Item(
    id: id != null ? id() : this.id,
    isDeleted: isDeleted != null ? isDeleted() : this.isDeleted,
    type: type != null ? type() : this.type,
    username: username != null ? username() : this.username,
    dateTime: dateTime != null ? dateTime() : this.dateTime,
    text: text != null ? text() : this.text,
    isDead: isDead != null ? isDead() : this.isDead,
    parentId: parentId != null ? parentId() : this.parentId,
    pollId: pollId != null ? pollId() : this.pollId,
    childIds: childIds != null ? childIds() : this.childIds,
    url: url != null ? url() : this.url,
    score: score != null ? score() : this.score,
    title: title != null ? title() : this.title,
    partIds: partIds != null ? partIds() : this.partIds,
    descendantCount: descendantCount != null
        ? descendantCount()
        : this.descendantCount,
  );

  @override
  List<Object?> get props => [
    id,
    isDeleted,
    type,
    username,
    dateTime,
    text,
    isDead,
    parentId,
    pollId,
    childIds,
    url,
    score,
    title,
    partIds,
    descendantCount,
  ];
}

enum ItemType() {
  job,
  story,
  comment,
  poll,
  pollopt;

  static ItemType parse(String name) => ItemType.values.byName(name);

  static ItemType? tryParse(String name) {
    try {
      return parse(name);
    } on Object {
      return null;
    }
  }
}
