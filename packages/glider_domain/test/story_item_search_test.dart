import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glider_data/glider_data.dart';
import 'package:glider_domain/glider_domain.dart';
import 'package:http/http.dart' as http;

/// Serves one saved page whatever is asked for, in pieces, because the tree is
/// parsed as the body arrives.
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

/// Searching a thread answers from the comments already in memory.
///
/// It used to ask Algolia, whose hits were then seeded back over the items the
/// page had produced. An Algolia hit carries no `childIds`, so that overwrote
/// the reply counts and the delete gating of every comment it matched.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          const MethodChannel('plugins.it_nomads.com/flutter_secure_storage'),
          (call) async => null,
        );
  });

  ItemRepository repositoryServing(String fixture) {
    final client = _FileClient(
      File('../../test/fixtures/$fixture').readAsStringSync(),
    );
    return ItemRepository(
      AlgoliaApiService(client),
      HackerNewsApiService(client),
      HackerNewsWebsiteService(client),
      const SecureStorageService(FlutterSecureStorage()),
    );
  }

  test('a thread is searchable once its tree has been read', () async {
    final repository = repositoryServing('comment_permalink.html');
    final descendants = await repository
        .getItemDescendantsStream(35155467)
        .last;
    expect(descendants, isNotEmpty);

    // Empty query returns the whole thread, in page order.
    final all = await repository.searchStoryItems(35155467);
    expect(
      all.map((item) => item.id),
      descendants.map((descendant) => descendant.id),
    );

    // Every comment kept the children the page gave it: that is the field an
    // Algolia hit does not carry.
    expect(all.every((item) => item.childIds != null), isTrue);
  });

  test('matching is on body and author, and misses report nothing', () async {
    final repository = repositoryServing('comment_permalink.html');
    await repository.getItemDescendantsStream(35155467).last;
    final all = await repository.searchStoryItems(35155467);

    final Item sample = all.first;
    final String word = sample.text!
        .split(RegExp(r'\s+'))
        .firstWhere((word) => word.length > 4);

    final byText = await repository.searchStoryItems(35155467, text: word);
    expect(byText.map((item) => item.id), contains(sample.id));

    final byAuthor = await repository.searchStoryItems(
      35155467,
      text: sample.username!.toUpperCase(),
    );
    expect(
      byAuthor.map((item) => item.id),
      contains(sample.id),
      reason: 'author matching ignores case',
    );

    final missing = await repository.searchStoryItems(
      35155467,
      text: 'zzzznotinthisthreadzzzz',
    );
    expect(missing, isEmpty);
  });

  test('a thread never read is searchable without throwing', () async {
    final repository = repositoryServing('comment_permalink.html');
    expect(await repository.searchStoryItems(1, text: 'anything'), isEmpty);
  });
}
