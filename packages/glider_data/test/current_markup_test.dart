import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glider_data/glider_data.dart';
import 'package:http/http.dart' as http;

class _FileClient(final String _body) extends http.BaseClient {
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = utf8.encode(_body);
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(<List<int>>[
        for (var i = 0; i < bytes.length; i += 512)
          bytes.sublist(i, (i + 512).clamp(0, bytes.length)),
      ]),
      200,
      contentLength: bytes.length,
      request: request,
    );
  }
}

HackerNewsWebsiteService _serving(String fixture) =>
    HackerNewsWebsiteService(_FileClient(_fixture(fixture)));

String _fixture(String name) =>
    File('../../test/fixtures/$name').readAsStringSync();

/// The saved item pages predate two changes to Hacker News' markup, so this
/// rewrites them into what is served now: author links lost
/// `class="hnuser"`, and `span.age` titles lost their fraction and the `Z`
/// that marked them UTC. Both broke parsing while the old fixtures kept
/// passing.
HackerNewsWebsiteService _currentMarkup(String fixture) =>
    HackerNewsWebsiteService(
      _FileClient(
        _fixture(fixture)
            .replaceAll(' class="hnuser"', '')
            .replaceAll('.000000Z"', '"'),
      ),
    );

void main() {
  test('a story list reads its authors from the current markup', () async {
    final String body = _fixture('front_page.html');
    expect(body, isNot(contains('hnuser')), reason: 'saved after the change');

    final StoryListDto list = await HackerNewsWebsiteService(_FileClient(body))
        .getStories(path: 'news');

    expect(list.stories, isNotEmpty);
    // Job posts carry no author, so not every story has one.
    expect(list.stories.where((story) => story.by != null), isNotEmpty);
    expect(
      list.stories.where((story) => story.score != null && story.by == null),
      isEmpty,
      reason: 'every scored story has an author',
    );
  });

  test('a story page reads its own author and its rows', () async {
    final ItemPageDto page = await _currentMarkup('show_hn.html')
        .getItemPage(id: 1);

    expect(page.story.by, 'stingrae');
    expect(page.rows, isNotEmpty);
    expect(page.rows.first.by, 'Rebelgecko');
  });

  test('a comment permalink reads its own author and its rows', () async {
    final ItemPageDto page = await _currentMarkup('comment_permalink.html')
        .getItemPage(id: 1);

    expect(page.story.by, 'Imnimo');
    expect(page.rows.map((row) => row.by), ['jsheard', 'spotplay']);
  });

  group('a timestamp without a zone is read as UTC', () {
    test('on a story list', () async {
      final String body = _fixture('front_page.html');
      expect(
        body,
        contains('title="2026-11-09T18:01:10"'),
        reason: 'the saved page carries no zone on its timestamps',
      );

      final StoryListDto list = await HackerNewsWebsiteService(
        _FileClient(body),
      ).getStories(path: 'news');

      expect(
        list.stories.first.time,
        DateTime.utc(2026, 11, 9, 18, 1, 10).millisecondsSinceEpoch ~/ 1000,
      );
    });

    test('on a comment row', () async {
      final ItemPageDto page = await _currentMarkup('comment_permalink.html')
          .getItemPage(id: 1);

      expect(page.rows, isNotEmpty);
      for (final ItemPageRowDto row in page.rows) {
        expect(DateTime.parse(row.timeIso!).isUtc, isTrue);
      }
    });

    test('and one that has a zone is left alone', () async {
      final ItemPageDto page = await _serving('comment_permalink.html')
          .getItemPage(id: 1);

      expect(page.rows.first.timeIso, endsWith('.000000Z'));
    });
  });
}
