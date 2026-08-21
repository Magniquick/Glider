import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
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
