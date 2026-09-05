import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:glider/common/models/status.dart';
import 'package:glider/item_tree/cubit/item_tree_cubit.dart';
import 'package:glider_domain/glider_domain.dart';

/// The real shape of `news.ycombinator.com/item?id=38309611`.
///
/// 2540 comments, 363 of them top level, nested up to thirteen deep. A real
/// thread matters here because the gaps between consecutive root comments vary
/// enormously, and it is the short gaps that expose the bug.
ItemTreeState _threadState() {
  final json = jsonDecode(
    File('test/fixtures/thread_38309611_shape.json').readAsStringSync(),
  ) as Map<String, dynamic>;
  final rows = json['rows'] as List<dynamic>;
  return ItemTreeState(
    status: Status.success,
    data: [
      for (final (index, row) in rows.indexed)
        ItemDescendant(
          id: 1000 + index,
          // Depth is the ancestor count and a root comment sits at depth one,
          // so an indent of n needs n + 1 ancestors.
          ancestorIds: List<int>.filled(
            ((row as List<dynamic>)[0] as int) + 1,
            0,
          ),
        ),
    ],
  );
}

/// Every root comment index, in order. What pressing next should walk.
List<int> _rootIndices(ItemTreeState state) => [
  for (final (index, descendant) in state.data!.indexed)
    if (descendant.depth == 1) index,
];

/// Presses "next root comment" [presses] times, reporting what it aimed at.
///
/// [landingOffset] is where the viewport ends up relative to the comment that
/// was targeted: zero is perfect, negative means the scroll stopped short.
/// [obstructedRows] is how many rows at the top the app bar covers, which is
/// what separates the raw visible range from the unobstructed one.
List<int> _pressNext(
  ItemTreeState state, {
  required int presses,
  required int landingOffset,
  required bool rememberTarget,
  int obstructedRows = 0,
}) {
  final targets = <int>[];
  var visibleStart = 0;
  int? lastTarget;

  for (var press = 0; press < presses; press++) {
    final visibleRange = (visibleStart, visibleStart + 20);
    final unobstructed = (visibleStart + obstructedRows, visibleStart + 20);
    final int origin = rememberTarget
        ? ItemTreeStateExtension.resolveJumpOrigin(
            visibleRange: visibleRange,
            lastTarget: lastTarget,
          )
        : unobstructed.$1;

    final int? next = state.getNextRootChildIndex(index: origin);
    if (next == null) break;

    targets.add(next);
    lastTarget = next;
    visibleStart = (next + landingOffset).clamp(0, state.data!.length - 1);
  }

  return targets;
}

void main() {
  group('jumping to the next root comment', () {
    test('reaches a new comment on every press, even landing short', () {
      final state = _threadState();
      final targets = _pressNext(
        state,
        presses: 100,
        landingOffset: -1,
        rememberTarget: true,
      );

      expect(targets, hasLength(100));
      expect(
        targets,
        orderedEquals(_rootIndices(state).skip(1).take(100)),
        reason: 'did not walk the root comments one at a time',
      );
    });

    test('skips nothing when the app bar obstructs the targeted row', () {
      final state = _threadState();
      final targets = _pressNext(
        state,
        presses: 100,
        landingOffset: 0,
        rememberTarget: true,
        obstructedRows: 1,
      );

      // The case behind childless root comments. With no replies between
      // them, the next root is the very next row, so an origin one row past
      // the target steps straight over it.
      expect(
        targets,
        orderedEquals(_rootIndices(state).skip(1).take(100)),
        reason: 'skipped a root comment',
      );
    });

    test('a perfect landing was never the problem', () {
      final state = _threadState();
      final targets = _pressNext(
        state,
        presses: 100,
        landingOffset: 0,
        rememberTarget: false,
      );

      expect(targets, orderedEquals(_rootIndices(state).skip(1).take(100)));
    });

    test('the viewport alone skips a root when the top row is obstructed', () {
      final state = _threadState();
      final targets = _pressNext(
        state,
        presses: 100,
        landingOffset: 0,
        rememberTarget: false,
        obstructedRows: 1,
      );

      expect(
        targets,
        isNot(orderedEquals(_rootIndices(state).skip(1).take(100))),
        reason: 'expected the old logic to skip past childless roots',
      );
    });

    test('survives a landing that stops short by any distance', () {
      final state = _threadState();
      final expected = _rootIndices(state).skip(1).take(60);

      for (final offset in [-15, -5, -2, -1, 0]) {
        expect(
          _pressNext(
            state,
            presses: 60,
            landingOffset: offset,
            rememberTarget: true,
          ),
          orderedEquals(expected),
          reason: 'a landing $offset rows out broke the walk',
        );
      }
    });

    test('survives the app bar covering more than one row', () {
      final state = _threadState();
      final expected = _rootIndices(state).skip(1).take(60);

      for (final obstructed in [1, 2, 5]) {
        expect(
          _pressNext(
            state,
            presses: 60,
            landingOffset: 0,
            rememberTarget: true,
            obstructedRows: obstructed,
          ),
          orderedEquals(expected),
          reason: '$obstructed obstructed rows broke the walk',
        );
      }
    });

    // The regression all of this exists for. Deriving the origin from the
    // viewport alone means a short landing re-finds the comment just jumped
    // to, so the button animates to where the reader already is and stops
    // moving. Keeping this proves the fix is load bearing.
    test('deriving the origin from the viewport alone gets stuck', () {
      final targets = _pressNext(
        _threadState(),
        presses: 100,
        landingOffset: -1,
        rememberTarget: false,
      );

      expect(
        targets.toSet(),
        hasLength(1),
        reason: 'expected every press to re-target the same comment',
      );
    });
  });
}
