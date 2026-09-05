import 'package:glider_data/src/dtos/item_dto.dart';

/// One page of a Hacker News story list: thirty stories, ranked, complete.
class const StoryListDto({
  /// The stories on this page, in the order Hacker News ranked them.
  required final List<ItemDto> stories,

  /// Whether the page ended with a `More` link. The only signal that further
  /// pages exist, since a page knows nothing beyond itself.
  final bool hasMore = false,
}) {
  /// Creates a page holding [stories].
  this;
}
