import 'package:flutter_test/flutter_test.dart';
import 'package:glider/common/models/status.dart';
import 'package:glider/item/cubit/item_cubit.dart';
import 'package:glider/item/models/vote_type.dart';
import 'package:glider_domain/glider_domain.dart';

/// The persisted interaction flags on [ItemState] have to survive the
/// `toMap`/`fromMap` round trip [ItemCubit] uses to hydrate. `fromMap` reads a
/// `visited` key that `toMap` never writes, so the flag is silently dropped on
/// every reload while its neighbours survive.
void main() {
  final item = Item(id: 1, type: ItemType.comment, username: 'someone');

  ItemState roundTrip(ItemState state) => ItemState.fromMap(state.toMap());

  group('ItemState survives a hydration round trip', () {
    // These pass today: they are the controls that prove the round trip works
    // for every persisted field except the one below.
    test('the vote is kept', () {
      final state = ItemState(
        status: Status.success,
        data: item,
        vote: VoteType.upvote,
      );
      expect(roundTrip(state).vote, VoteType.upvote);
    });

    test('favorited, flagged and blocked are kept', () {
      final state = ItemState(
        status: Status.success,
        data: item,
        favorited: true,
        flagged: true,
        blocked: true,
      );
      final restored = roundTrip(state);
      expect(restored.favorited, isTrue);
      expect(restored.flagged, isTrue);
      expect(restored.blocked, isTrue);
    });

    // Red: `toMap` omits the `visited` key that `fromMap` reads, so a visited
    // item comes back unvisited after any reload.
    test('visited is kept', () {
      final state = ItemState(
        status: Status.success,
        data: item,
        visited: true,
      );
      expect(roundTrip(state).visited, isTrue);
    });
  });
}
