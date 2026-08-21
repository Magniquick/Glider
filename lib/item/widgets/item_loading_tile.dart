import 'package:flutter/material.dart';
import 'package:glider/common/constants/app_spacing.dart';
import 'package:glider/item/models/item_style.dart';
import 'package:glider/item/widgets/item_data_tile.dart';
import 'package:glider_domain/glider_domain.dart';
import 'package:skeletonizer/skeletonizer.dart';

/// Placeholder shown while an item loads.
///
/// Rather than hand-mirroring [ItemDataTile]'s layout -- which had to be kept
/// in step with it by hand -- this renders the real tile with stand-in content
/// and lets Skeletonizer turn it into bones. Any change to [ItemDataTile] is
/// therefore reflected here automatically.
class const ItemLoadingTile({
  required final ItemType type,
  super.key,
  final int? collapsedCount,
  final int storyLines = 2,
  final bool useLargeStoryStyle = true,
  final bool showMetadata = true,
  final ItemStyle style = ItemStyle.full,
  final EdgeInsetsGeometry padding = AppSpacing.defaultTilePadding,
}) extends StatelessWidget {
  /// Stand-in content, sized so the bones match a typical item's proportions.
  Item get _placeholder => Item(
    id: 0,
    type: type,
    username: 'username',
    dateTime: DateTime.fromMillisecondsSinceEpoch(0),
    title: type == ItemType.comment
        ? null
        : 'A story title that runs to about the length of a real one',
    text: type == ItemType.comment
        ? 'A comment body long enough to occupy the couple of lines that a '
              'typical Hacker News reply takes up on screen.'
        : null,
    url: type == ItemType.comment ? null : Uri.https('example.com'),
    score: 100,
    descendantCount: 10,
  );

  @override
  Widget build(BuildContext context) => Skeletonizer(
    // Pointer events are ignored while skeletonized, so the stand-in tile
    // cannot be tapped through to a nonexistent item.
    child: ItemDataTile(
      _placeholder,
      collapsedCount: collapsedCount,
      storyLines: storyLines,
      useLargeStoryStyle: useLargeStoryStyle,
      showMetadata: showMetadata,
      // Favicons would try to hit the network for the placeholder URL.
      showFavicons: false,
      showUserAvatars: false,
      style: style,
      padding: padding is EdgeInsets
          ? padding as EdgeInsets
          : AppSpacing.defaultTilePadding,
    ),
  );
}
