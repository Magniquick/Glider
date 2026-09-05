import 'dart:convert';
import 'dart:developer';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:glider/item_tree/cubit/item_tree_cubit.dart';
import 'package:glider_domain/glider_domain.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

/// Comment trees currently on screen, so profiling can drive them.
///
/// Only ever populated outside release builds. Keyed by item id, which is
/// unique per open thread.
final Map<int, ItemTreeCubit> _liveTrees = {};

/// How to bring a row of each open tree on screen.
///
/// Collapsing a row that was never laid out is a different and much cheaper
/// operation than collapsing one the reader is looking at, so a measurement
/// that cannot scroll first measures the wrong thing.
final Map<int, Future<void> Function(int index, {required bool jump})>
_treeScrollers = {};

/// Lets the controls below scroll [itemId]'s tree to a given row.
void registerItemTreeScroller(
  int itemId,
  Future<void> Function(int index, {required bool jump}) scrollToIndex,
) {
  if (kReleaseMode) return;
  _treeScrollers[itemId] = scrollToIndex;
}

/// Frame timings recorded since the last reset, newest last.
///
/// Timeline spans have to be paired up by hand and disagree run to run;
/// [FrameTiming] is what the engine itself measured a frame to have taken,
/// build and raster together, which is the only number that answers "did this
/// drop frames".
final List<FrameTiming> _frameTimings = [];
bool _recordingFrames = false;

void _onFrameTimings(List<FrameTiming> timings) {
  if (_recordingFrames) _frameTimings.addAll(timings);
}

/// Makes [cubit] reachable from the VM service controls below.
void registerItemTree(ItemTreeCubit cubit) {
  if (kReleaseMode) return;
  _liveTrees[cubit.itemId] = cubit;
}

/// Drops [cubit] once its screen is gone.
void unregisterItemTree(ItemTreeCubit cubit) {
  if (kReleaseMode) return;
  _liveTrees.remove(cubit.itemId);
  _treeScrollers.remove(cubit.itemId);
}

/// Exposes the app's state and a few actions over the VM service.
///
/// Profiling a gesture otherwise means someone tapping the screen at the right
/// moment, which is slow to iterate on and impossible to repeat exactly. These
/// let a script arm counters, perform the action and read the result in one
/// pass. Everything here is compiled out of release builds.
///
/// ```sh
/// # every root comment, biggest subtree first
/// ext.glider.tree
/// # collapse one, by item id or by rank among the roots
/// ext.glider.collapse?id=123    ext.glider.collapse?biggest=1
/// ```
void registerDevControls() {
  if (kReleaseMode) return;

  registerExtension('ext.glider.env', (method, parameters) async {
    // Whether an accessibility client asked for a semantics tree. On Linux any
    // running at-spi bus is enough, so a desktop profile can show costs that a
    // phone without a screen reader never pays.
    return _ok({
      'semanticsEnabled': SemanticsBinding.instance.semanticsEnabled,
      'liveTrees': _liveTrees.keys.toList(growable: false),
      'width':
          PlatformDispatcher.instance.views.first.physicalSize.width /
          PlatformDispatcher.instance.views.first.devicePixelRatio,
      'height':
          PlatformDispatcher.instance.views.first.physicalSize.height /
          PlatformDispatcher.instance.views.first.devicePixelRatio,
    });
  });

  SchedulerBinding.instance.addTimingsCallback(_onFrameTimings);

  registerExtension('ext.glider.frames', (method, parameters) async {
    if (parameters['reset'] == 'true') {
      _frameTimings.clear();
      _recordingFrames = true;
    }
    return _ok({
      'frames': [
        for (final timing in _frameTimings)
          {
            'build': timing.buildDuration.inMicroseconds,
            'raster': timing.rasterDuration.inMicroseconds,
            'total': timing.totalSpan.inMicroseconds,
          },
      ],
    });
  });

  registerExtension('ext.glider.tap', (method, parameters) async {
    final x = double.tryParse(parameters['x'] ?? '');
    final y = double.tryParse(parameters['y'] ?? '');
    if (x == null || y == null) return _error('tap needs x and y');

    // Calling the cubit directly skips everything the gesture does around it,
    // and the row's own handler also scrolls itself back into view. Only a
    // real pointer event measures what a reader's tap costs.
    GestureBinding.instance
      ..handlePointerEvent(PointerDownEvent(position: Offset(x, y)))
      ..handlePointerEvent(PointerUpEvent(position: Offset(x, y)));
    return _ok({'x': x, 'y': y});
  });

  registerExtension('ext.glider.budget', (method, parameters) async {
    // How long SuperSliverList may spend each layout laying out extra items
    // to refine its extent estimates. It defaults to 3 ms and is a static, so
    // a sweep needs no rebuild.
    if (int.tryParse(parameters['micros'] ?? '') case final value?) {
      SuperSliverList.layoutBudget = _FixedLayoutBudget(
        Duration(microseconds: value),
      );
    }
    return _ok({'set': parameters['micros']});
  });

  registerExtension('ext.glider.tree', (method, parameters) async {
    final entry = _resolveTree(parameters);
    if (entry == null) return _error('no comment tree is on screen');

    final data = entry.value.state.data ?? const <ItemDescendant>[];
    final roots = _rootsBySize(data);
    return _ok({
      'itemId': entry.key,
      'rows': data.length,
      'collapsed': entry.value.state.collapsedIds.toList(growable: false),
      'roots': [
        for (final root in roots.take(20))
          {
            'id': root.$1.id,
            'index': data.indexOf(root.$1),
            'descendants': root.$2,
          },
      ],
    });
  });

  registerExtension('ext.glider.scroll', (method, parameters) async {
    final entry = _resolveTree(parameters);
    if (entry == null) return _error('no comment tree is on screen');
    final scroller = _treeScrollers[entry.key];
    if (scroller == null) return _error('that tree has no scroller');

    final data = entry.value.state.viewableData ?? const <ItemDescendant>[];
    final int? index = switch (parameters) {
      {'index': final String value} => int.tryParse(value),
      {'id': final String value} => data.indexWhere(
        (descendant) => descendant.id == int.tryParse(value),
      ),
      _ => null,
    };
    if (index == null || index < 0) return _error('no such row to scroll to');

    // Arriving by animation passes through every row in between, which is a
    // different amount of accumulated state than landing there directly.
    await scroller(index, jump: parameters['jump'] == 'true');
    return _ok({'index': index});
  });

  registerExtension('ext.glider.collapse', (method, parameters) async {
    final entry = _resolveTree(parameters);
    if (entry == null) return _error('no comment tree is on screen');

    final data = entry.value.state.data ?? const <ItemDescendant>[];
    final int? id = switch (parameters) {
      {'id': final String value} => int.tryParse(value),
      {'biggest': final String rank} => _rootsBySize(
        data,
      ).elementAtOrNull((int.tryParse(rank) ?? 1) - 1)?.$1.id,
      _ => _rootsBySize(data).firstOrNull?.$1.id,
    };
    if (id == null) return _error('no such comment to collapse');

    // Explicit rather than a toggle: a profiling run has to know which
    // direction it measured, and repeat runs must start from the same place.
    final want = parameters['collapsed'] != 'false';
    final bool isCollapsed = entry.value.state.collapsedIds.contains(id);
    final changed = isCollapsed != want;
    if (changed) entry.value.toggleCollapsed(id);

    return _ok({
      'id': id,
      'changed': changed,
      'collapsed': entry.value.state.collapsedIds.contains(id),
      'visibleRows': entry.value.state.viewableData?.length,
    });
  });
}

/// The tree named by `itemId`, or the only one on screen.
MapEntry<int, ItemTreeCubit>? _resolveTree(Map<String, String> parameters) {
  if (parameters['itemId'] case final raw?) {
    final id = int.tryParse(raw);
    final cubit = id != null ? _liveTrees[id] : null;
    return cubit != null ? MapEntry(id!, cubit) : null;
  }
  return _liveTrees.entries.lastOrNull;
}

/// Root comments paired with their subtree size, biggest first.
List<(ItemDescendant, int)> _rootsBySize(List<ItemDescendant> data) {
  final counts = <int, int>{};
  for (final descendant in data) {
    for (final ancestor in descendant.ancestorIds) {
      counts[ancestor] = (counts[ancestor] ?? 0) + 1;
    }
  }
  return [
    for (final descendant in data)
      if (descendant.ancestorIds.length == 1)
        (descendant, counts[descendant.id] ?? 0),
  ]..sort((a, b) => b.$2.compareTo(a.$2));
}

ServiceExtensionResponse _ok(Map<String, Object?> body) =>
    ServiceExtensionResponse.result(jsonEncode(body));

ServiceExtensionResponse _error(String message) =>
    ServiceExtensionResponse.error(
      ServiceExtensionResponse.extensionError,
      jsonEncode({'error': message}),
    );

/// A layout budget of a fixed wall-clock size, for sweeping the default.
class _FixedLayoutBudget(final Duration _budget)
    extends SuperSliverListLayoutBudget {
  final Stopwatch _stopwatch = Stopwatch();

  @override
  void beginLayout() => _stopwatch.start();

  @override
  void endLayout() => _stopwatch.stop();

  @override
  void reset() => _stopwatch.reset();

  @override
  bool shouldLayoutNextItem() => _stopwatch.elapsed < _budget;
}
