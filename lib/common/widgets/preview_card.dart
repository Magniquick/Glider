import 'package:flutter/material.dart';
import 'package:glider/common/constants/app_animation.dart';
import 'package:glider/common/constants/app_spacing.dart';
import 'package:glider/common/extensions/widget_list_extension.dart';
import 'package:glider/common/widgets/metadata_widget.dart';
import 'package:glider/l10n/extensions/app_localizations_extension.dart';

class const PreviewCard({required final Widget child, super.key})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Card.outlined(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: AppSpacing.defaultTilePadding.copyWith(bottom: 0),
          child: Row(
            spacing: AppSpacing.l,
            children: [
              const MetadataWidget(icon: Icons.visibility_outlined),
              Text(
                context.l10n.preview,
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
          ),
        ),
        AnimatedSize(
          alignment: Alignment.topCenter,
          duration: AppAnimation.emphasized.duration,
          curve: AppAnimation.emphasized.easing,
          child: child,
        ),
      ],
    ),
  );
}
