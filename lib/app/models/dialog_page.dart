import 'package:flutter/material.dart';

class const DialogPage<T>({
  required final WidgetBuilder builder,
  super.key,
  super.name,
  super.arguments,
  super.restorationId,
  final CapturedThemes? themes,
  final Color? barrierColor = Colors.black54,
  final bool barrierDismissible = true,
  final String? barrierLabel,
  final bool useSafeArea = true,
  final Offset? anchorPoint,
  final TraversalEdgeBehavior? traversalEdgeBehavior,
}) extends Page<T> {
  @override
  Route<T> createRoute(BuildContext context) => DialogRoute<T>(
    context: context,
    builder: builder,
    themes: themes,
    barrierColor: barrierColor,
    barrierDismissible: barrierDismissible,
    barrierLabel: barrierLabel,
    useSafeArea: useSafeArea,
    settings: this,
    anchorPoint: anchorPoint,
    traversalEdgeBehavior: traversalEdgeBehavior,
  );
}
