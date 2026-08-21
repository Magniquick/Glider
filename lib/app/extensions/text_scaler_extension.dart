import 'package:flutter/rendering.dart';

extension TextScalerExtension on TextScaler {
  double getFontSizeMultiplier({
    required double? fontSize,
    required double fallbackFontSize,
  }) {
    final double defaultFontSize = fontSize ?? fallbackFontSize;
    return scale(defaultFontSize) / fallbackFontSize;
  }
}
