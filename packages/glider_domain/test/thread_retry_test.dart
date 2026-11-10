import 'package:flutter_test/flutter_test.dart';
import 'package:glider_data/glider_data.dart';
import 'package:glider_domain/glider_domain.dart';

/// Serves a scripted answer per attempt at an item page.
class _ScriptedWebsite(final List<Stream<ItemPageChunk> Function()> _attempts)
    implements HackerNewsWebsiteService {
  StoryListDto stories = const StoryListDto(stories: []);
  int calls = 0;

  @override
  Stream<ItemPageChunk> getItemPageStream({
    required int id,
    int page = 1,
    String? userCookie,
    int batchSize = 100,
  }) => _attempts[calls++]();

  @override
  Future<StoryListDto> getStories({required String path, int page = 1}) async =>
      stories;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _Unused() implements AlgoliaApiService, HackerNewsApiService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoCookie() implements SecureStorageService {
  @override
  Future<String?> getUserCookie() async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _storyId = 1;

ItemDto _story({int? descendants, String type = 'story'}) =>
    ItemDto(id: _storyId, type: type, descendants: descendants);

Stream<ItemPageChunk> _page(ItemDto story, {int comments = 0}) =>
    Stream.fromIterable([
      ItemPageChunk(story: story),
      ItemPageChunk(
        rows: [
          for (var i = 0; i < comments; i++)
            ItemPageRowDto(id: 100 + i, by: 'someone', textHtml: 'hi'),
        ],
      ),
    ]);

Stream<ItemPageChunk> _dropped() =>
    Stream.error(HackerNewsRequestException(503, Uri()));

ItemRepository _repository(_ScriptedWebsite website) => ItemRepository(
  _Unused(),
  _Unused(),
  website,
  _NoCookie(),
  threadRetryDelays: const [
    Duration.zero,
    Duration.zero,
    Duration.zero,
    Duration.zero,
    Duration.zero,
  ],
);

void main() {
  test('a thread that fails and then loads is shown', () async {
    final website = _ScriptedWebsite([
      _dropped,
      _dropped,
      () => _page(_story(descendants: 2), comments: 2),
    ]);

    final List<ItemDescendant> tree = await _repository(website)
        .getItemDescendantsStream(_storyId)
        .last;

    expect(tree, hasLength(2));
    expect(website.calls, 3);
  });

  test('a thread that keeps failing is retried five times, then fails', () {
    final website = _ScriptedWebsite(List.filled(6, _dropped));

    expect(
      _repository(website).getItemDescendantsStream(_storyId).toList(),
      throwsA(isA<HackerNewsRequestException>()),
    );
    addTearDown(() => expect(website.calls, 6));
  });

  test('an item that does not exist is not retried', () async {
    final website = _ScriptedWebsite([
      () => Stream.error(HackerNewsItemNotFoundException(Uri())),
    ]);

    await expectLater(
      _repository(website).getItemDescendantsStream(_storyId).toList(),
      throwsA(isA<HackerNewsItemNotFoundException>()),
    );
    expect(website.calls, 1);
  });

  test('a story with no comments resolves to an empty thread', () async {
    final website = _ScriptedWebsite([() => _page(_story())]);

    expect(
      await _repository(website).getItemDescendantsStream(_storyId).last,
      isEmpty,
    );
  });

  group('a page with no rows for a story that has comments', () {
    test('fails when its own header gives the count', () async {
      final website = _ScriptedWebsite(
        List.filled(6, () => _page(_story(descendants: 12))),
      );

      await expectLater(
        _repository(website).getItemDescendantsStream(_storyId).toList(),
        throwsA(
          isA<MissingCommentsException>().having(
            (e) => e.expected,
            'expected',
            12,
          ),
        ),
      );
      expect(website.calls, 6, reason: 'it is retried like any failure');
    });

    test('fails when only the story list gave the count', () async {
      final website = _ScriptedWebsite(List.filled(6, () => _page(_story())))
        ..stories = const StoryListDto(
          stories: [ItemDto(id: _storyId, type: 'story', descendants: 7)],
        );
      final ItemRepository repository = _repository(website);
      await repository.getStories('news');

      await expectLater(
        repository.getItemDescendantsStream(_storyId).toList(),
        throwsA(isA<MissingCommentsException>()),
      );
    });

    test('recovers when a retry brings the rows', () async {
      final website = _ScriptedWebsite([
        () => _page(_story(descendants: 3)),
        () => _page(_story(descendants: 3), comments: 3),
      ]);

      expect(
        await _repository(website).getItemDescendantsStream(_storyId).last,
        hasLength(3),
      );
    });
  });
}
