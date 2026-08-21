import 'package:flutter/material.dart';
import 'package:glider/app/extensions/text_scaler_extension.dart';
import 'package:glider/common/constants/app_spacing.dart';
import 'package:glider/item/widgets/avatar_widget.dart';

// The key is derived from a constructor parameter, so this constructor can
// never be const. The lint does not see the non-const super initialiser in
// primary-constructor syntax (false positive on Dart 3.13).
// ignore: prefer_const_constructors_in_immutables
class UsernameWidget({
  required final String username,
  final bool showAvatar = true,
  final UsernameStyle style = UsernameStyle.none,
  final VoidCallback? onTap,
}) extends StatelessWidget {
  this : super(key: ValueKey(username));

  @override
  Widget build(BuildContext context) {
    void onPressed() => onTap?.call();
    void onLongPress() {}

    final EdgeInsetsGeometry padding = ButtonStyleButton.scaledPadding(
      const EdgeInsets.symmetric(horizontal: AppSpacing.l),
      const EdgeInsets.symmetric(horizontal: AppSpacing.m),
      const EdgeInsets.symmetric(horizontal: AppSpacing.s),
      MediaQuery.textScalerOf(context).getFontSizeMultiplier(
        fontSize: Theme.of(context).textTheme.labelLarge?.fontSize,
        fallbackFontSize: 14,
      ),
    );
    const visualDensity = VisualDensity(
      horizontal: VisualDensity.minimumDensity,
      vertical: VisualDensity.minimumDensity,
    );
    const MaterialTapTargetSize tapTargetSize =
        MaterialTapTargetSize.shrinkWrap;
    final ButtonStyle buttonStyle = switch (style) {
      UsernameStyle.loggedInUser ||
      UsernameStyle.storyUser => FilledButton.styleFrom(
        padding: padding,
        visualDensity: visualDensity,
        tapTargetSize: tapTargetSize,
      ),
      UsernameStyle.none => ElevatedButton.styleFrom(
        padding: padding,
        visualDensity: visualDensity,
        tapTargetSize: tapTargetSize,
      ),
    };
    final icon = AvatarWidget(username: username);
    final label = Text(username, maxLines: 1, overflow: TextOverflow.ellipsis);

    return switch (style) {
      UsernameStyle.loggedInUser when showAvatar => FilledButton.icon(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: buttonStyle,
        icon: icon,
        label: label,
      ),
      UsernameStyle.loggedInUser => FilledButton(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: buttonStyle,
        child: label,
      ),
      UsernameStyle.storyUser when showAvatar => FilledButton.tonalIcon(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: buttonStyle,
        icon: icon,
        label: label,
      ),
      UsernameStyle.storyUser => FilledButton(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: buttonStyle,
        child: label,
      ),
      UsernameStyle.none when showAvatar => ElevatedButton.icon(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: buttonStyle,
        icon: icon,
        label: label,
      ),
      UsernameStyle.none => ElevatedButton(
        onPressed: onPressed,
        onLongPress: onLongPress,
        style: buttonStyle,
        child: label,
      ),
    };
  }
}

enum UsernameStyle() {
  loggedInUser,
  storyUser,
  none
}
