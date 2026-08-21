import 'package:flutter_test/flutter_test.dart';
import 'package:glider/common/widgets/hacker_news_text.dart';
import 'package:glider_domain/glider_domain.dart';
import 'package:markdown/markdown.dart' as md;

/// Runs a Hacker News HTML fragment through the exact pipeline the app uses:
/// HTML -> Hacker News flavoured Markdown -> [HackerNewsText.parse].
///
/// The unit tests in `glider_domain` only assert on the intermediate Markdown
/// string, so they would pass even if the parser rejected it. These assert on
/// the parsed tree instead.
List<md.Node> parse(String hackerNewsHtml) =>
    HackerNewsText.parse(hackerNewsHtml.convertHtmlToHackerNews());

/// Collects the `href` of every link in the parsed tree.
///
/// This is what `flutter_markdown_plus` reads to build the tap target, so it is
/// the value that decides where the user actually goes. Rendering to HTML would
/// apply the renderer's own escaping and hide that.
List<String> hrefs(List<md.Node> nodes) {
  final found = <String>[];
  void visit(List<md.Node> ns) {
    for (final node in ns) {
      if (node is md.Element) {
        if (node.tag == 'a') found.add(node.attributes['href'] ?? '');
        final children = node.children;
        if (children != null) visit(children);
      }
    }
  }

  visit(nodes);
  return found;
}

/// The visible text of the parsed tree.
String textOf(List<md.Node> nodes) {
  final buffer = StringBuffer();
  void visit(List<md.Node> ns) {
    for (final node in ns) {
      if (node is md.Text) buffer.write(node.text);
      if (node is md.Element) visit(node.children ?? const []);
    }
  }

  visit(nodes);
  return buffer.toString();
}

void main() {
  group('link round trip through the markdown parser', () {
    test('href keeps its percent-encoding while the label is decoded', () {
      const href =
          'https://en.wikipedia.org/wiki/Bh%C4%81skara_I%27s_sine_approximation_formula';
      final nodes = parse('<a href="$href" rel="nofollow">$href</a>');
      expect(hrefs(nodes), [href], reason: 'target must stay encoded');
      expect(
        textOf(nodes),
        contains("Bhāskara_I's_sine_approximation_formula"),
      );
    });

    test('unencoded parentheses survive as part of the destination', () {
      // A bare markdown destination would stop at the first `)`.
      const href =
          'https://en.wikipedia.org/wiki/Monad_(functional_programming)';
      expect(hrefs(parse('<a href="$href">$href</a>')), [href]);
    });

    test('a decoded asterisk does not become emphasis', () {
      const href = 'https://example.com/%2Ax%2A';
      final nodes = parse('<a href="$href">$href</a>');
      expect(hrefs(nodes), [href]);
      expect(textOf(nodes), contains('*x*'), reason: 'asterisks must survive');
    });

    test('a trailing backslash does not break the link', () {
      final nodes = parse(r'<a href="https://example.com/a\">link</a>');
      expect(hrefs(nodes), [
        'https://example.com/a%5C',
      ], reason: 'a trailing backslash must not swallow the closing angle');
    });

    test('a malformed escape survives as a valid URL', () {
      // `Uri.decodeFull` throws on a bare `%`, so the label keeps it verbatim.
      // package:markdown then normalises the destination's `%` to `%25`, which
      // decodes back to the original URL, so the tap target stays correct.
      const href = 'https://example.com/100%';
      final nodes = parse('<a href="$href">$href</a>');
      expect(hrefs(nodes), ['https://example.com/100%25']);
      expect(Uri.decodeFull(hrefs(nodes).single), href);
      expect(textOf(nodes), contains('100%'));
    });
  });
}
