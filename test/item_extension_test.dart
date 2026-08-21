import 'package:flutter_test/flutter_test.dart';
import 'package:glider/common/utils/public_suffix.dart';
import 'package:glider/item/extensions/item_extension.dart';
import 'package:glider_domain/glider_domain.dart';

Item _itemWithUrl(String? url) =>
    Item(id: 1, url: url != null ? Uri.parse(url) : null);

void main() {
  group('faviconUrls', () {
    setUp(() => debugSetPublicSuffixRules(['com', 'uno', 'github.io']));

    test('is empty when the item has no link', () {
      expect(_itemWithUrl(null).faviconUrls, isEmpty);
    });

    test('offers only the host when there is no subdomain to strip', () {
      expect(_itemWithUrl('https://deepseek.com/docs').faviconUrls, [
        'https://icons.duckduckgo.com/ip3/deepseek.com.ico',
      ]);
    });

    test('falls back to the parent domain for a subdomain', () {
      // DuckDuckGo 404s on api-docs.deepseek.com but serves deepseek.com.
      expect(_itemWithUrl('https://api-docs.deepseek.com/').faviconUrls, [
        'https://icons.duckduckgo.com/ip3/api-docs.deepseek.com.ico',
        'https://icons.duckduckgo.com/ip3/deepseek.com.ico',
      ]);
    });

    test('tries the full host first, since www can be the only hit', () {
      // The reverse case: www.winona.com serves an icon, winona.com 404s.
      expect(
        _itemWithUrl('https://www.winona.com/').faviconUrls.first,
        'https://icons.duckduckgo.com/ip3/www.winona.com.ico',
      );
    });

    test('strips only one label, never past the registrable domain', () {
      expect(
        _itemWithUrl('https://a.b.c.example.com/').faviconUrls,
        hasLength(2),
      );
    });
  });
}
