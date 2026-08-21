// Vendored from sliver_tools 0.2.12 (MIT, Copyright (c) 2020 Pieter van Loon),
// which has had no release since July 2023 and was the package's only remaining
// use here -- everything else it provided is now in the framework as
// SliverMainAxisGroup. There is no framework equivalent for this one.
//
// See third_party/sliver_tools/LICENSE for the full licence text.

import 'dart:math';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

/// [SliverAnimatedPaintExtent] allows for smoothly animating maxPaintExtent changes
class const SliverAnimatedPaintExtent({
  Key? key,
  required this.duration,
  required this.child,
  this.curve = Curves.linear,
}) extends StatefulWidget {
  /// The duration that the animation will take
  final Duration duration;

  /// The curve for the animation
  final Curve curve;

  /// The child widget that will be rendered
  final Widget child;

  this : super(key: key);

  @override
  State<SliverAnimatedPaintExtent> createState() =>
      _SliverAnimatedPaintExtentState();
}

class _SliverAnimatedPaintExtentState()
    extends State<SliverAnimatedPaintExtent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    _controller = AnimationController(vsync: this);
    super.initState();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _SliverAnimatedPaintExtent(
      controller: _controller,
      duration: widget.duration,
      curve: widget.curve,
      child: widget.child,
    );
  }
}

class const _SliverAnimatedPaintExtent({
  Key? key,
  required this.controller,
  required this.duration,
  required this.curve,
  required Widget child,
}) extends SingleChildRenderObjectWidget {
  /// The controller in charge of the animation
  final AnimationController controller;

  /// The duration that the animation will take
  final Duration duration;

  /// The curve for the animation
  final Curve curve;

  this : super(key: key, child: child);

  @override
  RenderSliverAnimatedPaintExtent createRenderObject(BuildContext context) {
    return RenderSliverAnimatedPaintExtent()
      ..duration = duration
      ..controller = controller
      ..curve = curve;
  }

  @override
  void updateRenderObject(
    BuildContext context,
    covariant RenderSliverAnimatedPaintExtent renderObject,
  ) {
    renderObject
      ..duration = duration
      ..controller = controller
      ..curve = curve;
  }
}

/// The RenderObject that handles the animation for [SliverAnimatedPaintExtent]
class RenderSliverAnimatedPaintExtent() extends RenderProxySliver {
  /// The duration that the animation will take
  late Duration duration;

  /// The curve for the animation
  late Curve curve;

  AnimationController? _controller;

  /// The controller in charge of the animation
  AnimationController get controller => _controller!;
  set controller(AnimationController value) {
    if (value != _controller) {
      _controller?.removeListener(_update);
      _controller = value;
      value.addListener(_update);
    }
  }

  void _update() {
    if (_lastValue == controller.value) return;
    markNeedsLayout();
  }

  Tween<double>? _paintExtentTween;
  Tween<double>? _scrollExtentTween;
  double _lastValue = 0;

  void _restartAnimation() {
    _paintExtentTween!.begin = geometry!.maxPaintExtent;
    _paintExtentTween!.end = child!.geometry!.maxPaintExtent;
    _scrollExtentTween!.begin = geometry!.scrollExtent;
    _scrollExtentTween!.end = child!.geometry!.scrollExtent;
    _lastValue = 0;
    controller.value = 0;
    controller.animateTo(1, duration: duration, curve: curve);
  }

  @override
  void performLayout() {
    _lastValue = controller.value;
    child!.layout(constraints, parentUsesSize: true);
    assert(
      child!.geometry != null,
      'Sliver child $child did not set its geometry',
    );
    final extentTween = _paintExtentTween ??= Tween<double>(
      begin: child!.geometry!.maxPaintExtent,
      end: child!.geometry!.maxPaintExtent,
    );
    final scrollExtentTween = _scrollExtentTween ??= Tween<double>(
      begin: child!.geometry!.scrollExtent,
      end: child!.geometry!.scrollExtent,
    );
    if (child!.geometry!.maxPaintExtent != extentTween.end ||
        child!.geometry!.scrollExtent != scrollExtentTween.end) {
      _restartAnimation();
    }
    final maxPaintExtent = extentTween.evaluate(controller);
    final scrollExtent = scrollExtentTween.evaluate(controller);
    double paintExtent;
    double layoutExtent;
    if (extentTween.begin! > extentTween.end!) {
      paintExtent = max(
        0.0,
        max(
          child!.geometry!.paintExtent,
          maxPaintExtent - constraints.scrollOffset,
        ),
      );
      paintExtent = min(
        paintExtent,
        constraints.remainingPaintExtent - child!.geometry!.paintOrigin,
      );
      layoutExtent = max(
        child!.geometry!.layoutExtent,
        child!.geometry!.paintOrigin + paintExtent,
      );
    } else {
      paintExtent = max(
        0.0,
        min(
          child!.geometry!.paintExtent,
          maxPaintExtent - constraints.scrollOffset,
        ),
      );
      layoutExtent = min(
        child!.geometry!.layoutExtent,
        child!.geometry!.paintOrigin + paintExtent,
      );
    }
    final hitTestExtent = min(
      child!.geometry!.hitTestExtent,
      child!.geometry!.paintOrigin + paintExtent,
    );
    geometry = SliverGeometry(
      paintOrigin: child!.geometry!.paintOrigin,
      scrollExtent: scrollExtent,
      paintExtent: paintExtent,
      layoutExtent: layoutExtent,
      maxPaintExtent: maxPaintExtent,
      cacheExtent: child!.geometry!.cacheExtent,
      maxScrollObstructionExtent: child!.geometry!.maxScrollObstructionExtent,
      visible: child!.geometry!.visible,
      hitTestExtent: hitTestExtent,
      hasVisualOverflow: child!.geometry!.hasVisualOverflow,
      scrollOffsetCorrection: child!.geometry!.scrollOffsetCorrection,
    );
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (child == null) {
      layer = null;
      return;
    }
    Offset bottomRight;
    switch (constraints.axis) {
      case Axis.horizontal:
        bottomRight = Offset(
          geometry!.paintExtent,
          constraints.crossAxisExtent,
        );
        break;
      case Axis.vertical:
        bottomRight = Offset(
          constraints.crossAxisExtent,
          geometry!.paintExtent,
        );
        break;
    }
    if (controller.isAnimating) {
      layer = context.pushClipRect(
        needsCompositing,
        offset,
        Rect.fromPoints(Offset.zero, bottomRight),
        (context, offset) => super.paint(context, offset),
        oldLayer: layer as ClipRectLayer?,
      );
    } else {
      layer = null;
      super.paint(context, offset);
    }
  }
}
