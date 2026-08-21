import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glider/common/extensions/date_time_extension.dart';
import 'package:glider/l10n/app_localizations.dart';

/// Pumps a localized subtree and returns what [DateTimeExtension.relativeTime]
/// renders for [time], with `now` pinned so the result is deterministic.
Future<String> relative(WidgetTester tester, DateTime time) async {
  late String result;
  await tester.pumpWidget(
    MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) {
          result = time.relativeTime(context);
          return const SizedBox();
        },
      ),
    ),
  );
  return result;
}

void main() {
  final now = DateTime.utc(2026, 6, 15, 12);

  Future<String> ago(WidgetTester tester, Duration d) =>
      withClock(Clock.fixed(now), () => relative(tester, now.subtract(d)));

  group('relativeTime', () {
    testWidgets('picks the largest unit that fits', (tester) async {
      expect(await ago(tester, const Duration(seconds: 5)), '5 seconds ago');
      expect(await ago(tester, const Duration(minutes: 3)), '3 minutes ago');
      expect(await ago(tester, const Duration(hours: 13)), '13 hours ago');
      expect(await ago(tester, const Duration(days: 3)), '3 days ago');
      expect(await ago(tester, const Duration(days: 21)), '3 weeks ago');
    });

    testWidgets('uses natural wording for a single unit', (tester) async {
      expect(await ago(tester, const Duration(days: 1)), 'yesterday');
      expect(await ago(tester, const Duration(days: 8)), 'last week');
      expect(await ago(tester, const Duration(hours: 1)), '1 hour ago');
      expect(await ago(tester, const Duration(minutes: 1)), '1 minute ago');
    });

    testWidgets('handles months and years', (tester) async {
      expect(await ago(tester, const Duration(days: 40)), 'last month');
      expect(await ago(tester, const Duration(days: 200)), '6 months ago');
      expect(await ago(tester, const Duration(days: 400)), 'last year');
      expect(await ago(tester, const Duration(days: 800)), '2 years ago');
    });

    testWidgets('reports the present as now', (tester) async {
      expect(await ago(tester, Duration.zero), 'now');
    });
  });
}
