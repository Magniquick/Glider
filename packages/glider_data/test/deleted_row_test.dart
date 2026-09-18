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

/// A comment deleted by its author keeps its place in the tree when it has
/// replies, rendered with `[deleted]` in place of the body and no username.
/// `deleted_comment_permalink.html` holds the real markup for that, but only
/// as a fatitem, so the row path had nothing covering it and quietly reported
/// every row as not deleted. The tile reads that to decide whether to show the
/// marker, and `ItemAction` reads it to gate replying, voting and flagging.
String _withFirstRowDeleted(String body) {
  final int rowStart = body.indexOf('<tr class="athing comtr');
  final int rowEnd = body.indexOf('<tr class="athing comtr', rowStart + 1);
  final String row = body.substring(rowStart, rowEnd);

  // Exactly what Hacker News leaves behind: the marker as the whole body, and
  // the author's link gone from the header.
  final int textStart = row.indexOf('<div class="comment">');
  final int textEnd = row.indexOf('</td>', textStart);
  final String deletedRow =
      row.substring(0, textStart) +
      '<div class="comment">[deleted]<div class="reply"></div></div>' +
      row.substring(textEnd);

  return body.substring(0, rowStart) +
      deletedRow.replaceAll(RegExp('<a href="user[^<]*</a>'), '') +
      body.substring(rowEnd);
}

void main() {
  final String original = File('../../test/fixtures/comment_permalink.html')
      .readAsStringSync();

  test('a deleted comment row is reported as deleted', () async {
    final String body = _withFirstRowDeleted(original);
    expect(
      body,
      isNot(original),
      reason: 'the fixture must have a row to edit',
    );

    final page = await HackerNewsWebsiteService(_FileClient(body))
        .getItemPage(id: 1);

    expect(page.rows, hasLength(2));
    expect(
      page.rows.first.isDeleted,
      isTrue,
      reason: 'the row carries the [deleted] marker',
    );
    expect(page.rows.last.isDeleted, isFalse);
  });

  test('an ordinary row is not reported as deleted', () async {
    final page = await HackerNewsWebsiteService(_FileClient(original))
        .getItemPage(id: 1);

    expect(page.rows, isNotEmpty);
    expect(page.rows.every((row) => !row.isDeleted), isTrue);
  });
}
