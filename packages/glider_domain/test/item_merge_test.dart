import 'package:flutter_test/flutter_test.dart';
import 'package:glider_domain/glider_domain.dart';

/// Seeding an item must not let a source erase what it never reports.
///
/// Each source describes an item to a different depth, and they all write to
/// the same subject, so whichever wrote last used to decide what the app knew.
/// The tests below seed a fully described item and then lay a poorer reading
/// over it, which is the order that happens in the app: read a thread, then
/// open search, the inbox or a profile.
///
/// When [Item] gains a field, one of these fails rather than the field quietly
/// disappearing in whichever screen re-seeds it.
void main() {
  final complete = Item(
    id: 1,
    type: ItemType.comment,
    username: 'someone',
    dateTime: DateTime.fromMillisecondsSinceEpoch(1000),
    text: 'a body',
    isDead: true,
    isDeleted: true,
    parentId: 2,
    pollId: 3,
    childIds: const [4, 5],
    url: Uri.https('example.com'),
    score: 10,
    title: 'a title',
    partIds: const [6],
    descendantCount: 7,
  );

  group('a search hit keeps what Algolia does not index', () {
    // A hit carries an author and a body whenever the index holds the item,
    // and deleted or dead comments are not indexed at all, so their flags
    // cannot be read as false.
    final hit = Item(
      id: 1,
      username: 'someone',
      dateTime: DateTime.fromMillisecondsSinceEpoch(2000),
      text: 'an edited body',
      parentId: 2,
      url: Uri.https('example.com'),
      score: 99,
      title: 'a newer title',
      descendantCount: 42,
    );

    test('the fields it never carries survive', () {
      final merged = hit.mergedOnto(complete, ItemSource.search);

      expect(merged.type, ItemType.comment);
      expect(merged.isDeleted, isTrue);
      expect(merged.isDead, isTrue);
      expect(merged.pollId, 3);
      expect(merged.childIds, [4, 5]);
      expect(merged.partIds, [6]);
    });

    test('the fresher numbers it does carry win', () {
      final merged = hit.mergedOnto(complete, ItemSource.search);

      expect(merged.score, 99);
      expect(merged.descendantCount, 42);
      expect(merged.title, 'a newer title');
      expect(merged.text, 'an edited body');
    });
  });

  test('a comment row keeps the story fields a row is not rendered with', () {
    final row = Item(
      id: 1,
      type: ItemType.comment,
      username: 'someone',
      text: 'a body',
      parentId: 2,
      childIds: const [4],
    );
    final merged = row.mergedOnto(complete, ItemSource.pageRow);

    expect(merged.url, Uri.https('example.com'));
    expect(merged.score, 10);
    expect(merged.title, 'a title');
    expect(merged.descendantCount, 7);
    expect(merged.pollId, 3);
    // What the row does report is authoritative: it can see a deletion.
    expect(merged.childIds, [4]);
  });

  test('a story list keeps children it cannot see', () {
    final listed = Item(id: 1, type: ItemType.story, title: 'a title');
    final merged = listed.mergedOnto(complete, ItemSource.storyList);

    expect(merged.childIds, [4, 5]);
    expect(merged.partIds, [6]);
  });

  test('the API is authoritative and replaces outright', () {
    final fromApi = Item(id: 1, type: ItemType.story, title: 'a title');

    expect(fromApi.mergedOnto(complete, ItemSource.api), fromApi);
  });

  test('a deletion reported by a page is not undone by a merge', () {
    final deleted = Item(id: 1, type: ItemType.comment, isDeleted: true);
    final merged = deleted.mergedOnto(
      complete.copyWith(isDeleted: () => false),
      ItemSource.pageRow,
    );

    expect(
      merged.isDeleted,
      isTrue,
      reason:
          'a row reads the [deleted] marker, so it is reporting, not absent',
    );
  });
}
