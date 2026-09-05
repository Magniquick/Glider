import 'package:glider_data/src/dtos/item_dto.dart';

/// One page of a Hacker News story list.
///
/// Thirty submissions, complete, in ranked order. The Firebase API can only
/// give the ids for these, leaving a client to fetch each story separately.
class const StoryListDto({
  /// The stories on this page, in the order Hacker News ranked them.
  required final List<ItemDto> stories,

  /// Whether the page ended with a `More` link.
  ///
  /// This is the only signal that further pages exist. The id-list endpoints
  /// gave a fixed 500 up front, but a page knows only about itself.
  final bool hasMore = false,
}) {
  /// Creates a page holding [stories].
  this;
}
