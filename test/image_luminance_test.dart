import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:glider/common/utils/image_luminance.dart';

/// Builds an image from straight (non-premultiplied) RGBA pixels.
Future<ui.Image> imageOf(List<List<int>> pixels) async {
  final bytes = Uint8List(pixels.length * 4);
  for (var i = 0; i < pixels.length; i++) {
    final p = pixels[i];
    // premultiply, which is what a decoded image gives us back
    final a = p[3];
    bytes[i * 4] = p[0] * a ~/ 255;
    bytes[i * 4 + 1] = p[1] * a ~/ 255;
    bytes[i * 4 + 2] = p[2] * a ~/ 255;
    bytes[i * 4 + 3] = a;
  }
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  final descriptor = ui.ImageDescriptor.raw(
    buffer,
    width: pixels.length,
    height: 1,
    pixelFormat: ui.PixelFormat.rgba8888,
  );
  final codec = await descriptor.instantiateCodec();
  return (await codec.getNextFrame()).image;
}

void main() {
  const opaque = 255;

  test('white is near 1.0, black near 0.0', () async {
    expect(
      await averageOpaqueLuminance(
        await imageOf([
          [255, 255, 255, opaque],
        ]),
      ),
      closeTo(1.0, 0.01),
    );
    expect(
      await averageOpaqueLuminance(
        await imageOf([
          [0, 0, 0, opaque],
        ]),
      ),
      closeTo(0.0, 0.01),
    );
  });

  test('fully transparent pixels are skipped, not counted as black', () async {
    // One white pixel beside three transparent ones. Counting the transparent
    // pixels as black would drag this to ~0.25 and misclassify a light mark on
    // a transparent background as dark.
    final image = await imageOf([
      [255, 255, 255, opaque],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
      [0, 0, 0, 0],
    ]);
    expect(await averageOpaqueLuminance(image), closeTo(1.0, 0.01));
  });

  test('a fully transparent image has no luminance', () async {
    expect(
      await averageOpaqueLuminance(
        await imageOf([
          [0, 0, 0, 0],
        ]),
      ),
      isNull,
    );
  });

  test('partial alpha is un-premultiplied back to its true colour', () async {
    // Half-transparent white must read as white, not as mid grey.
    final image = await imageOf([
      [255, 255, 255, 128],
    ]);
    expect(await averageOpaqueLuminance(image), greaterThan(0.9));
  });

  test('contrast ratio matches the WCAG definition', () {
    expect(contrastRatio(1.0, 0.0), closeTo(21.0, 0.01));
    expect(contrastRatio(0.0, 0.0), closeTo(1.0, 0.01));
  });

  test('relativeLuminance matches known sRGB values', () {
    expect(relativeLuminance(255, 255, 255), closeTo(1.0, 0.001));
    expect(relativeLuminance(0, 0, 0), closeTo(0.0, 0.001));
    // mid grey #808080
    expect(relativeLuminance(128, 128, 128), closeTo(0.2159, 0.005));
  });
}
