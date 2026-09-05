import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:glider_data/src/dtos/item_dto.dart';
import 'package:glider_data/src/dtos/item_page_dto.dart';
import 'package:glider_data/src/dtos/story_list_dto.dart';
import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;
import 'package:http/http.dart' as http;

/// Thrown when Hacker News does not hand back the one-time token an
/// authenticated action needs.
///
/// In practice this means the stored session cookie is no longer valid: a
/// logged-out item page carries no `auth` parameter, and `/submit` renders
/// "You have to be logged in to submit." with no hidden `fnid`.
class const HackerNewsAuthException(this.action) implements Exception {
  /// Creates an exception for the named [action].
  this;

  /// The action that could not be authorised, e.g. `vote`.
  final String action;

  @override
  String toString() =>
      'Hacker News did not authorise the $action request. '
      'The session has most likely expired.';
}

/// Thrown when Hacker News answers a request with a non-success status.
class const HackerNewsRequestException(this.statusCode, this.uri)
    implements Exception {
  /// Creates an exception for [statusCode] returned by [uri].
  this;

  /// The HTTP status Hacker News returned.
  final int statusCode;

  /// The request that failed.
  final Uri uri;

  @override
  String toString() => 'Hacker News returned HTTP $statusCode for $uri.';
}

/// Thrown when Hacker News served its anti-procrastination interstitial.
///
/// `check-procrast` in news.arc replaces the whole page body with
/// `<div class="noprocrast">` once a logged-in user is past their `maxvisit`
/// window, so there is nothing on the page to parse.
///
/// Retrying without the cookie always succeeds, because the same function
/// exempts anonymous requests outright:
///
/// ```arc
/// (def check-procrast (user)
///   (or (no user)
///       (no (uvar user noprocrast))
/// ```
///
/// Worth going further than a retry, though. Every authenticated view that
/// does get through writes `lastview` forward, so a client that keeps sending
/// the cookie spends the reading budget the setting exists to protect. Once
/// this is seen, prefer anonymous fetches for the rest of the session.
class const HackerNewsProcrastinationException(this.uri) implements Exception {
  /// Creates an exception for the page at [uri].
  this;

  /// The page that was withheld.
  final Uri uri;

  @override
  String toString() =>
      "Hacker News withheld $uri under the account's noprocrast setting.";
}

/// Thrown when an item page came back but did not look like one.
///
/// In practice this means the markup this parser depends on has changed.
/// Callers are expected to fall back to the Firebase API rather than surface
/// this.
class const HackerNewsParseException(this.uri) implements Exception {
  /// Creates an exception for the page at [uri].
  this;

  /// The page that could not be parsed.
  final Uri uri;

  @override
  String toString() => 'Hacker News served no parseable item page at $uri.';
}

/// Outcome of a [HackerNewsWebsiteService.logIn] attempt.
enum LogInResult() {
  /// The session cookie was obtained.
  success,

  /// Hacker News reported `Bad login.`
  badCredentials,

  /// Hacker News refused the request outright, e.g. HTTP 429 for an embedded
  /// browser user agent.
  rejected,

  /// Hacker News served a validation or captcha challenge, which cannot be
  /// completed inside the app.
  challengeRequired,

  /// Something else went wrong: an outage, or a change to the login form.
  failure
}

class const HackerNewsWebsiteService(
  final http.Client _client, {
  final String userAgent = _defaultUserAgent,
}) {
  static const String authority = 'news.ycombinator.com';

  /// Hacker News refuses requests from embedded browsers on `/login` and
  /// `/submit`, which it detects by the `wv` and `Version/4.0` tokens that
  /// Android's WebView adds to its user agent. A self-identifying client is
  /// accepted, so send one rather than impersonating a browser.
  static const String _defaultUserAgent = 'Glider';

  /// Submits credentials to the Hacker News login form, returning the `user`
  /// session cookie on success.
  ///
  /// The password is sent to Hacker News and never retained; only the returned
  /// cookie is persisted, by the caller.
  Future<(LogInResult, String? userCookie)> logIn({
    required String username,
    required String password,
  }) async {
    // Success is a 302 carrying `Set-Cookie`, so redirects must not be
    // followed or the cookie is lost.
    final request = http.Request('POST', Uri.https(authority, 'login'))
      ..followRedirects = false
      ..headers.addAll(_getHeaders())
      ..bodyFields = <String, String>{
        'acct': username,
        'pw': password,
        'goto': 'news',
      };
    final response = await http.Response.fromStream(
      await _client.send(request),
    );

    if (response.statusCode == 429) return (LogInResult.rejected, null);

    final userCookie = _parseUserCookie(response.headers['set-cookie']);
    if (userCookie != null) return (LogInResult.success, userCookie);

    // Distinguish an actually-wrong password from everything else. Reporting
    // "incorrect password" for a captcha challenge or an outage just makes the
    // user retry credentials that were fine.
    final body = response.body;
    if (body.contains('Bad login.')) return (LogInResult.badCredentials, null);
    if (body.contains('Validation required') || body.contains('recaptcha')) {
      return (LogInResult.challengeRequired, null);
    }
    return (LogInResult.failure, null);
  }

  static String? _parseUserCookie(String? setCookieHeader) {
    if (setCookieHeader == null) return null;
    // `expires` values contain commas, so the joined header cannot be split on
    // them; match the cookie by name instead.
    final match = RegExp(r'(?:^|[,;]\s*)user=([^;]+)')
        .firstMatch(setCookieHeader);
    final value = match?.group(1);
    return value != null && value.isNotEmpty ? value : null;
  }

  /// Fetches an item and its whole comment tree as one page.
  ///
  /// This exists because the Firebase API has no way to return a thread: it
  /// holds no story reference on a comment, only a `parent`, so a tree costs
  /// one request per comment. A 1992-comment thread measured 2270 requests and
  /// 10.8 seconds that way, against roughly 1.5 seconds here.
  ///
  /// Pass [userCookie] when there is one. It is worth about 2% more rows,
  /// because dead and flagged comments are only rendered for a profile with
  /// `showdead` set, and it makes every row carry a vote `auth` token.
  Future<ItemPageDto> getItemPage({
    required int id,
    int page = 1,
    String? userCookie,
  }) async {
    final endpoint = Uri.https(authority, 'item', <String, String>{
      'id': id.toString(),
      if (page > 1) 'p': page.toString(),
    });
    final response = await _performGet(endpoint, userCookie: userCookie);
    // Cheaper to spot by substring than to parse a page that holds nothing but
    // the interstitial, and it has to be distinguished from a markup change:
    // this one is fixed by dropping the cookie, not by falling back to the API.
    if (response.body.contains('class="noprocrast"')) {
      throw HackerNewsProcrastinationException(endpoint);
    }
    final ItemPageDto? parsed = await compute(_parseItemPage, response.body);
    return parsed ?? (throw HackerNewsParseException(endpoint));
  }

  /// Parses an item page while it is still arriving.
  ///
  /// Same single request as [getItemPage], but emits the submission as soon as
  /// the header has landed and then batches of comments as they stream in,
  /// rather than after the whole body. On a 2000-comment thread the body takes
  /// around 5 seconds to arrive, so buffering it costs that long staring at
  /// placeholders. This is what the browser does, and why the page appears to
  /// grow as you watch it.
  ///
  /// Every parse runs through `compute`, so the isolate does the HTML work and
  /// the UI thread only ever receives finished data.
  Stream<ItemPageChunk> getItemPageStream({
    required int id,
    int page = 1,
    String? userCookie,
    int batchSize = 100,
  }) async* {
    final endpoint = Uri.https(authority, 'item', <String, String>{
      'id': id.toString(),
      if (page > 1) 'p': page.toString(),
    });
    final request = http.Request('GET', endpoint)
      ..headers.addAll(_getHeaders(userCookie: userCookie));
    final response = await _client.send(request);
    if (response.statusCode >= 400) {
      throw HackerNewsRequestException(response.statusCode, endpoint);
    }

    // Only the tail that has not yet formed a complete unit is kept, so this
    // stays a few kilobytes however large the thread is. Holding the whole
    // document instead would make every append a multi-megabyte copy.
    var pending = '';
    var storyEmitted = false;
    var batch = <String>[];

    await for (final text in response.stream.transform<String>(utf8.decoder)) {
      // A StringBuffer cannot be searched, and `pending` never holds more than
      // one incomplete row because rows are consumed as soon as they close, so
      // this concatenation stays bounded rather than growing with the page.
      // ignore: use_string_buffers
      pending += text;

      if (!storyEmitted) {
        final int start = pending.indexOf(_rowMarker);
        // The header is not complete until the first comment row begins.
        if (start < 0) continue;
        final ItemPageDto? head = await compute(
          _parseItemPage,
          pending.substring(0, start),
        );
        if (head == null) throw _pageException(pending, endpoint);
        yield ItemPageChunk(story: head.story, rows: head.rows);
        pending = pending.substring(start);
        storyEmitted = true;
      }

      // A row is only whole once the next one starts, so the final match stays
      // behind for the next chunk to finish.
      //
      // Scanning by index and compacting once at the end matters: reassigning
      // `pending` per row would re-copy the rest of the chunk every time, which
      // is quadratic in the chunk size. `indexOf` itself is the VM's native
      // string search, so the scan stays linear and stays out of Dart.
      var start = 0;
      for (
        int next = pending.indexOf(_rowMarker, start + 1);
        next >= 0;
        next = pending.indexOf(_rowMarker, start + 1)
      ) {
        batch.add(pending.substring(start, next));
        start = next;
      }
      if (start > 0) pending = pending.substring(start);

      if (batch.length >= batchSize) {
        yield ItemPageChunk(rows: await compute(_parseRowBatch, batch));
        batch = <String>[];
      }
    }

    if (!storyEmitted) throw _pageException(pending, endpoint);

    // Whatever is left is the final row plus the page footer.
    if (pending.isNotEmpty) batch.add(pending);
    yield ItemPageChunk(
      rows: batch.isEmpty ? const [] : await compute(_parseRowBatch, batch),
      hasMore: pending.contains('morelink'),
    );
  }

  /// Tells a reading limit apart from markup that no longer parses.
  ///
  /// They need different handling: the first is fixed by dropping the cookie,
  /// the second by falling back to the API.
  static Exception _pageException(String body, Uri endpoint) =>
      body.contains('class="noprocrast"')
      ? HackerNewsProcrastinationException(endpoint)
      : HackerNewsParseException(endpoint);

  /// Fetches one page of a story list, e.g. `news`, `newest`, `best`.
  ///
  /// The Firebase API returns only ids for these, so the app then fetched each
  /// story separately: roughly 26 requests per page. A page carries all thirty
  /// stories complete, in ranked order, for under 7 KB gzipped.
  ///
  /// Deliberately anonymous. Nothing here needs the session, and an anonymous
  /// page is the one Hacker News can serve from cache.
  Future<StoryListDto> getStories({required String path, int page = 1}) async {
    final endpoint = Uri.https(authority, path, <String, String>{
      if (page > 1) 'p': page.toString(),
    });
    final response = await _performGet(endpoint);
    return await compute(_parseStoryList, response.body);
  }

  Future<Iterable<int>> getUpvoted({
    required String username,
    required String userCookie,
  }) async {
    return [
      ...await _getUpvotedType(
        username: username,
        userCookie: userCookie,
        comments: false,
      ),
      ...await _getUpvotedType(
        username: username,
        userCookie: userCookie,
        comments: true,
      ),
    ].sorted((a, b) => b.compareTo(a));
  }

  Future<Iterable<int>> _getUpvotedType({
    required String username,
    required String userCookie,
    required bool comments,
    int page = 1,
  }) async {
    final uri = Uri.https(authority, 'upvoted', <String, String>{
      'id': username,
      if (page > 1) 'p': page.toString(),
      if (comments) 'comments': 't',
    });
    final response = await _performGet(uri, userCookie: userCookie);
    final document = await compute(html_parser.parse, response.body);
    return await document.getThingIds(
      onMore: () => _getUpvotedType(
        username: username,
        userCookie: userCookie,
        page: page + 1,
        comments: comments,
      ),
    );
  }

  Future<Iterable<int>> getFavorited({required String username}) async {
    return [
      ...await _getFavoritedType(username: username, comments: false),
      ...await _getFavoritedType(username: username, comments: true),
    ].sorted((a, b) => b.compareTo(a));
  }

  Future<Iterable<int>> _getFavoritedType({
    required String username,
    required bool comments,
    int page = 1,
  }) async {
    final uri = Uri.https(authority, 'favorites', <String, String>{
      'id': username,
      if (page > 1) 'p': page.toString(),
      if (comments) 'comments': 't',
    });
    final response = await _performGet(uri);
    final document = await compute(html_parser.parse, response.body);
    return await document.getThingIds(
      onMore: () => _getFavoritedType(
        username: username,
        page: page + 1,
        comments: comments,
      ),
    );
  }

  Future<Iterable<int>> getFlagged({
    required String username,
    required String userCookie,
  }) async {
    return [
      ...await _getFlaggedType(
        username: username,
        userCookie: userCookie,
        comments: false,
      ),
      ...await _getFlaggedType(
        username: username,
        userCookie: userCookie,
        comments: true,
      ),
    ].sorted((a, b) => b.compareTo(a));
  }

  Future<Iterable<int>> _getFlaggedType({
    required String username,
    required String userCookie,
    required bool comments,
    int page = 1,
  }) async {
    final uri = Uri.https(authority, 'flagged', <String, String>{
      'id': username,
      if (page > 1) 'p': page.toString(),
      if (comments) 'kind': 'comment',
    });
    final response = await _performGet(uri, userCookie: userCookie);
    final document = await compute(html_parser.parse, response.body);
    return await document.getThingIds(
      onMore: () => _getFlaggedType(
        username: username,
        userCookie: userCookie,
        page: page + 1,
        comments: comments,
      ),
    );
  }

  Future<void> upvote({
    required int id,
    required bool upvote,
    required String userCookie,
  }) async {
    final auth = await _getAuthValue(id: id, userCookie: userCookie);
    final endpoint = Uri.https(authority, 'vote');
    final body = <String, String>{
      'id': id.toString(),
      'how': upvote ? 'up' : 'un',
      'auth': _require(auth, 'vote'),
    };
    await _performPost(endpoint, body: body, userCookie: userCookie);
  }

  Future<void> downvote({
    required int id,
    required bool downvote,
    required String userCookie,
  }) async {
    final auth = await _getAuthValue(id: id, userCookie: userCookie);
    final endpoint = Uri.https(authority, 'vote');
    final body = <String, String>{
      'id': id.toString(),
      'how': downvote ? 'down' : 'un',
      'auth': _require(auth, 'vote'),
    };
    await _performPost(endpoint, body: body, userCookie: userCookie);
  }

  Future<void> favorite({
    required int id,
    required bool favorite,
    required String userCookie,
  }) async {
    final auth = await _getAuthValue(id: id, userCookie: userCookie);
    final endpoint = Uri.https(authority, 'fave');
    final body = <String, String>{
      'id': id.toString(),
      if (!favorite) 'un': 't',
      'auth': _require(auth, 'vote'),
    };
    await _performPost(endpoint, body: body, userCookie: userCookie);
  }

  Future<void> flag({
    required int id,
    required bool flag,
    required String userCookie,
  }) async {
    final auth = await _getAuthValue(id: id, userCookie: userCookie);
    final endpoint = Uri.https(authority, 'flag');
    final body = <String, String>{
      'id': id.toString(),
      if (!flag) 'un': 't',
      'auth': _require(auth, 'vote'),
    };
    await _performPost(endpoint, body: body, userCookie: userCookie);
  }

  Future<void> edit({
    required int id,
    String? title,
    String? text,
    required String userCookie,
  }) async {
    final hmac = await _getHmacValue(
      path: 'edit',
      id: id,
      userCookie: userCookie,
    );
    final endpoint = Uri.https(authority, 'xedit');
    final body = <String, String>{
      'id': id.toString(),
      'title': ?title,
      'text': ?text,
      'hmac': _require(hmac, 'edit'),
    };
    await _performPost(endpoint, body: body, userCookie: userCookie);
  }

  Future<void> delete({required int id, required String userCookie}) async {
    final hmac = await _getHmacValue(
      path: 'delete-confirm',
      id: id,
      userCookie: userCookie,
    );
    final endpoint = Uri.https(authority, 'xdelete');
    final body = <String, String>{
      'id': id.toString(),
      'd': 'Yes',
      'hmac': _require(hmac, 'edit'),
    };
    await _performPost(endpoint, body: body, userCookie: userCookie);
  }

  Future<void> reply({
    required int parentId,
    required String text,
    required String userCookie,
  }) async {
    final hmac = await _getHmacValue(id: parentId, userCookie: userCookie);
    final endpoint = Uri.https(authority, 'comment');
    final body = <String, String>{
      'parent': parentId.toString(),
      'text': text,
      'hmac': _require(hmac, 'edit'),
      'goto': 'item?id=$parentId',
    };
    await _performPost(endpoint, body: body, userCookie: userCookie);
  }

  Future<void> submit({
    required String title,
    String? url,
    String? text,
    required String userCookie,
  }) async {
    final (fnid, fnop) = await _getFnidFnopValues(userCookie: userCookie);
    final endpoint = Uri.https(authority, 'r');
    final body = <String, String>{
      'title': title,
      'url': ?url,
      'text': ?text,
      'fnid': _require(fnid, 'submit'),
      'fnop': _require(fnop, 'submit'),
    };
    await _performPost(endpoint, body: body, userCookie: userCookie);
  }

  Future<String?> _getAuthValue({
    String path = 'item',
    required int id,
    required String userCookie,
  }) async {
    final endpoint = Uri.https(authority, path, <String, dynamic>{
      'id': id.toString(),
    });
    final response = await _performGet(endpoint, userCookie: userCookie);
    final voteHref = await compute(
      (body) =>
          html_parser.parse(body).getElementById('up_$id')?.attributes['href'],
      response.body,
    );

    if (voteHref == null) {
      return null;
    }

    final voteUrl = Uri.parse(voteHref);
    return voteUrl.queryParameters['auth'];
  }

  Future<String?> _getHmacValue({
    String path = 'item',
    required int id,
    required String userCookie,
  }) async {
    final endpoint = Uri.https(authority, path, <String, dynamic>{
      'id': id.toString(),
    });
    final response = await _performGet(endpoint, userCookie: userCookie);
    return await compute(
      (body) => html_parser
          .parse(body)
          .hiddenFormAttributes
          ?.getAttributeValue('hmac'),
      response.body,
    );
  }

  Future<(String? fnid, String? fnop)> _getFnidFnopValues({
    required String userCookie,
  }) async {
    final endpoint = Uri.https(authority, 'submit');
    final response = await _performGet(endpoint, userCookie: userCookie);
    return await compute((body) {
      final attributes = html_parser.parse(body).hiddenFormAttributes;
      return (
        attributes?.getAttributeValue('fnid'),
        attributes?.getAttributeValue('fnop'),
      );
    }, response.body);
  }

  /// Returns [value], or reports an expired session for [action].
  static String _require(String? value, String action) =>
      value ?? (throw HackerNewsAuthException(action));

  /// Hacker News answers rate limits with 429 and errors with an HTML page.
  /// Without this check a failed page fetch simply parses to nothing, which
  /// silently truncates paginated results instead of reporting a problem.
  static http.Response _ensureSuccess(http.Response response, Uri endpoint) {
    if (response.statusCode >= 400) {
      throw HackerNewsRequestException(response.statusCode, endpoint);
    }
    return response;
  }

  Future<http.Response> _performGet(Uri endpoint, {String? userCookie}) async =>
      _ensureSuccess(
        await _client.get(
          endpoint,
          headers: _getHeaders(userCookie: userCookie),
        ),
        endpoint,
      );

  Future<http.Response> _performPost(
    Uri endpoint, {
    Object? body,
    String? userCookie,
  }) async => _ensureSuccess(
    await _client.post(
      endpoint,
      body: body,
      headers: _getHeaders(userCookie: userCookie),
    ),
    endpoint,
  );

  Map<String, String> _getHeaders({String? userCookie}) => <String, String>{
    'user-agent': userAgent,
    if (userCookie != null) 'cookie': 'user=$userCookie',
  };
}

/// Start of a comment row, and the only reliable boundary between rows.
///
/// Rows nest tables, so `</tr>` is ambiguous; a row is instead taken to end
/// where the next one begins. The class attribute continues past this, as
/// `comtr noshow` or `comtr coll` for a collapsed subtree, so the marker stops
/// short of the closing quote.
const _rowMarker = '<tr class="athing comtr';

/// Parses a batch of raw comment rows, each one a slice of the page.
///
/// A bare `<tr>` would be discarded by the HTML5 tree builder, which only
/// keeps table rows inside a table, so each slice is parsed in a `tbody`.
List<ItemPageRowDto> _parseRowBatch(List<String> rows) => <ItemPageRowDto>[
  for (final row in rows)
    if (html_parser
            .parseFragment(row, container: 'tbody')
            .querySelector('.comtr')
        case final element?)
      if (int.tryParse(element.id) case final int id) element.toRowDto(id),
];

/// Parses an item page into its submission and every row below it.
///
/// Returns null when the page is not an item page at all, which in practice
/// means a `noprocrast` interstitial. Runs through `compute`, so it takes and
/// returns plain data: the largest threads are around 5.4 MB of HTML, far too
/// much to parse on the UI thread.
ItemPageDto? _parseItemPage(String body) {
  final html_dom.Document document = html_parser.parse(body);
  final html_dom.Element? submission = document.querySelector(
    'tr.athing.submission',
  );
  if (submission == null) return null;

  final rows = <ItemPageRowDto>[
    // Poll options are bare `tr.athing` rows inside the fatitem, neither a
    // submission nor a comment, holding their text in `td.comment`.
    for (final element in document.querySelectorAll('table.fatitem tr.athing'))
      if (!element.classes.contains('submission') &&
          !element.classes.contains('comtr'))
        if (int.tryParse(element.id) case final int id)
          ItemPageRowDto(
            id: id,
            textHtml: element.querySelector('td.comment')?.innerHtml,
            isPart: true,
          ),
    // Comment rows carry `comtr` plus, when a subtree is collapsed, `noshow`
    // or `coll`. Those variants still hold every field, so match on the one
    // class they share rather than on the exact attribute.
    for (final element in document.querySelectorAll('.comtr'))
      if (int.tryParse(element.id) case final int id) element.toRowDto(id),
  ];

  return ItemPageDto(
    story: _parseStory(document, submission),
    rows: rows,
    hasMore: document.querySelector('a.morelink') != null,
  );
}

/// Reads a submission row into a DTO.
///
/// Shared by the item page and the story lists: both render a submission as a
/// `tr.athing.submission` for the title, with score, author, age and comment
/// count in a sibling `td.subtext`. Only where those elements live differs.
ItemDto _storyDto(
  html_dom.Element submission, {
  html_dom.Element? subtext,
  html_dom.Element? toptext,
  String type = 'story',
}) {
  final html_dom.Element? titleAnchor = submission.querySelector(
    'span.titleline a',
  );
  final String? href = titleAnchor?.attributes['href'];
  // A text submission links its own title back at itself; that is not a URL
  // the app should render as an outbound link.
  final bool isSelfLink = href == null || href.startsWith('item?id=');

  return ItemDto(
    id: int.tryParse(submission.id) ?? 0,
    type: type,
    by: subtext?.querySelector('a.hnuser')?.text,
    time: subtext?.querySelector('span.age')?.epochSeconds,
    text: toptext?.innerHtml,
    url: isSelfLink ? null : href,
    score: subtext?.querySelector('span.score')?.leadingInt,
    title: titleAnchor?.text,
    descendants: subtext?.leadingIntBefore('comment'),
  );
}

/// Builds the submission's own DTO from the fatitem table.
ItemDto _parseStory(html_dom.Document document, html_dom.Element submission) {
  final html_dom.Element? fatitem = document.querySelector('table.fatitem');
  final bool isPoll = document
      .querySelectorAll('table.fatitem tr.athing')
      .any(
        (e) =>
            !e.classes.contains('submission') && !e.classes.contains('comtr'),
      );

  return _storyDto(
    submission,
    subtext: fatitem?.querySelector('td.subtext'),
    toptext: fatitem?.querySelector('div.toptext'),
    type: isPoll ? 'poll' : 'story',
  );
}

/// Parses one page of a story list.
///
/// Thirty submissions per page, which is exactly the app's own page size, so a
/// page maps one to one onto what the list needs. The subtext is the row's next
/// sibling rather than a child, because Hacker News lays each story out as two
/// table rows.
StoryListDto _parseStoryList(String body) {
  final html_dom.Document document = html_parser.parse(body);
  final stories = <ItemDto>[
    for (final submission in document.querySelectorAll('tr.athing.submission'))
      if (submission.nextElementSibling?.querySelector('td.subtext')
          case final subtext?)
        _storyDto(
          submission,
          subtext: subtext,
          // Job posts carry neither a score nor an author, which is the only
          // thing that distinguishes them here.
          type: subtext.querySelector('span.score') == null ? 'job' : 'story',
        ),
  ];

  return StoryListDto(
    stories: stories,
    hasMore: document.querySelector('a.morelink') != null,
  );
}

extension on html_dom.Element {
  /// Reads this row's fields, given the [id] already parsed from it.
  ItemPageRowDto toRowDto(int id) {
    // Logged in, the marker is a bare text node in the header, e.g. `<span
    // id="unv_49562690"></span> [dead] <span class="navs">`. Anonymously the
    // header stays clean and the body is replaced wholesale instead, as
    // `<div class="comment noshow">[flagged]`, with no commtext at all.
    final String head = querySelector('span.comhead')?.text ?? '';
    final String comment = querySelector('div.comment')?.text ?? '';
    final String? voteHref = querySelectorAll('a')
        .firstWhereOrNull((e) => e.id.startsWith('up_'))
        ?.attributes['href'];

    return ItemPageRowDto(
      id: id,
      parentId: parentAnchorId,
      indent:
          int.tryParse(querySelector('td.ind')?.attributes['indent'] ?? '') ??
          0,
      by: querySelector('a.hnuser')?.text,
      timeIso: querySelector('span.age')?.isoTimestamp,
      textHtml: querySelector('div.commtext')?.innerHtml,
      subtreeCount: int.tryParse(
        querySelector('a.togg')?.attributes['n'] ?? '',
      ),
      isDead:
          head.contains('[dead]') ||
          head.contains('[flagged]') ||
          comment.startsWith('[flagged]'),
      voteAuth: voteHref != null
          ? Uri.tryParse(voteHref)?.queryParameters['auth']
          : null,
    );
  }

  /// The id behind this row's `parent` link, absent on a top-level comment.
  ///
  /// The same `span.navs` holds `root`, `prev` and `next` links, so match on
  /// the label rather than on position.
  int? get parentAnchorId => int.tryParse(
    querySelectorAll('span.navs a')
            .firstWhereOrNull((anchor) => anchor.text == 'parent')
            ?.attributes['href']
            ?.replaceFirst('#', '') ??
        '',
  );

  /// The exact timestamp from an `span.age` title, e.g.
  /// `2026-09-04T11:01:58.000000Z`.
  ///
  /// Preferred over the anchor's "22 hours ago" text, which is both imprecise
  /// and localised. Some pages append an epoch after a space.
  String? get isoTimestamp => attributes['title']?.split(' ').first;

  /// [isoTimestamp] as whole seconds since the epoch, as Firebase reports it.
  int? get epochSeconds => switch (isoTimestamp) {
    final String iso => switch (DateTime.tryParse(iso)) {
      final DateTime parsed => parsed.millisecondsSinceEpoch ~/ 1000,
      _ => null,
    },
    _ => null,
  };

  /// The first run of digits in this element's text, e.g. `2172 points`.
  int? get leadingInt =>
      int.tryParse(RegExp(r'\d+').firstMatch(text)?.group(0) ?? '');

  /// The number immediately before [word] in this element's text.
  ///
  /// Hacker News writes the comment count as `1996&nbsp;comments`, so the
  /// separator cannot be assumed to be an ordinary space.
  int? leadingIntBefore(String word) =>
      int.tryParse(RegExp('(\\d+)\\s*$word').firstMatch(text)?.group(1) ?? '');
}

extension on html_dom.Document {
  Iterable<Map<Object, String>>? get hiddenFormAttributes =>
      getElementsByTagName('form').firstOrNull
          ?.querySelectorAll("input[type='hidden']")
          .map((element) => element.attributes);

  Future<Iterable<int>> getThingIds({
    required Future<Iterable<int>> Function() onMore,
  }) async => <int>[
    ...querySelectorAll('.athing').map((thing) => int.parse(thing.id)),
    if (querySelector('.morelink') != null) ...await onMore(),
  ];
}

extension on Iterable<Map<Object, String>> {
  String? getAttributeValue(String name) =>
      firstWhereOrNull((attributes) => attributes['name'] == name)?['value'];
}
