import 'package:flutter/material.dart';

class const LoadingBlock({super.key, this.width, this.height})
    extends StatelessWidget {
  final double? width;
  final double? height;

  static const double opacity = 0.25;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(4)),
        color: Theme.of(context).colorScheme.outline.withValues(alpha: opacity),
      ),
    );
  }
}
