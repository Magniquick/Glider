import 'package:flutter_test/flutter_test.dart';
import 'package:glider/item/widgets/favicon_resolution.dart';

void main() {
  setUp(resetFaviconResolutionsForTest);

  group('claiming a favicon lookup', () {
    test('the first caller wins', () {
      expect(claimFaviconLookup('example.com'), isTrue);
    });

    // The bug this exists for. Resolution is only recorded once a load
    // finishes, so a second row sharing the domain used to pass the guard
    // while the first was still in flight, and fetch the same icon again.
    test('a second caller is turned away while the first is in flight', () {
      expect(claimFaviconLookup('example.com'), isTrue);
      expect(claimFaviconLookup('example.com'), isFalse);
      expect(claimFaviconLookup('example.com'), isFalse);
    });

    test('a different host is unaffected', () {
      expect(claimFaviconLookup('example.com'), isTrue);
      expect(claimFaviconLookup('other.com'), isTrue);
    });

    test('nobody re-fetches once it has resolved', () {
      claimFaviconLookup('example.com');
      recordFaviconResolution('example.com', url: 'https://icon', luminance: 1);

      expect(claimFaviconLookup('example.com'), isFalse);
    });

    test('nobody retries a host that resolved to no icon at all', () {
      claimFaviconLookup('example.com');
      recordFaviconResolution('example.com', url: null, luminance: null);

      expect(claimFaviconLookup('example.com'), isFalse);
    });

    test('resolving hands the result to every row that wanted it', () {
      claimFaviconLookup('example.com');
      recordFaviconResolution(
        'example.com',
        url: 'https://icon',
        luminance: 0.5,
      );

      expect(faviconUrlFor('example.com'), 'https://icon');
      expect(faviconLuminanceFor('example.com'), 0.5);
    });
  });
}
