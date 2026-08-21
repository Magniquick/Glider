import 'dart:math' as math;
import 'dart:ui' as ui;

/// Average relative luminance of an image's opaque pixels, or null if the
/// image is entirely transparent.
///
/// Fully transparent pixels are skipped rather than counted as black. Counting
/// them drags a light mark on a transparent background down into the "dark"
/// range, which is the classic bug in this kind of analysis.
///
/// Uses WCAG relative luminance rather than a perceptual average, because the
/// caller compares the result against a surface colour as a contrast ratio.
Future<double?> averageOpaqueLuminance(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return null;

  final bytes = data.buffer.asUint8List();
  var total = 0.0;
  var counted = 0;

  for (var i = 0; i + 3 < bytes.length; i += 4) {
    final alpha = bytes[i + 3];
    if (alpha == 0) continue;

    // rawRgba is premultiplied, so undo that before measuring colour.
    final scale = 255 / alpha;
    total += relativeLuminance(
      (bytes[i] * scale).clamp(0, 255).round(),
      (bytes[i + 1] * scale).clamp(0, 255).round(),
      (bytes[i + 2] * scale).clamp(0, 255).round(),
    );
    counted++;
  }

  return counted == 0 ? null : total / counted;
}

/// WCAG relative luminance of an sRGB colour, each channel 0-255.
double relativeLuminance(int r, int g, int b) =>
    0.2126 * _linearize(r) + 0.7152 * _linearize(g) + 0.0722 * _linearize(b);

double _linearize(int channel) {
  final v = channel / 255;
  return v <= 0.04045
      ? v / 12.92
      : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
}

/// WCAG contrast ratio between two relative luminances.
double contrastRatio(double a, double b) {
  final hi = a > b ? a : b;
  final lo = a > b ? b : a;
  return (hi + 0.05) / (lo + 0.05);
}
