import 'dart:ui';

import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';

// The key is derived from a constructor parameter, so this constructor can
// never be const. The lint does not see the non-const super initialiser in
// primary-constructor syntax (false positive on Dart 3.13).
// ignore: prefer_const_constructors_in_immutables
class AvatarWidget({required final String username}) extends StatelessWidget {
  this : super(key: ValueKey(username));

  @override
  Widget build(BuildContext context) {
    final double pixelSize = MediaQuery.textScalerOf(context).scale(2);
    final double avatarSize = pixelSize * 7;

    return CustomPaint(
      painter: _AvatarPainter(
        username: username,
        pixelSize: pixelSize,
        offset: Offset(pixelSize / 2, pixelSize / 2),
      ),
      size: Size.square(avatarSize),
    );
  }
}

// Algorithm based on https://news.ycombinator.com/item?id=30668207 by tomxor.
class const _AvatarPainter({
  required final String username,
  required final double pixelSize,
  required final Offset offset,
}) extends CustomPainter with EquatableMixin {
  @override
  void paint(Canvas canvas, Size size) {
    const seedSteps = 28;
    final points = <Offset>[];
    final paint = Paint()..strokeWidth = pixelSize;
    var seed = 1;

    for (int i = seedSteps + username.length - 1; i >= seedSteps; i--) {
      seed = _xorShift32(seed);
      seed += username.codeUnitAt(i - seedSteps);
    }

    paint.color = Color(seed >> 8 | 0xff000000);

    for (int i = seedSteps - 1; i >= 0; i--) {
      seed = _xorShift32(seed);

      final int x = i & 3;
      final int y = i >> 2;

      if (seed.toUnsigned(32) >> seedSteps + 1 > x * x / 3 + y / 2) {
        points
          ..add(Offset(pixelSize * 3 + pixelSize * x, pixelSize * y) + offset)
          ..add(Offset(pixelSize * 3 - pixelSize * x, pixelSize * y) + offset);
      }
    }

    canvas.drawPoints(PointMode.points, points, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      oldDelegate != this;

  @override
  List<Object?> get props => [username, pixelSize, offset];

  static int _xorShift32(int number) {
    var result = number;
    result ^= result << 13;
    result ^= result.toUnsigned(32) >> 17;
    result ^= result << 5;
    return result;
  }
}
