import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:glider/common/constants/app_animation.dart';

class AnimatedVisibility extends StatelessWidget {
  const new({
    required this.visible,
    required this.child,
    super.key,
    this.padding = EdgeInsets.zero,
    this.alignment = -1,
  }) : _axis = Axis.horizontal,
       _replacement = const SizedBox.shrink();

  const new vertical({
    required this.visible,
    required this.child,
    super.key,
    this.padding = EdgeInsets.zero,
    this.alignment = -1,
  }) : _axis = Axis.vertical,
       _replacement = const SizedBox(width: double.infinity);

  final bool visible;
  final EdgeInsetsGeometry padding;
  final double alignment;
  final Widget child;
  final Axis _axis;
  final Widget _replacement;

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    duration: AppAnimation.standard.duration,
    switchInCurve: AppAnimation.standard.easing,
    switchOutCurve: AppAnimation.standard.easing,
    transitionBuilder: (child, animation) => SizeTransition(
      axis: _axis,
      axisAlignment: alignment,
      sizeFactor: animation,
      child: FadeTransition(opacity: animation, child: child),
    ),
    child: visible
        ? AnimatedPadding(
            padding: padding,
            duration: AppAnimation.standard.duration,
            curve: AppAnimation.standard.easing,
            child: child,
          )
        : _replacement,
  );

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties
      ..add(DiagnosticsProperty<bool>('visible', visible))
      ..add(DiagnosticsProperty<EdgeInsetsGeometry>('padding', padding))
      ..add(DoubleProperty('alignment', alignment));
  }
}
