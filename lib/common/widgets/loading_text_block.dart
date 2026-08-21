import 'package:flutter/widgets.dart';
import 'package:glider/common/extensions/text_style_extension.dart';
import 'package:glider/common/widgets/loading_block.dart';

class const LoadingTextBlock({
  super.key,
  this.width,
  this.style,
  this.hasLeading = true,
}) extends StatelessWidget {
  final double? width;
  final TextStyle? style;
  final bool hasLeading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (hasLeading) SizedBox(height: style?.leading(context)),
        LoadingBlock(width: width, height: style?.scaledFontSize(context)),
      ],
    );
  }
}
