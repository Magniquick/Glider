import 'package:html/dom.dart' as html_dom;
import 'package:html/parser.dart' as html_parser;

// https://news.ycombinator.com/formatdoc
extension StringExtension on String {
  String convertHtmlToHackerNews() => html_parser.parseFragment(this).convert();
}

/// Percent-decodes [url] for display, falling back to the original string when
/// it cannot be decoded.
///
/// Comments contain plenty of URLs with stray or truncated escapes (`100%`,
/// `%zz`, a `%E2` whose continuation bytes were cut off). `Uri.decodeFull`
/// signals all of those by throwing, so showing such a URL verbatim is the
/// only sensible fallback.
String _decodeForDisplay(String url) {
  if (!url.contains('%')) return url;
  try {
    return Uri.decodeFull(url);
    // `Uri.decodeFull` reports malformed escapes as ArgumentError and invalid
    // UTF-8 byte sequences as FormatException.
    // ignore: avoid_catching_errors
  } on ArgumentError {
    return url;
  } on FormatException {
    return url;
  }
}

/// Renders [url] as a Markdown link whose label is human-readable but whose
/// destination preserves Hacker News' own encoding.
String _linkMarkdown(String url) {
  // `[` and `]` would terminate the label early. Decoding can also reveal
  // Markdown metacharacters that were hidden as escapes: `%2A` becomes `*`
  // (emphasis) and `%60` becomes a backtick (code).
  final label = _decodeForDisplay(url)
      .replaceAllMapped(RegExp(r'[\[\]\\*`]'), (match) => '\\${match[0]}');
  // An angle-bracket destination tolerates parentheses and spaces in the URL,
  // which a bare destination does not. `<`, `>` and `\` must still be escaped:
  // a trailing backslash would otherwise escape the closing `>` and break the
  // link entirely. Those three bytes aside, the original encoding is preserved.
  final destination = url
      .replaceAll(r'\', '%5C')
      .replaceAll('<', '%3C')
      .replaceAll('>', '%3E');
  return '[$label](<$destination>)';
}

extension on html_dom.Node {
  String get _url => attributes['href'] ?? text!;

  String convert() => switch (this) {
    // "Urls become links, except in the text field of a submission."
    // We cheat by not handling submissions any differently.
    // Unlike the website, we prefer showing the full URL, percent-decoded so
    // that it is readable. The link target keeps the original encoding.
    html_dom.Element(localName: 'a') => _linkMarkdown(_url),
    // "Text surrounded by asterisks is italicized."
    html_dom.Element(localName: 'i') => '*${convertNodes()}*',
    // "Blank lines separate paragraphs."
    html_dom.Element(localName: 'p') => '\n\n${convertNodes()}',
    // "Text after a blank line that is indented by two or more spaces is
    // reproduced verbatim. (This is intended for code.)"
    // No need to add spaces here though, as they're part of the HTML.
    html_dom.Text(parentNode: html_dom.Element(localName: 'code')) => text!,
    // "To get a literal asterisk, use \* or **."
    // Escape asterisks not surrounded by spaces.
    // There may be newlines part of the HTML which don't show up on the
    // website. Replace them with a space, but exclude starting newlines.
    // There may be adjacent spaces. Replace them with single spaces.
    html_dom.Text() =>
      text!
          .replaceAll(RegExp(r'(?<!^| )\*|\*(?! |$)'), r'\*')
          .replaceAll(RegExp(r'(?<!^)\n'), ' ')
          .replaceAll(RegExp(' {2,}'), ' '),
    _ => convertNodes(),
  };

  String convertNodes() => nodes.map((node) => node.convert()).join();
}
