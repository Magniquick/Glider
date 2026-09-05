import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:glider_data/glider_data.dart';
import 'package:glider_domain/src/entities/item.dart';
import 'package:glider_domain/src/entities/item_descendant.dart';
import 'package:glider_domain/src/extensions/behavior_subject_map_extension.dart';
import 'package:rxdart/subjects.dart';

class ItemRepository(
  final AlgoliaApiService _algoliaApiService,
  final HackerNewsApiService _hackerNewsApiService,
  final HackerNewsWebsiteService _hackerNewsWebsiteService,
  final SecureStorageService _secureStorageService,
) {
  this : _itemStreamControllers = {};

  final Map<int, BehaviorSubject<Item>> _itemStreamControllers;

  /// Set once Hacker News answers with its `noprocrast` interstitial.
  ///
  /// Every authenticated page view that does get through writes the account's
  /// `lastview` forward, so continuing to send the cookie would keep spending
  /// the reading budget the setting exists to protect. Dropping it for the
  /// rest of the session costs only the dead comments.
  bool _preferAnonymous = false;

  /// Fetches one page of a story list and seeds every story it carries.
  ///
  /// [path] is the Hacker News section, e.g. `news` or `newest`. One request
  /// returns thirty complete stories in ranked order, for under 7 KB gzipped.
  /// The Firebase API offers only ids for these, which left the app fetching
  /// each story separately: about twenty-six requests for the same page.
  ///
  /// `hasMore` comes from the page's own `More` link, and is the only signal
  /// that further pages exist.
  Future<({List<Item> items, bool hasMore})> getStories(
    String path, {
    int page = 1,
  }) async {
    final dto = await _hackerNewsWebsiteService.getStories(
      path: path,
      page: page,
    );
    final items = await compute(
      (stories) => stories.map(Item.fromDto).toList(growable: false),
      dto.stories,
    );

    for (final item in items) {
      _itemStreamControllers.getOrAdd(item.id).add(item);
    }

    return (items: items, hasMore: dto.hasMore);
  }

  Future<List<Item>> searchStories({
    String? text,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final dto = await _algoliaApiService.searchStories(
      query: text,
      startDate: startDate,
      endDate: endDate,
    );
    final items = await compute(
      (hits) => hits.map(Item.fromAlgoliaSearchHitDto).toList(growable: false),
      dto.hits,
    );

    for (final item in items) {
      _itemStreamControllers.getOrAdd(item.id).add(item);
    }

    return items;
  }

  Future<List<Item>> searchStoryItems(int id, {String? text}) async {
    final dto = await _algoliaApiService.searchStoryItems(id, query: text);
    final items = await compute(
      (hits) => hits.map(Item.fromAlgoliaSearchHitDto).toList(growable: false),
      dto.hits,
    );

    for (final item in items) {
      _itemStreamControllers.getOrAdd(item.id).add(item);
    }

    return items;
  }

  Future<List<Item>> getSimilarStories(int id, {required String url}) async {
    final dto = await _algoliaApiService.getSimilarStories(id, url: url);
    final items = await compute(
      (hits) => hits.map(Item.fromAlgoliaSearchHitDto).toList(growable: false),
      dto.hits,
    );

    for (final item in items) {
      _itemStreamControllers.getOrAdd(item.id).add(item);
    }

    return items;
  }

  Future<List<Item>> searchUserItems(String username, {String? text}) async {
    final dto = await _algoliaApiService.searchUserItems(username, query: text);
    final items = await compute(
      (hits) => hits.map(Item.fromAlgoliaSearchHitDto).toList(growable: false),
      dto.hits,
    );

    for (final item in items) {
      _itemStreamControllers.getOrAdd(item.id).add(item);
    }

    return items;
  }

  Future<List<Item>> getUserReplies(String username) async {
    final userDto = await _hackerNewsApiService.getUser(username);

    if (userDto.submitted case final submitted?) {
      // Limit ID count to prevent running into HTTP status 414 URI Too Long or
      // Algolia internal server errors.
      final dto = await _algoliaApiService.getUserReplies(submitted.take(30));
      final items = await compute(
        (hits) =>
            hits.map(Item.fromAlgoliaSearchHitDto).toList(growable: false),
        dto.hits,
      );

      for (final item in items) {
        _itemStreamControllers.getOrAdd(item.id).add(item);
      }

      return items;
    } else {
      return [];
    }
  }

  Stream<Item> getItemStream(int id) =>
      _itemStreamControllers.getOrAdd(id, asyncSeed: () => getItem(id)).stream;

  Future<Item> getItem(int id) async {
    try {
      final dto = await _hackerNewsApiService.getItem(id);
      final item = Item.fromDto(dto);
      _itemStreamControllers.getOrAdd(id).add(item);
      return item;
    } on Object catch (e, st) {
      _itemStreamControllers.getOrAdd(id).addError(e, st);
      rethrow;
    }
  }

  /// Streams the whole comment tree for [id], in Hacker News' own order.
  ///
  /// Reads the item page, which returns the entire thread in one request. The
  /// Firebase API cannot: a comment holds only a `parent`, never a reference
  /// to its story, so a tree there costs one request per comment. Measured on
  /// a 1992-comment thread that was 2270 requests and 10.8 seconds, against a
  /// single request here, and the two produce byte-identical ordering,
  /// ancestry, authors and timestamps.
  ///
  /// The page is parsed as it downloads rather than after, because the body
  /// takes seconds to arrive and buffering it means staring at placeholders
  /// for all of them. Measured on that thread: the header lands at 0.86 s and
  /// the first comments at 1.19 s, against 5.1 s for everything at once.
  Stream<List<ItemDescendant>> getItemDescendantsStream(int id) =>
      _getPageDescendantsStream(id, _getItemPageStream(id));

  /// Fetches the item page, logged in when that is possible and sensible.
  ///
  /// The cookie is worth roughly 2% more rows, because dead and flagged
  /// comments only render for a profile with `showdead` set, and it measured
  /// faster than fetching anonymously.
  Stream<ItemPageChunk> _getItemPageStream(int id) async* {
    final String? userCookie = _preferAnonymous
        ? null
        : await _secureStorageService.getUserCookie();

    if (userCookie == null) {
      yield* _hackerNewsWebsiteService.getItemPageStream(id: id);
      return;
    }

    var blocked = false;
    try {
      // `await for` rather than `yield*`: inside an `async*` function `yield*`
      // hands a delegated stream's errors straight to the listener instead of
      // throwing here, which would leave this retry unreachable.
      await for (final chunk in _hackerNewsWebsiteService.getItemPageStream(
        id: id,
        userCookie: userCookie,
      )) {
        yield chunk;
      }
    } on HackerNewsProcrastinationException {
      blocked = true;
    }

    if (blocked) {
      _preferAnonymous = true;
      yield* _hackerNewsWebsiteService.getItemPageStream(id: id);
    }
  }

  /// Builds the tree as chunks arrive, seeding every item on the way.
  ///
  /// The ancestor stack, the child map and the descendant list all carry
  /// across chunks, so each instalment appends rather than rebuilding.
  ///
  /// Seeding matters as much as the fetch. `getOrAdd` only runs its async seed
  /// when the key is absent, so putting the item in first means the `ItemCubit`
  /// each row builds finds its data already there and never calls `getItem`.
  /// That is what removes the per-comment requests.
  Stream<List<ItemDescendant>> _getPageDescendantsStream(
    int id,
    Stream<ItemPageChunk> chunks,
  ) async* {
    final descendants = <ItemDescendant>[];
    final childIds = <int, List<int>>{id: []};
    final ancestors = <int>[id];
    final rows = <int, ItemPageRowDto>{};
    var emitted = false;

    await for (final chunk in chunks) {
      // A row seen in an earlier chunk can still gain children in this one, and
      // `ItemAction.delete` is gated on a comment having no children, so those
      // rows have to be seeded again rather than left stale.
      final stale = <int>{};

      for (final row in chunk.rows) {
        rows[row.id] = row;
        childIds.putIfAbsent(row.id, () => []);
        stale.add(row.id);

        if (row.isPart) {
          descendants.add(
            ItemDescendant(id: row.id, ancestorIds: [id], isPart: true),
          );
          continue;
        }

        // Indentation only grows one level at a time on a well-formed page. A
        // deeper jump would mean the markup changed, and treating the row as a
        // child of the current deepest one is what its indent implies anyway.
        final int depth = row.indent + 1;
        if (depth <= ancestors.length) ancestors.length = depth;

        descendants.add(
          ItemDescendant(id: row.id, ancestorIds: [...ancestors]),
        );
        childIds.putIfAbsent(ancestors.last, () => []).add(row.id);
        stale.add(ancestors.last);
        ancestors.add(row.id);
      }

      // Converting a row to an item parses its HTML again, so it goes to an
      // isolate. Doing it inline would put two thousand parses on the UI
      // thread, which is the cost this whole change exists to remove.
      final List<Item> items = await compute(_itemsFromRows, [
        for (final rowId in stale)
          if (rows[rowId] case final row?) (row, childIds[rowId] ?? const []),
      ]);
      for (final item in items) {
        _itemStreamControllers.getOrAdd(item.id).add(item);
      }

      if (chunk.story case final story?) {
        _itemStreamControllers
            .getOrAdd(id)
            .add(Item.fromDto(story).copyWith(childIds: () => childIds[id]!));
      } else if (stale.contains(id)) {
        // The story gained top-level comments, so its child list moved on.
        final Item? previous = _itemStreamControllers[id]?.valueOrNull;
        if (previous != null) {
          _itemStreamControllers
              .getOrAdd(id)
              .add(previous.copyWith(childIds: () => childIds[id]!));
        }
      }

      // The first chunk carries the story and no comments, and the item list
      // reads an empty list as "no comments", so emitting it flashes the empty
      // state for the third of a second before the first rows land.
      if (descendants.isEmpty) continue;
      emitted = true;
      yield [...descendants];
    }

    // A thread genuinely can have no comments, and that has to resolve to the
    // empty state rather than sit on the skeletons forever.
    if (!emitted) yield const [];
  }
}

/// Converts parsed rows into items, off the UI thread.
///
/// A row's text is Hacker News' own HTML, so building an item parses it again.
/// Two thousand of those inline would block the frame loop for exactly as long
/// as the streaming was meant to save.
List<Item> _itemsFromRows(List<(ItemPageRowDto, List<int>)> rows) => <Item>[
  for (final (row, childIds) in rows)
    Item.fromItemPageRowDto(row, childIds: childIds),
];
