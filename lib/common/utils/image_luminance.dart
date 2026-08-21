import 'dart:math' as math;
import 'dart:ui' as ui;

/// What a favicon looks like: how bright its opaque pixels are on average,
/// and where those pixels actually sit within the image.
typedef FaviconAnalysis = ({double? luminance, ui.Rect? opaqueBounds});

/// Pixels this faint are treated as transparent when finding [opaqueBounds].
///
/// Antialiased edges and drop shadows fade to a near-zero alpha that still
/// technically covers the whole canvas, which would defeat the trim entirely.
const _opaqueAlphaThreshold = 16;

/// Measures [image] in a single pass over its pixels.
///
/// [FaviconAnalysis.luminance] is the average WCAG relative luminance of the
/// opaque pixels, or null if the image is entirely transparent. Fully
/// transparent pixels are skipped rather than counted as black -- counting
/// them drags a light mark on a transparent background down into the "dark"
/// range, which is the classic bug in this kind of analysis. WCAG luminance
/// rather than a perceptual average, because the caller compares the result
/// against a surface colour as a contrast ratio.
///
/// [FaviconAnalysis.opaqueBounds] is the box the visible pixels occupy,
/// normalised to 0..1, or null if nothing is visible. Plenty of real icons are
/// a small glyph centred in a much larger transparent canvas -- multi-frame
/// ICOs are frequently authored by padding one 16x16 image out to 64x64 -- and
/// drawn as-is those render as a speck in the corner of their tile.
Future<FaviconAnalysis> analyseFavicon(ui.Image image) async {
  final data = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
  if (data == null) return (luminance: null, opaqueBounds: null);

  final bytes = data.buffer.asUint8List();
  final width = image.width;
  var total = 0.0;
  var counted = 0;
  var left = width, top = image.height, right = -1, bottom = -1;

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

    if (alpha < _opaqueAlphaThreshold) continue;
    final pixel = i ~/ 4;
    final x = pixel % width;
    final y = pixel ~/ width;
    if (x < left) left = x;
    if (x > right) right = x;
    if (y < top) top = y;
    if (y > bottom) bottom = y;
  }

  return (
    luminance: counted == 0 ? null : total / counted,
    opaqueBounds: right < 0
        ? null
        : ui.Rect.fromLTRB(
            left / width,
            top / image.height,
            (right + 1) / width,
            (bottom + 1) / image.height,
          ),
  );
}

/// Average relative luminance of an image's opaque pixels, or null if the
/// image is entirely transparent. See [analyseFavicon].
Future<double?> averageOpaqueLuminance(ui.Image image) async =>
    (await analyseFavicon(image)).luminance;

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
