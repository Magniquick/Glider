import 'package:flutter/material.dart';
import 'package:glider/common/constants/app_spacing.dart';
import 'package:glider/user/models/user_style.dart';
import 'package:glider/user/widgets/user_data_tile.dart';
import 'package:glider_domain/glider_domain.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Placeholder shown while a user profile loads.
///
/// Renders [UserDataTile] with stand-in content and lets Skeletonizer turn it
/// into bones, so it cannot drift out of step with the real tile.
class const UserLoadingTile({
  super.key,
  final UserStyle style = UserStyle.full,
  final EdgeInsets padding = AppSpacing.defaultTilePadding,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Skeletonizer(
    child: UserDataTile(
      User(
        username: 'username',
        createdDateTime: DateTime.fromMillisecondsSinceEpoch(0),
        karma: 1000,
        about:
            'A profile description of roughly the length people tend to '
            'write, running to about two lines.',
      ),
      useInAppBrowser: false,
      style: style,
      padding: padding,
    ),
  );
}
