import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glider_data/glider_data.dart';
import 'package:http/http.dart' as http;

/// Serves one saved page whatever is asked for.
///
/// Delivered in small pieces, because the streaming parse works on the body as
/// it arrives and a single-chunk response would never exercise that.
class _FileClient(final String _body) extends http.BaseClient {
  static const int _chunkSize = 512;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final bytes = utf8.encode(_body);
    return http.StreamedResponse(
      Stream<List<int>>.fromIterable(<List<int>>[
        for (var i = 0; i < bytes.length; i += _chunkSize)
          bytes.sublist(i, (i + _chunkSize).clamp(0, bytes.length)),
      ]),
      200,
      contentLength: bytes.length,
      request: request,
    );
  }
}

HackerNewsWebsiteService _serving(String fixture) => HackerNewsWebsiteService(
  _FileClient(File('../../test/fixtures/$fixture').readAsStringSync()),
);

/// Collapses the streaming parse back into a whole page, so a fixture can be
/// asserted against both paths.
Future<ItemPageDto> _streamed(HackerNewsWebsiteService service) async {
  final chunks = await service.getItemPageStream(id: 1).toList();
  return ItemPageDto(
    story: chunks.first.story!,
    rows: [for (final chunk in chunks) ...chunk.rows],
    hasMore: chunks.last.hasMore,
  );
}

void main() {
  // Hacker News renders a comment's own page with no `tr.athing.submission`:
  // the fatitem holds a bare `tr.athing` for the comment itself. Requiring a
  // submission row meant the parser returned nothing, and with no API fallback
  // behind it the screen stayed empty. Reachable from any comment's `parent`
  // link and from the inbox.
  test('a comment permalink parses, not just a story page', () async {
    final page = await _serving('comment_permalink.html').getItemPage(id: 1);

    expect(page.story.id, 35155467);
    expect(page.story.type, 'comment');
    expect(page.story.by, isNotNull);
    expect(page.story.text, isNotNull);
    expect(page.rows, hasLength(2));
    expect(page.rows.every((row) => !row.isPart), isTrue);
  });

  // The streaming parse only emitted the header once it had seen a comment
  // row, so a page that has none never emitted anything and ended by throwing.
  // That is not a rare shape: every job post, every story nobody has replied
  // to yet, and every comment permalink with no replies.
  group('a page with no comment rows still emits its item', () {
    test('job post', () async {
      final page = await _streamed(_serving('job_post.html'));

      expect(page.story.id, 49563415);
      expect(page.rows, isEmpty);
    });

    test('comment permalink', () async {
      final page = await _streamed(
        _serving('comment_permalink_no_replies.html'),
      );

      expect(page.story.id, 1079);
      expect(page.rows, isEmpty);
    });
  });

  // Job posts carry neither a score nor an author, which is what tells them
  // apart. The story lists already read that; the item page did not, so a job
  // opened from a list changed type under the reader and picked up vote,
  // reply, favorite and flag actions that Hacker News rejects.
  test('a job post is typed as a job on its own page', () async {
    final page = await _serving('job_post.html').getItemPage(id: 1);

    expect(page.story.type, 'job');
    expect(page.story.score, isNull);
    expect(page.story.descendants, isNull);
    expect(
      page.story.url,
      'https://www.ycombinator.com/companies/subimage/jobs/'
      'NCTFgKK-founding-engineer',
    );
    // An empty `div.toptext` is how Hacker News renders "no text at all", and
    // the tile lays out a text section for anything non-null.
    expect(page.story.text, isNull);
  });

  test('a poll keeps its options, their order and its type', () async {
    final page = await _serving('poll.html').getItemPage(id: 1);

    expect(page.story.type, 'poll');
    expect(page.story.id, 3746692);
    expect(page.story.score, 2423);
    expect(page.story.descendants, 570);
    // The title links back at the poll, so it is not an outbound URL.
    expect(page.story.url, isNull);

    final parts = page.rows.where((row) => row.isPart).toList();
    expect(parts.map((part) => part.id), [3746718, 3746720, 3746710]);
    expect(parts.map((part) => part.textHtml?.contains('Python')), [
      true,
      false,
      false,
    ]);
    expect(page.rows.where((row) => !row.isPart), hasLength(1));
  });

  test('a self post links nowhere and keeps its text', () async {
    final page = await _serving('ask_hn.html').getItemPage(id: 1);

    expect(page.story.type, 'story');
    expect(page.story.title, 'Ask HN: Resources to get good at soldering?');
    expect(page.story.url, isNull);
    expect(page.story.text, contains('soldering'));
  });

  test('a Show HN keeps both its link and its text', () async {
    final page = await _serving('show_hn.html').getItemPage(id: 1);

    expect(page.story.type, 'story');
    expect(page.story.url, 'https://opentrailpaper.com');
    expect(page.story.text, contains('Eink Bike computer'));
  });

  // Anonymously the body is replaced wholesale with the marker and there is no
  // author left to read, so the marker is the only thing that says the comment
  // is not simply empty.
  test('a dead comment permalink reports itself dead', () async {
    final page = await _serving('dead_comment_permalink.html')
        .getItemPage(id: 1);

    expect(page.story.id, 49579018);
    expect(page.story.dead, isTrue);
    expect(page.story.parent, 49571634);
  });

  test('a deleted comment permalink reports itself deleted', () async {
    final page = await _serving('deleted_comment_permalink.html')
        .getItemPage(id: 1);

    expect(page.story.id, 49579049);
    expect(page.story.deleted, isTrue);
  });

  // Both mean "there is nothing here for you", not "the markup moved", and
  // only the second is worth reporting as a defect in this parser.
  group('an item that cannot be shown is reported as missing', () {
    test('an id that was never used', () {
      expect(
        _serving('no_such_item.html').getItemPage(id: 1),
        throwsA(isA<HackerNewsItemNotFoundException>()),
      );
    });

    test('a killed story, viewed anonymously', () {
      expect(
        _serving('withheld_item.html').getItemPage(id: 1),
        throwsA(isA<HackerNewsItemNotFoundException>()),
      );
    });

    test('the streaming parse agrees', () {
      expect(
        _serving('withheld_item.html').getItemPageStream(id: 1).toList(),
        throwsA(isA<HackerNewsItemNotFoundException>()),
      );
    });
  });
}
