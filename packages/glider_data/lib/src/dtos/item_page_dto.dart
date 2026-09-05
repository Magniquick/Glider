import 'package:glider_data/src/dtos/item_dto.dart';

/// One comment or poll-option row parsed from a Hacker News item page.
///
/// The page carries more per-comment detail than `/v0/item/<id>.json` does:
/// [subtreeCount] has no equivalent in the Firebase API, and [voteAuth] is
/// only present when the page was fetched with a session cookie.
class const ItemPageRowDto({
  /// The item's own id, from the row's `id` attribute.
  required final int id,

  /// The id linked by the row's `parent` anchor, absent on top-level rows.
  final int? parentId,

  /// Nesting level, from `td.ind[indent]`. Zero for a top-level comment.
  final int indent = 0,

  /// The commenter's username, from `a.hnuser`.
  final String? by,

  /// The exact timestamp from `span.age[title]`, an ISO 8601 string.
  ///
  /// Preferred over the anchor's relative "22 hours ago" text, which loses
  /// precision and is localised.
  final String? timeIso,

  /// Inner HTML of `div.commtext`, in the same shape as the Firebase `text`
  /// field, so it converts with `convertHtmlToHackerNews`.
  final String? textHtml,

  /// Size of this row's subtree, from the `n` attribute on the toggle link.
  final int? subtreeCount,

  /// Whether Hacker News marked the row dead or flagged.
  ///
  /// Only ever true when the page was fetched by a user whose profile has
  /// `showdead` set; anonymous pages omit these rows entirely.
  final bool isDead = false,

  /// Whether this is a poll option rather than a comment.
  final bool isPart = false,

  /// The one-time `auth` token from the row's upvote link, when logged in.
  final String? voteAuth,
}) {
  /// Creates a row for the item with the given [id].
  this;
}

/// One instalment of an item page parsed while it is still downloading.
///
/// Hacker News sends the page as an HTTP/2 stream with no `content-length`,
/// and a large thread takes several seconds to arrive: 3 MB over roughly 3
/// seconds after a 0.9 second first byte. A browser paints from the first
/// second because it renders as the bytes land, which is why the scrollbar
/// visibly shrinks. Waiting for the whole body before showing anything throws
/// that away, so the parse is fed the same way.
class const ItemPageChunk({
  /// The submission, on the first chunk only.
  ///
  /// `table.fatitem` sits near the top of the document, so this arrives long
  /// before the comments do.
  final ItemDto? story,

  /// Rows parsed since the previous chunk, in the order the page rendered
  /// them.
  final List<ItemPageRowDto> rows = const [],

  /// Whether the page ended with a `More` link, known only on the last chunk.
  final bool hasMore = false,
}) {
  /// Creates a chunk carrying [rows], and [story] on the first one.
  this;
}

/// A parsed Hacker News item page: the submission plus every row on it.
class const ItemPageDto({
  /// The submission itself, parsed from `table.fatitem`.
  required final ItemDto story,

  /// Comment and poll-option rows, in the order Hacker News rendered them.
  ///
  /// That order is Hacker News' own ranking, which is the reason this page is
  /// parsed at all rather than the tree being read from the Algolia API.
  required final List<ItemPageRowDto> rows,

  /// Whether the page ended with a `More` link, meaning rows were withheld.
  ///
  /// Hacker News currently serves whole threads unpaginated, even at 3859
  /// comments, but it has throttled this down under load before.
  final bool hasMore = false,
}) {
  /// Creates a page holding [story] and its [rows].
  this;
}
