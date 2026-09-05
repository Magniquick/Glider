import 'package:flutter/material.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

extension SuperSliverListExtension on SuperSliverList {
  static SuperSliverList builder({
    required NullableIndexedWidgetBuilder itemBuilder,
    required int itemCount,
    ListController? listController,
  }) => SuperSliverList(
    listController: listController,
    delegate: SliverChildBuilderDelegate(itemBuilder, childCount: itemCount),
    extentPrecalculationPolicy: ShortListExtentPrecalculationPolicy(),
  );
}

/// Measures every item up front, but only for lists short enough to be worth
/// it.
///
/// Precalculating means laying the item out, so doing it unconditionally
/// builds a whole two thousand comment thread in the background for a
/// scrollbar that is already close enough at that length.
///
/// Nothing tests this threshold, and the jump buttons landing badly was once
/// wrongly blamed on it; the cause was in `ItemTreeStateExtension`. Measure
/// before blaming it again.
class ShortListExtentPrecalculationPolicy() extends ExtentPrecalculationPolicy {
  static const int _threshold = 100;

  @override
  bool shouldPrecalculateExtents(ExtentPrecalculationContext context) =>
      context.numberOfItems < _threshold;
}
