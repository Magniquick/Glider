import 'package:flutter/services.dart';

const _assetPath = 'assets/public_suffix_list.dat';

Set<String>? _rules;
Set<String>? _exceptions;
Future<void>? _loading;

/// Loads the bundled Public Suffix List, once per process.
Future<void> ensurePublicSuffixListLoaded() {
  if (_rules != null) return Future<void>.value();
  return _loading ??= () async {
    final raw = await rootBundle.loadString(_assetPath);
    final rules = <String>{};
    final exceptions = <String>{};
    for (final line in raw.split('\n')) {
      if (line.isEmpty) continue;
      if (line.startsWith('!')) {
        exceptions.add(line.substring(1));
      } else {
        rules.add(line);
      }
    }
    _rules = rules;
    _exceptions = exceptions;
  }();
}

/// The public suffix of [labels], following the matching algorithm at
/// https://publicsuffix.org/list/: exceptions win, then the longest matching
/// rule, then the implicit `*` rule that makes any unknown TLD a suffix.
String _publicSuffix(List<String> labels) {
  for (var i = 0; i < labels.length; i++) {
    if (_exceptions!.contains(labels.sublist(i).join('.'))) {
      // An exception rule's suffix is the rule minus its leftmost label.
      return labels.sublist(i + 1).join('.');
    }
  }
  // Ascending i means longest candidate first, so the first hit is the
  // prevailing rule.
  for (var i = 0; i < labels.length; i++) {
    final candidate = labels.sublist(i);
    if (_rules!.contains(candidate.join('.'))) return candidate.join('.');
    if (candidate.length > 1 &&
        _rules!.contains(['*', ...candidate.skip(1)].join('.'))) {
      return candidate.join('.');
    }
  }
  return labels.last;
}

/// The registrable domain of [host] -- its public suffix plus one label -- or
/// null when [host] is itself a public suffix and so has no owner to speak of.
///
/// This is what separates a subdomain worth walking up from one that only
/// looks like one. `api-docs.deepseek.com` belongs to whoever owns
/// `deepseek.com`, but `bandarlabs.github.io` belongs to bandarlabs alone:
/// `github.io` is a public suffix, so treating it as a parent would hand every
/// GitHub Pages site GitHub's own identity.
///
/// Requires [ensurePublicSuffixListLoaded] to have completed.
String? registrableDomain(String host) {
  final normalised = host.toLowerCase();
  if (normalised.isEmpty) return null;

  final labels = normalised.split('.');
  final suffixLength = _publicSuffix(labels).split('.').length;
  if (labels.length <= suffixLength) return null;
  return labels.sublist(labels.length - suffixLength - 1).join('.');
}

/// Test seam: installs rules directly so lookups can run without assets.
void debugSetPublicSuffixRules(Iterable<String> rules) {
  _rules = {
    for (final r in rules)
      if (!r.startsWith('!')) r,
  };
  _exceptions = {
    for (final r in rules)
      if (r.startsWith('!')) r.substring(1),
  };
  _loading = null;
}
