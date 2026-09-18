import 'package:flutter_test/flutter_test.dart';
import 'package:glider_data/glider_data.dart';
import 'package:glider_domain/glider_domain.dart';

/// An empty child list is a claim that an item has no children, and the app
/// acts on it: `ItemAction.delete` is offered only when `childIds` is non-null
/// and empty, and the item screen sizes its loading skeletons from its length.
///
/// The Firebase API earns that claim, omitting `kids` exactly when there are
/// none. A scraped story list does not: its markup never carries children, so
/// reading `[]` off it said every story on the front page had no comments.
void main() {
  test('an absent Firebase kids list means childless', () {
    final item = Item.fromDto(const ItemDto(id: 1, type: 'story'));

    expect(item.childIds, isEmpty);
    expect(item.partIds, isEmpty);
  });

  test('Firebase children are carried through', () {
    final item = Item.fromDto(
      const ItemDto(id: 1, type: 'story', kids: [2, 3]),
    );

    expect(item.childIds, [2, 3]);
  });

  test('a source that never lists children reports unknown, not none', () {
    final item = Item.fromDto(
      const ItemDto(id: 1, type: 'story'),
      reportsChildren: false,
    );

    expect(
      item.childIds,
      isNull,
      reason: 'null is unknown; empty would claim there are no comments',
    );
    expect(item.partIds, isNull);
  });
}
