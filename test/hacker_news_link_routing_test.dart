import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glider/app/models/app_route.dart';
import 'package:glider/common/extensions/uri_extension.dart';
import 'package:go_router/go_router.dart';

/// A tapped Hacker News link is handled by [UriExtension.tryLaunch], which
/// pushes *any* `news.ycombinator.com` URL into go_router. The router only
/// serves the [AppRoute] paths, so an HN URL for any other section lands on the
/// error page instead of opening. Comments and user pages both link to several
/// such sections.
///
/// The router here is built from [AppRoute]'s own top-level entries rather than
/// a hand-copied list, so it matches exactly what the app can route. Sub-routes
/// like `/item/reply` are irrelevant to a top-level HN link and are left out.
GoRouter _routerUnderTest() => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => Scaffold(
        body: Center(
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => (state.extra! as Uri).tryLaunch(
                context,
                useInAppBrowser: false,
              ),
              child: const Text('tap'),
            ),
          ),
        ),
      ),
    ),
    for (final route in AppRoute.values.where((route) => route.parent == null))
      if (route.path != '/')
        GoRoute(
          path: route.path,
          builder: (context, state) => Text('route:${route.name}'),
        ),
  ],
  errorBuilder: (context, state) => const Text('UNMATCHED'),
);

Future<void> _tap(WidgetTester tester, GoRouter router, Uri uri) async {
  router.go('/', extra: uri);
  await tester.pumpWidget(MaterialApp.router(routerConfig: router));
  await tester.tap(find.text('tap'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('an HN item link opens the item route', (tester) async {
    final router = _routerUnderTest();
    await _tap(
      tester,
      router,
      Uri.parse('https://news.ycombinator.com/item?id=1'),
    );
    expect(find.text('route:item'), findsOneWidget);
    expect(find.text('UNMATCHED'), findsNothing);
  });

  testWidgets('an HN user link opens the user route', (tester) async {
    final router = _routerUnderTest();
    await _tap(
      tester,
      router,
      Uri.parse('https://news.ycombinator.com/user?id=pg'),
    );
    expect(find.text('route:user'), findsOneWidget);
    expect(find.text('UNMATCHED'), findsNothing);
  });

  // Red: every one of these is a link a reader can tap from a comment or a
  // profile, and each is pushed into a router that has no route for it, so the
  // app shows "Page Not Found" instead of opening the page.
  group(
    'an HN section link the app cannot route stays out of the error page',
    () {
      const locations = {
        "a user's submissions": 'https://news.ycombinator.com/submitted?id=pg',
        "a user's comments": 'https://news.ycombinator.com/threads?id=pg',
        'a comment in context': 'https://news.ycombinator.com/context?id=1',
        'stories from a site':
            'https://news.ycombinator.com/from?site=example.com',
        'the newest list': 'https://news.ycombinator.com/newest',
      };

      for (final MapEntry(key: description, value: location)
          in locations.entries) {
        testWidgets(description, (tester) async {
          final router = _routerUnderTest();
          await _tap(tester, router, Uri.parse(location));
          expect(find.text('UNMATCHED'), findsNothing);
        });
      }
    },
  );
}
