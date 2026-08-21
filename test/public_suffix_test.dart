import 'package:flutter_test/flutter_test.dart';
import 'package:glider/common/utils/public_suffix.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('registrableDomain', () {
    setUp(
      () => debugSetPublicSuffixRules([
        'com',
        'org',
        'uk',
        'co.uk',
        'github.io',
        'blogspot.com',
        'ck',
        '*.ck',
        '!www.ck',
      ]),
    );

    test('walks a subdomain up to its owner', () {
      expect(registrableDomain('api-docs.deepseek.com'), 'deepseek.com');
      expect(registrableDomain('www.winona.com'), 'winona.com');
    });

    test('stops at a private public suffix', () {
      // The whole point: bandarlabs owns this, GitHub does not.
      expect(registrableDomain('bandarlabs.github.io'), 'bandarlabs.github.io');
      expect(
        registrableDomain('gus-massa.blogspot.com'),
        'gus-massa.blogspot.com',
      );
    });

    test('handles a multi-label ICANN suffix', () {
      expect(registrableDomain('bbc.co.uk'), 'bbc.co.uk');
      expect(registrableDomain('news.bbc.co.uk'), 'bbc.co.uk');
    });

    test('returns null when the host is itself a public suffix', () {
      expect(registrableDomain('github.io'), isNull);
      expect(registrableDomain('co.uk'), isNull);
      expect(registrableDomain('com'), isNull);
    });

    test('applies wildcard and exception rules', () {
      expect(registrableDomain('foo.bar.ck'), 'foo.bar.ck');
      expect(registrableDomain('www.ck'), 'www.ck');
    });

    test('treats an unknown tld as a suffix of one label', () {
      expect(registrableDomain('passo.uno'), 'passo.uno');
      expect(registrableDomain('blog.passo.uno'), 'passo.uno');
    });

    test('is case insensitive', () {
      expect(registrableDomain('API-Docs.DeepSeek.COM'), 'deepseek.com');
    });
  });

  group('bundled list', () {
    test('loads and carries the suffixes that matter here', () async {
      await ensurePublicSuffixListLoaded();
      expect(registrableDomain('bandarlabs.github.io'), 'bandarlabs.github.io');
      expect(
        registrableDomain('lawrencecpaulson.github.io'),
        'lawrencecpaulson.github.io',
      );
      expect(registrableDomain('api-docs.deepseek.com'), 'deepseek.com');
      expect(registrableDomain('news.bbc.co.uk'), 'bbc.co.uk');
    });
  });
}
