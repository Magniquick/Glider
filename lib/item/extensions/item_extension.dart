import 'package:flutter/widgets.dart';
import 'package:glider/l10n/extensions/app_localizations_extension.dart';
import 'package:glider_domain/glider_domain.dart';

// These regular expressions are partially based on analysis from
// https://vsupalov.com/frequent-hn-title-suffixes-prefixes/.
final RegExp _prefixRegExp = RegExp(r'^(\S+\s+(?:HN|YC|PG)|Poll):\s+');
final RegExp _suffixRegExp = RegExp(r'\s+\[(\S+)\](?=(?:\s|$))');
final RegExp _originalDateRegExp = RegExp(r'\s+\(((?:\S+\s+)?\d{4})\)$');
final RegExp _ycBatchRegExp = RegExp(r'\s+\((YC\s*[SW]\d{2})\)');

const _usernameTags = <String, _UsernameTag>{
  'tlb': _UsernameTag.founder,
  'pg': _UsernameTag.founder,
  'jl': _UsernameTag.founder,
  'rtm': _UsernameTag.founder,
  'garry': _UsernameTag.ceo,
  'dang': _UsernameTag.moderator,
  'sctb': _UsernameTag.exModerator,
  'whoishiring': _UsernameTag.bot,
  'cats4ever': _UsernameTag.purrfect,
};

extension ItemExtension on Item {
  String? get storyUsername =>
      type == ItemType.story || type == ItemType.poll ? username : null;

  String? get filteredTitle => title
      ?.replaceAll(_prefixRegExp, '')
      .replaceAll(_suffixRegExp, '')
      .replaceAll(_originalDateRegExp, '')
      .replaceAll(_ycBatchRegExp, '');

  bool get hasPrefix => title != null && _prefixRegExp.hasMatch(title!);

  String? get prefix => _prefixRegExp.firstMatch(title!)?.group(1);

  bool get hasSuffix => title != null && _suffixRegExp.hasMatch(title!);

  String? get suffix =>
      _suffixRegExp.firstMatch(title!)?.group(1)?.toLowerCase();

  bool get hasOriginalDate =>
      title != null && _originalDateRegExp.hasMatch(title!);

  String? get originalDate => _originalDateRegExp.firstMatch(title!)?.group(1);

  bool get hasYcBatch => title != null && _ycBatchRegExp.hasMatch(title!);

  String? get ycBatch => _ycBatchRegExp.firstMatch(title!)?.group(1);

  bool get hasUsernameTag => _usernameTags.containsKey(username);

  String? usernameTag(BuildContext context) =>
      switch (_usernameTags[username]) {
        _UsernameTag.founder => context.l10n.founder,
        _UsernameTag.ceo => context.l10n.ceo,
        _UsernameTag.moderator => context.l10n.moderator,
        _UsernameTag.exModerator => context.l10n.exModerator,
        _UsernameTag.bot => context.l10n.bot,
        _UsernameTag.purrfect => context.l10n.purrfect,
        null => null,
      };

  /// Favicon for this item's link, or null if it has no link.
  ///
  /// The previous source, icons.viter.nl, was the original maintainer's own
  /// server and no longer resolves -- it answers every request with Cloudflare
  /// error 1000 ("DNS points to prohibited IP"), so favicons had been broken
  /// for everyone. DuckDuckGo's endpoint serves the same purpose and does not
  /// take a size, so the icon is scaled on the device instead.
  String? get faviconUrl => url != null
      ? Uri.https('icons.duckduckgo.com', 'ip3/${url!.host}.ico').toString()
      : null;
}

enum _UsernameTag() {
  founder,
  ceo,
  moderator,
  exModerator,
  bot,
  purrfect
}
