import 'package:flutter_test/flutter_test.dart';
import 'package:glider_domain/src/extensions/string_extension.dart';

/// Extracts the label and destination from `[label](<destination>)`.
({String label, String destination}) parseLink(String markdown) {
  final match = RegExp(
    r'^\[(.*)\]\(<(.*)>\)$',
    dotAll: true,
  ).firstMatch(markdown.trim());
  expect(match, isNotNull, reason: 'not a link: $markdown');
  return (label: match!.group(1)!, destination: match.group(2)!);
}

String convertAnchor(String href) =>
    '<a href="$href" rel="nofollow">$href</a>'.convertHtmlToHackerNews();

void main() {
  group('anchor conversion', () {
    test('shows the percent-decoded URL but links to the original', () {
      const href =
          'https://en.wikipedia.org/wiki/Bh%C4%81skara_I%27s_sine_approximation_formula';
      final link = parseLink(convertAnchor(href));
      expect(
        link.label,
        'https://en.wikipedia.org/wiki/Bhāskara_I\'s_sine_approximation_formula',
      );
      expect(link.destination, href, reason: 'target must stay encoded');
    });

    test('decodes multi-byte UTF-8 escapes', () {
      const href =
          'https://en.wikipedia.org/wiki/%C4%80ryabha%E1%B9%ADa\'s_sine_table';
      final link = parseLink(convertAnchor(href));
      expect(link.label, contains('Āryabhaṭa'));
      expect(link.destination, href);
    });

    test('decodes an en dash', () {
      const href = 'https://en.wikipedia.org/wiki/Price%E2%80%93earnings_ratio';
      expect(
        parseLink(convertAnchor(href)).label,
        endsWith('Price–earnings_ratio'),
      );
    });

    test('decodes %20 inside a query string', () {
      const href =
          'https://www.biblegateway.com/passage/?search=1%20Corinthians';
      final link = parseLink(convertAnchor(href));
      expect(link.label, endsWith('?search=1 Corinthians'));
      expect(link.destination, href, reason: 'the space must stay encoded');
    });

    test('leaves malformed percent escapes alone instead of throwing', () {
      for (final href in [
        'https://example.com/%zz',
        'https://example.com/100%',
        'https://example.com/%E2%28',
      ]) {
        final link = parseLink(convertAnchor(href));
        expect(link.label, href, reason: 'undecodable, so shown verbatim');
        expect(link.destination, href);
      }
    });

    test('keeps unencoded parentheses in the destination', () {
      const href =
          'https://en.wikipedia.org/wiki/Monad_(functional_programming)';
      final link = parseLink(convertAnchor(href));
      expect(link.destination, href);
      expect(link.label, href);
    });

    test('escapes brackets so they cannot terminate the label', () {
      const href = 'https://example.com/a%5Bb%5Dc';
      final link = parseLink(convertAnchor(href));
      expect(link.label, r'https://example.com/a\[b\]c');
      expect(link.destination, href);
    });

    test('escapes angle brackets in the destination', () {
      const href = 'https://example.com/a<b>c';
      expect(
        parseLink(convertAnchor(href)).destination,
        'https://example.com/a%3Cb%3Ec',
      );
    });

    test('falls back to the anchor text when there is no href', () {
      expect(
        parseLink('<a>https://example.com/%41</a>'.convertHtmlToHackerNews()),
        (
          label: 'https://example.com/A',
          destination: 'https://example.com/%41',
        ),
      );
    });
  });
}
