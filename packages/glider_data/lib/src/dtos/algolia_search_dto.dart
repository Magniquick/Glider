class const AlgoliaSearchDto({required final List<AlgoliaSearchHitDto> hits}) {
  factory fromMap(Map<String, dynamic> json) => AlgoliaSearchDto(
    hits: (json['hits'] as List<dynamic>)
        .map((e) => AlgoliaSearchHitDto.fromMap(e as Map<String, dynamic>))
        .toList(growable: false),
  );
}

class const AlgoliaSearchHitDto({
  required final String objectId,
  final String? title,
  final String? url,
  final String? author,
  final int? points,
  final String? storyText,
  final String? commentText,
  final int? numComments,
  final int? parentId,
  final int? createdAtI,
}) {
  factory fromMap(Map<String, dynamic> json) => AlgoliaSearchHitDto(
    objectId: json['objectID'] as String,
    title: json['title'] as String?,
    url: json['url'] as String?,
    author: json['author'] as String?,
    points: json['points'] as int?,
    storyText: json['story_text'] as String?,
    commentText: json['comment_text'] as String?,
    numComments: json['num_comments'] as int?,
    parentId: json['parent_id'] as int?,
    createdAtI: json['created_at_i'] as int?,
  );
}
