import 'package:flutter/material.dart';

class const LoadingBlock({super.key, final double? width, final double? height})
    extends StatelessWidget {
  static const double opacity = 0.25;

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    decoration: BoxDecoration(
      borderRadius: const BorderRadius.all(Radius.circular(4)),
      color: Theme.of(context).colorScheme.outline.withValues(alpha: opacity),
    ),
  );
}
