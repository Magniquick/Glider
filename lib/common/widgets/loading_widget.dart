import 'package:flutter/material.dart';
import 'package:glider/common/constants/app_spacing.dart';

class const LoadingWidget({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => const Padding(
    padding: AppSpacing.defaultTilePadding,
    child: Center(child: CircularProgressIndicator.adaptive()),
  );
}
