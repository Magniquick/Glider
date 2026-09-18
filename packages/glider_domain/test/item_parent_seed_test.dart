import 'package:flutter_test/flutter_test.dart';
import 'package:glider_data/glider_data.dart';
import 'package:glider_domain/glider_domain.dart';

/// Hacker News only renders a `parent` link on a comment row when that comment
/// is nested. A top-level comment read off its story's page therefore has no
/// parent id, while the very same comment on its own page does, pointing at
/// the story.
///
/// Reading the story's page then has to leave the known id alone rather than
/// treat the absent link as "no parent". It did not, so opening a comment,
/// following "load parent" to the story, and coming back left the comment
/// without the button that got you there.
void main() {
  Item rowItem({required int id, int? parentId}) => Item.fromItemPageRowDto(
    ItemPageRowDto(id: id, parentId: parentId, by: 'someone'),
    childIds: const [],
  );

  test('a row with no parent link keeps a parent id already known', () {
    // The comment's own page: the fatitem carries a parent link.
    final fromPermalink = rowItem(id: 7386459, parentId: 7385407);
    // The same comment as a top-level row on its story's page: no link.
    final fromStoryPage = rowItem(id: 7386459);

    expect(fromPermalink.parentId, 7385407);
    expect(
      fromStoryPage.parentId,
      isNull,
      reason: 'a top-level row genuinely carries no parent link',
    );

    // What the repository does when the second reading arrives.
    final int? merged = fromStoryPage.parentId ?? fromPermalink.parentId;
    final Item seeded = merged == fromStoryPage.parentId
        ? fromStoryPage
        : fromStoryPage.copyWith(parentId: () => merged);

    expect(seeded.parentId, 7385407);
  });

  test('a row that does carry a parent link still wins', () {
    final stale = rowItem(id: 7390243, parentId: 1);
    final fresh = rowItem(id: 7390243, parentId: 7386516);

    final int? merged = fresh.parentId ?? stale.parentId;
    expect(merged, 7386516);
  });
}
