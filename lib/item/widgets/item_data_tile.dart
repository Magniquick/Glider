import 'dart:math';

import 'package:flutter/material.dart';
import 'package:glider/app/models/app_route.dart';
import 'package:glider/common/constants/app_spacing.dart';
import 'package:glider/common/extensions/date_time_extension.dart';
import 'package:glider/common/extensions/uri_extension.dart';
import 'package:glider/common/extensions/widget_list_extension.dart';
import 'package:glider/common/utils/image_luminance.dart';
import 'package:glider/common/widgets/animated_visibility.dart';
import 'package:glider/common/widgets/hacker_news_text.dart';
import 'package:glider/common/widgets/metadata_widget.dart';
import 'package:glider/item/extensions/item_extension.dart';
import 'package:glider/item/models/item_style.dart';
import 'package:glider/item/models/vote_type.dart';
import 'package:glider/item/typedefs/item_typedefs.dart';
import 'package:glider/item/widgets/username_widget.dart';
import 'package:glider/l10n/extensions/app_localizations_extension.dart';
import 'package:glider_domain/glider_domain.dart';
import 'package:go_router/go_router.dart';

const _faviconRequestSize = 64;

class const ItemDataTile(
  final Item item, {
  super.key,
  final ParsedData? parsedText,
  final bool visited = false,
  final VoteType? vote,
  final bool favorited = false,
  final bool flagged = false,
  final bool blocked = false,
  final bool filtered = false,
  final bool failed = false,
  final int? collapsedCount,
  final int storyLines = 2,
  final bool useLargeStoryStyle = true,
  final bool showFavicons = true,
  final bool showMetadata = true,
  final bool showUserAvatars = true,
  final bool useInAppBrowser = false,
  final ItemStyle style = ItemStyle.full,
  final UsernameStyle usernameStyle = UsernameStyle.none,
  final EdgeInsets padding = AppSpacing.defaultTilePadding,
  final ItemCallback? onTap,
  final ItemCallback? onLongPress,
  final VoidCallback? onTapFavorite,
  final VoidCallback? onTapUpvote,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    if (item.type == ItemType.pollopt) {
      return SwitchListTile.adaptive(
        value: vote.upvoted,
        onChanged: (value) => onTap?.call(context, item),
        title: Row(
          spacing: AppSpacing.s,
          children: [
            if (item.text case final text?)
              Expanded(
                child: Hero(
                  tag: 'item_tile_text_${item.id}',
                  child: HackerNewsText(
                    text,
                    parsedData: parsedText,
                    useInAppBrowser: useInAppBrowser,
                  ),
                ),
              )
            else
              const Spacer(),
            Hero(
              tag: 'item_tile_score_${item.id}',
              child: _buildVotedMetadata(context),
            ),
          ],
        ),
        contentPadding: padding.copyWith(top: 0, bottom: 0),
        visualDensity: VisualDensity.compact,
      );
    }

    final bool hasPrimary =
        style.showPrimary &&
        item.dateTime != null &&
        (showMetadata ||
            (item.title != null || item.url != null) && !blocked && !filtered);
    final bool hasSecondary =
        style.showSecondary &&
        (item.text != null || item.url != null) &&
        !blocked &&
        !filtered;

    if (!hasPrimary && !hasSecondary) {
      return const SizedBox.shrink();
    }

    return InkWell(
      onTap: onTap != null ? () => onTap!(context, item) : null,
      onLongPress: onLongPress != null
          ? () => onLongPress!(context, item)
          : null,
      child: Padding(
        padding: padding,
        child: Opacity(
          opacity: visited ? 2 / 3 : 1,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: AppSpacing.m,
            children: [
              if (hasPrimary) _buildPrimary(context),
              if (hasSecondary && collapsedCount == null)
                _buildSecondary(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrimary(BuildContext context) => Column(
    spacing: AppSpacing.s,
    children: [
      if ((item.title != null || item.url != null) && !blocked && !filtered)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpacing.xl,
          children: [
            if (item.title != null)
              Expanded(
                child: Hero(
                  tag: 'item_tile_title_${item.id}',
                  child: _ItemTitle(
                    item,
                    storyLines: storyLines,
                    useLargeStoryStyle: useLargeStoryStyle,
                    style: style,
                  ),
                ),
              )
            else
              const Spacer(),
            if (item.url != null && showFavicons && !_faviconKnownMissing(item))
              AnimatedVisibility(
                visible: style == ItemStyle.overview,
                child: InkWell(
                  onTap: () => item.url!.tryLaunch(
                    context,
                    useInAppBrowser: useInAppBrowser,
                  ),
                  // Explicitly override parent widget's long press.
                  onLongPress: () {},
                  child: _ItemFavicon(
                    item,
                    storyLines: storyLines,
                    useLargeStoryStyle: useLargeStoryStyle,
                  ),
                ),
              ),
          ],
        ),
      if (showMetadata) _buildMetadata(context),
    ],
  );

  Widget _buildMetadata(BuildContext context) => Row(
    children: [
      Hero(
        tag: 'item_tile_collapsed_${item.id}',
        child: AnimatedVisibility(
          visible: collapsedCount != null,
          padding: MetadataWidget.horizontalPadding,
          child: MetadataWidget(
            icon: Icons.add_circle_outline_outlined,
            label: collapsedCount != null && collapsedCount! > 0
                ? Text(collapsedCount.toString())
                : null,
          ),
        ),
      ),
      Hero(
        tag: 'item_tile_favorited_${item.id}',
        child: onTapFavorite != null
            ? _MetadataActionButton(
                padding: MetadataWidget.horizontalPadding,
                onTap: onTapFavorite,
                child: _buildFavoritedMetadata(context),
              )
            : AnimatedVisibility(
                visible: favorited,
                padding: MetadataWidget.horizontalPadding,
                child: _buildFavoritedMetadata(context),
              ),
      ),
      if (item.type != ItemType.job)
        Hero(
          tag: 'item_tile_score_${item.id}',
          child: onTapUpvote != null
              ? _MetadataActionButton(
                  padding: MetadataWidget.horizontalPadding,
                  onTap: onTapUpvote,
                  child: _buildVotedMetadata(context),
                )
              : AnimatedVisibility(
                  visible: item.score != null || vote != null,
                  padding: MetadataWidget.horizontalPadding,
                  child: _buildVotedMetadata(context),
                ),
        ),
      Hero(
        tag: 'item_tile_descendants_${item.id}',
        child: AnimatedVisibility(
          visible: item.descendantCount != null,
          padding: MetadataWidget.horizontalPadding,
          child: MetadataWidget(
            icon: Icons.mode_comment_outlined,
            label: item.descendantCount != null
                ? Text(item.descendantCount!.toString())
                : null,
          ),
        ),
      ),
      Hero(
        tag: 'item_tile_dead_${item.id}',
        child: AnimatedVisibility(
          visible: item.isDead || flagged,
          padding: MetadataWidget.horizontalPadding,
          child: MetadataWidget(
            icon: Icons.flag_outlined,
            color: flagged ? Theme.of(context).colorScheme.tertiary : null,
          ),
        ),
      ),
      Hero(
        tag: 'item_tile_blocked_${item.id}',
        child: AnimatedVisibility(
          visible: blocked,
          padding: MetadataWidget.horizontalPadding,
          child: MetadataWidget(
            icon: Icons.block_outlined,
            label: Text(context.l10n.blocked),
          ),
        ),
      ),
      Hero(
        tag: 'item_tile_filtered_${item.id}',
        child: AnimatedVisibility(
          visible: filtered,
          padding: MetadataWidget.horizontalPadding,
          child: MetadataWidget(
            icon: Icons.filter_alt_outlined,
            label: Text(context.l10n.filtered),
          ),
        ),
      ),
      ...[
        if (item.isDeleted)
          Hero(
            tag: 'item_tile_deleted_${item.id}',
            child: MetadataWidget(
              icon: Icons.delete_outlined,
              label: Text(context.l10n.deleted),
            ),
          ),
        if (item.username case final username?) ...[
          Expanded(
            child: Hero(
              tag: 'item_tile_username_${item.id}',
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: UsernameWidget(
                  username: username,
                  showAvatar: showUserAvatars,
                  style: usernameStyle,
                  onTap: () => context.push(
                    AppRoute.user.location(parameters: {'id': username}),
                  ),
                ),
              ),
            ),
          ),
          if (item.hasUsernameTag)
            Hero(
              tag: 'item_tile_username_tag_${item.id}',
              child: Badge(
                backgroundColor: Theme.of(context)
                    .colorScheme
                    .tertiaryContainer,
                textColor: Theme.of(context).colorScheme.onTertiaryContainer,
                label: Text(item.usernameTag(context)!),
              ),
            ),
        ] else
          const Spacer(),
        if (failed)
          Hero(
            tag: 'item_tile_failed_${item.id}',
            child: const MetadataWidget(icon: Icons.error_outline_outlined),
          ),
        if (item.dateTime case final dateTime?)
          Hero(
            tag: 'item_tile_date_${item.id}',
            child: MetadataWidget(
              label: Tooltip(
                message: dateTime.toString(),
                child: Text(dateTime.relativeTime(context)),
              ),
            ),
          ),
      ].spaced(width: AppSpacing.m),
    ],
  );

  Widget _buildFavoritedMetadata(BuildContext context) => MetadataWidget(
    icon: Icons.favorite_outline_outlined,
    color: favorited ? Theme.of(context).colorScheme.tertiary : null,
  );

  Widget _buildVotedMetadata(BuildContext context) => MetadataWidget(
    icon: vote.downvoted
        ? Icons.arrow_downward_outlined
        : Icons.arrow_upward_outlined,
    label: item.score != null ? Text(item.score!.toString()) : null,
    color: vote.downvoted
        ? Theme.of(context).colorScheme.secondary
        : vote.upvoted
        ? Theme.of(context).colorScheme.tertiary
        : null,
  );

  Widget _buildSecondary(BuildContext context) => Column(
    spacing: AppSpacing.m,
    children: [
      if (item.text case final text?)
        Hero(
          tag: 'item_tile_text_${item.id}',
          child: HackerNewsText(
            text,
            parsedData: parsedText,
            useInAppBrowser: useInAppBrowser,
          ),
        ),
      if (item.url case final url?)
        Card.outlined(
          child: InkWell(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            onTap: () =>
                url.tryLaunch(context, useInAppBrowser: useInAppBrowser),
            // Explicitly override parent widget's long press.
            onLongPress: () {},
            child: Padding(
              padding: AppSpacing.defaultTilePadding,
              child: Row(
                spacing: AppSpacing.l,
                children: [
                  if (showFavicons && !_faviconKnownMissing(item))
                    Hero(
                      tag: 'item_tile_favicon_${item.id}',
                      child: Material(
                        type: MaterialType.transparency,
                        child: _ItemFavicon(
                          item,
                          storyLines: 1,
                          useLargeStoryStyle: false,
                        ),
                      ),
                    )
                  else
                    const MetadataWidget(icon: Icons.link_outlined),
                  Expanded(
                    child: Hero(
                      tag: 'item_tile_url_${item.id}',
                      child: Text(
                        item.url!.toString(),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    ],
  );
}

class const _ItemTitle(
  final Item item, {
  required final int storyLines,
  required final bool useLargeStoryStyle,
  required final ItemStyle style,
}) extends StatelessWidget {
  int get maxLines =>
      storyLines >= 0 ? storyLines : (useLargeStoryStyle ? 3 : 2);

  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      style: useLargeStoryStyle
          ? Theme.of(context).textTheme.titleMedium
          : Theme.of(context).textTheme.titleSmall,
      children: [
        if (item.hasPrefix) ...[
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Badge(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              textColor: Theme.of(context).colorScheme.onSecondaryContainer,
              label: Text(item.prefix!),
            ),
          ),
          const TextSpan(text: ' '),
        ],
        TextSpan(text: item.filteredTitle),
        if (item.hasSuffix) ...[
          const TextSpan(text: ' '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Badge(
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              textColor: Theme.of(context).colorScheme.onPrimaryContainer,
              label: Text(item.suffix!),
            ),
          ),
        ],
        if (item.hasOriginalDate) ...[
          const TextSpan(text: ' '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Badge(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              textColor: Theme.of(context).colorScheme.onSecondaryContainer,
              label: Text(item.originalDate!),
            ),
          ),
        ],
        if (item.hasYcBatch) ...[
          const TextSpan(text: ' '),
          WidgetSpan(
            alignment: PlaceholderAlignment.baseline,
            baseline: TextBaseline.alphabetic,
            child: Badge(
              backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
              textColor: Theme.of(context).colorScheme.onTertiaryContainer,
              label: Text(item.ycBatch!),
            ),
          ),
        ],
        if (style.showUrlHost && useLargeStoryStyle)
          if (item.url case final url?) ...[
            const TextSpan(text: ' '),
            TextSpan(text: '(', style: Theme.of(context).textTheme.titleSmall),
            TextSpan(
              text: url.host,
              style: Theme.of(context).textTheme.titleSmall
                  ?.copyWith(color: Theme.of(context).colorScheme.secondary),
            ),
            TextSpan(text: ')', style: Theme.of(context).textTheme.titleSmall),
          ],
        // Append zero-width space of title style to enforce height.
        const TextSpan(text: '\u200b'),
        if (storyLines >= 0)
          // `minLines` does not exist, so append newlines as a workaround.
          TextSpan(text: '\n' * (maxLines - 1)),
      ],
    ),
    maxLines: maxLines,
    overflow: TextOverflow.ellipsis,
  );
}

/// Mean opaque luminance per favicon host, so an icon is analysed once for the
/// whole feed rather than once per row.
final _faviconLuminance = <String, double?>{};

/// Which of a host's candidate URLs actually served an icon, or null once every
/// candidate has failed. Cached per host so a miss is probed once per session
/// rather than once per row, and so a row that will never get an icon can drop
/// the slot entirely instead of reserving space for nothing.
final _faviconResolution = <String, String?>{};

/// Normalised bounds of each host icon's visible pixels, so a glyph padded out
/// with transparency can be trimmed back to fill its tile.
final _faviconBounds = <String, Rect?>{};

/// Whether [item]'s host is already known to have no icon at all.
bool _faviconKnownMissing(Item item) {
  final String? host = item.url?.host;
  return host != null &&
      _faviconResolution.containsKey(host) &&
      _faviconResolution[host] == null;
}

class _ItemFavicon extends StatefulWidget {
  const _ItemFavicon(
    this.item, {
    required this.storyLines,
    required this.useLargeStoryStyle,
  });

  final Item item;
  final int storyLines;
  final bool useLargeStoryStyle;

  @override
  State<_ItemFavicon> createState() => _ItemFaviconState();
}

class _ItemFaviconState extends State<_ItemFavicon> {
  // WCAG's minimum for non-text content. Chromium scopes this same 3.0 to
  // glyphs, reserving 4.5 for body text.
  static const _minimumContrast = 3.0;
  static const _inset = 2.0;

  // Icons whose visible pixels already span this much of their canvas are left
  // alone. Below it, the padding is the icon author's, not a design choice.
  static const _maximumUntrimmedExtent = 0.9;

  ImageStreamListener? _listener;
  ImageStream? _stream;

  int get _faviconSize => min(
    widget.useLargeStoryStyle
        ? (widget.storyLines >= 0 ? widget.storyLines : 2) * 24
        : 20,
    _faviconRequestSize,
  );

  String? get _host => widget.item.url?.host;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resolveIfNeeded();
  }

  @override
  void dispose() {
    _detach();
    super.dispose();
  }

  void _detach() {
    if (_listener case final listener?) _stream?.removeListener(listener);
    _listener = null;
    _stream = null;
  }

  /// Walks the candidate URLs until one loads, then measures it.
  ///
  /// Both results are cached per host: the winning URL so sibling rows skip
  /// straight to it, and the icon's mean luminance so the plate can be chosen
  /// per icon rather than applied to all of them.
  void _resolveIfNeeded() {
    final host = _host;
    if (host == null || _faviconResolution.containsKey(host)) return;
    _tryCandidate(host, widget.item.faviconUrls, 0);
  }

  void _tryCandidate(String host, List<String> candidates, int index) {
    if (index >= candidates.length) {
      _faviconResolution[host] = null;
      _faviconLuminance[host] = null;
      _faviconBounds[host] = null;
      if (mounted) setState(() {});
      return;
    }

    final listener = ImageStreamListener(
      (info, _) async {
        final analysis = await analyseFavicon(info.image);
        info.image.dispose();
        _faviconResolution[host] = candidates[index];
        _faviconLuminance[host] = analysis.luminance;
        _faviconBounds[host] = analysis.opaqueBounds;
        if (mounted) setState(() {});
      },
      onError: (_, __) {
        _detach();
        if (mounted) _tryCandidate(host, candidates, index + 1);
      },
    );

    _detach();
    _listener = listener;
    _stream = NetworkImage(
      candidates[index],
    ).resolve(createLocalImageConfiguration(context))..addListener(listener);
  }

  /// The plate to draw behind the icon.
  ///
  /// Most icons get the subtle themed tile. One measured to contrast poorly
  /// against it -- a dark mark on a dark surface, or a light one on a light
  /// surface -- gets [ColorScheme.inverseSurface] instead, which by definition
  /// runs opposite the current theme. The icon itself is never recoloured:
  /// that would be rewriting someone else's brand mark.
  Color _plate(ColorScheme colorScheme) {
    final tile = colorScheme.surfaceContainerHighest;
    final luminance = _host != null ? _faviconLuminance[_host] : null;
    if (luminance == null) return tile;

    final tileLuminance = relativeLuminance(
      (tile.r * 255).round(),
      (tile.g * 255).round(),
      (tile.b * 255).round(),
    );
    return contrastRatio(luminance, tileLuminance) < _minimumContrast
        ? colorScheme.inverseSurface
        : tile;
  }

  /// The region to blow up to fill the tile, or null to draw the icon as-is.
  ///
  /// Only worth doing when the padding is wide enough to see: trimming a
  /// hairline would just resample the icon for nothing.
  Rect? _trim(String? host) {
    final bounds = host != null ? _faviconBounds[host] : null;
    if (bounds == null) return null;
    return max(bounds.width, bounds.height) <= _maximumUntrimmedExtent
        ? bounds
        : null;
  }

  @override
  Widget build(BuildContext context) {
    final String? host = _host;
    final String? resolved = host != null ? _faviconResolution[host] : null;

    // No icon anywhere for this host: take up no room at all, so the title
    // gets the width back. A zero-size image inside the plate would leave the
    // inset padding behind as a stray dot.
    if (resolved == null) {
      return SizedBox.square(
        dimension: host != null && _faviconResolution.containsKey(host)
            ? 0
            : _faviconSize.toDouble(),
      );
    }

    final double imageSize = _faviconSize - _inset * 2;
    final Rect? bounds = _trim(host);
    final double magnification = bounds == null
        ? 1
        : 1 / max(bounds.width, bounds.height);
    // Decode at the resolution the screen will actually paint rather than the
    // logical one, and at the magnified size when only part of the image ends
    // up on screen. ResizeImage clamps to the source's own resolution instead
    // of upscaling, so asking for more detail than exists costs nothing.
    final int decodeSize =
        (imageSize * MediaQuery.devicePixelRatioOf(context) * magnification)
            .round();

    Widget icon = Image(
      image: ResizeImage(
        NetworkImage(resolved),
        width: decodeSize,
        height: decodeSize,
        policy: ResizeImagePolicy.fit,
      ),
      width: imageSize,
      height: imageSize,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
    );

    if (bounds != null) {
      // Scale the visible pixels up to fill the tile and recentre them. Done
      // with a transform rather than a crop so the icon keeps its aspect
      // ratio; ClipRect stops any faint fringe outside the bounds spilling out.
      icon = ClipRect(
        child: Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..scale(magnification)
            ..translate(
              (0.5 - bounds.center.dx) * imageSize,
              (0.5 - bounds.center.dy) * imageSize,
            ),
          child: icon,
        ),
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: _plate(Theme.of(context).colorScheme),
        borderRadius: const BorderRadius.all(Radius.circular(4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(_inset),
        // A plain Image, not Ink.image: Ink paints onto the ancestor Material's
        // canvas, which sits *behind* the plate above, so the plate would cover
        // the icon entirely.
        child: icon,
      ),
    );
  }
}

class const _MetadataActionButton({
  required final Widget child,
  final EdgeInsetsGeometry padding = EdgeInsets.zero,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Padding(
    padding: padding,
    child: ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.m),
        minimumSize: const Size.square(40),
        visualDensity: const VisualDensity(
          horizontal: VisualDensity.minimumDensity,
          vertical: VisualDensity.minimumDensity,
        ),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      child: child,
    ),
  );
}
