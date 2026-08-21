import 'package:flutter/material.dart';
import 'package:glider/common/constants/app_spacing.dart';
import 'package:glider/common/extensions/widget_list_extension.dart';

const _iconSize = 16.0;

class const MetadataWidget({
  super.key,
  final IconData? icon,
  final Widget? label,
  final Color? color,
}) extends StatelessWidget {
  static const horizontalPadding = EdgeInsetsDirectional.only(
    end: AppSpacing.m,
  );

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    spacing: AppSpacing.s,
    children: [
      if (icon != null) Icon(icon, size: _iconSize, color: color),
      if (label != null)
        Flexible(
          child: DefaultTextStyle(
            style: Theme.of(context).textTheme.bodySmall!
                .copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            child: label!,
          ),
        ),
    ],
  );
}
