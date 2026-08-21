import 'package:flutter/painting.dart';

abstract final class AppSpacing() {
  static const _baseUnit = 4.0;

  static const double s = _baseUnit;

  static const double m = _baseUnit * 2;

  static const double l = _baseUnit * 3;

  static const double xl = _baseUnit * 4;

  static const double xxl = _baseUnit * 6;

  static const defaultTilePadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: m,
  );

  static const defaultShadowPadding = EdgeInsets.all(2);

  static const floatingActionButtonPageBottomPadding = EdgeInsets.only(
    bottom: 88,
  );

  static const twoSmallFloatingActionButtonsPageBottomPadding = EdgeInsets.only(
    bottom: 136,
  );
}
