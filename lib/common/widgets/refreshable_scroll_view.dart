import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

// This value happens to fit a page worth of items (30) with the standard height
// of an item in the stories overview (92). It does not appear to have a
// significant negative impact on initial load performance, while making
// scrolling noticably smoother on most affected pages compared to the default.
const _cacheExtent = 2760.0;

class const RefreshableScrollView({
  required final List<Widget> slivers,
  required final RefreshCallback onRefresh,
  super.key,
  final ScrollController? scrollController,
  final double? toolbarHeight,
  final double? edgeOffset,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: onRefresh,
    displacement: toolbarHeight ?? kToolbarHeight,
    edgeOffset: edgeOffset ?? MediaQuery.paddingOf(context).top,
    child: CustomScrollView(
      controller: scrollController,
      scrollCacheExtent: const ScrollCacheExtent.pixels(_cacheExtent),
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: slivers,
    ),
  );
}
