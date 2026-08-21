import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glider/common/utils/brand_icon.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('brandIconFor', () {
    setUp(
      () => debugSetBrandIconIndex({
        'github.com': 'github',
        'deepseek.com': 'deepseek',
      }, version: '16.28.0'),
    );

    test('resolves a known domain to its CDN url', () async {
      final brand = await brandIconFor('github.com');
      expect(brand?.slug, 'github');
      expect(
        brand?.url,
        'https://cdn.jsdelivr.net/npm/simple-icons@16.28.0/icons/github.svg',
      );
    });

    test('falls back to the registrable domain for a subdomain', () async {
      expect((await brandIconFor('api-docs.deepseek.com'))?.slug, 'deepseek');
    });

    test('ignores a leading www and matches case-insensitively', () async {
      expect((await brandIconFor('WWW.GitHub.com'))?.slug, 'github');
    });

    test('returns null for a domain the index does not carry', () async {
      expect(await brandIconFor('passo.uno'), isNull);
    });
  });

  group('bundled index', () {
    test('is well formed and carries the domains it claims', () async {
      final raw = await rootBundle.loadString(
        'assets/simple_icons/domains.json',
      );
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final domains = (decoded['domains'] as Map<String, dynamic>);

      expect(
        RegExp(r'^\d+\.\d+\.\d+$').hasMatch(decoded['version'] as String),
        isTrue,
      );
      expect(domains.length, greaterThan(2000));
      // Regression: a source URL on github.com once handed the whole domain
      // to whichever unrelated brand happened to sort first.
      expect(domains['github.com'], 'github');
      expect(domains['twitter.com'], 'x');
    });
  });
}
