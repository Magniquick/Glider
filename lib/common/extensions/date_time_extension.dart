import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:glider/l10n/extensions/app_localizations_extension.dart';

/// Number of microseconds in an average Gregorian year.
const _microsecondsPerYear = 31556952e6;

/// Number of microseconds in an average Gregorian month.
const _microsecondsPerMonth = _microsecondsPerYear / 12;

/// Formats a [DateTime] as how long ago it was.
///
/// Replaces the `relative_time` package, which had seen no release in nearly
/// three years. The wording matches what it produced, and lives in the app's
/// own ARB file so it goes through the same translation pipeline as everything
/// else instead of a second localization delegate.
extension DateTimeExtension on DateTime {
  /// This moment expressed relative to now, e.g. `3 hours ago`.
  String relativeTime(BuildContext context) {
    final int elapsed = clock.now().difference(this).abs().inMicroseconds;
    final l10n = context.l10n;

    // Largest unit that fits at least once wins, as relative_time did.
    final int years = elapsed ~/ _microsecondsPerYear;
    if (years >= 1) return l10n.relativeYears(years);

    final int months = elapsed ~/ _microsecondsPerMonth;
    if (months >= 1) return l10n.relativeMonths(months);

    final int weeks = elapsed ~/ (Duration.microsecondsPerDay * 7);
    if (weeks >= 1) return l10n.relativeWeeks(weeks);

    final int days = elapsed ~/ Duration.microsecondsPerDay;
    if (days >= 1) return l10n.relativeDays(days);

    final int hours = elapsed ~/ Duration.microsecondsPerHour;
    if (hours >= 1) return l10n.relativeHours(hours);

    final int minutes = elapsed ~/ Duration.microsecondsPerMinute;
    if (minutes >= 1) return l10n.relativeMinutes(minutes);

    return l10n.relativeSeconds(elapsed ~/ Duration.microsecondsPerSecond);
  }
}
