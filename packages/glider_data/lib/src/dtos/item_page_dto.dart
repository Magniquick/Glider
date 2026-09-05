import 'package:glider_data/src/dtos/item_dto.dart';

/// One comment or poll-option row parsed from a Hacker News item page.
///
/// Carries more per comment than `/v0/item/<id>.json` does: [subtreeCount] has
/// no equivalent there, and [voteAuth] only appears when logged in.
class const ItemPageRowDto({
  /// The item's own id.
  required final int id,

  /// The id linked by the row's `parent` anchor, absent on top-level rows.
  final int? parentId,

  /// Nesting level from `td.ind[indent]`. Zero for a top-level comment.
  final int indent = 0,

  /// The commenter's username.
  final String? by,

  /// Exact ISO 8601 timestamp, preferred over the localised "22 hours ago".
  final String? timeIso,

  /// Inner HTML of `div.commtext`, in the same shape as the Firebase `text`
  /// field, so it converts with `convertHtmlToHackerNews`.
  final String? textHtml,

  /// Size of this row's subtree.
  final int? subtreeCount,

  /// Whether Hacker News marked the row dead or flagged.
  ///
  /// Only ever true for a profile with `showdead` set; anonymous pages omit
  /// these rows entirely.
  final bool isDead = false,

  /// Whether this is a poll option rather than a comment.
  final bool isPart = false,

  /// One-time `auth` token from the row's upvote link, when logged in.
  final String? voteAuth,
}) {
  /// Creates a row for the item with the given [id].
  this;
}

/// One instalment of an item page parsed while it is still downloading.
///
/// The body takes seconds to arrive, so it is parsed as it lands rather than
/// after, the way a browser paints it.
class const ItemPageChunk({
  /// The submission, on the first chunk only.
  final ItemDto? story,

  /// Rows parsed since the previous chunk, in render order.
  final List<ItemPageRowDto> rows = const [],

  /// Whether the page ended with a `More` link. Known only on the last chunk.
  final bool hasMore = false,
}) {
  /// Creates a chunk carrying [rows], and [story] on the first one.
  this;
}

/// A parsed Hacker News item page: the submission plus every row on it.
class const ItemPageDto({
  /// The submission itself, from `table.fatitem`.
  required final ItemDto story,

  /// Comment and poll-option rows, in Hacker News' own ranked order. That
  /// order is why this is parsed rather than read from the Algolia API.
  required final List<ItemPageRowDto> rows,

  /// Whether the page ended with a `More` link.
  final bool hasMore = false,
}) {
  /// Creates a page holding [story] and its [rows].
  this;
}
