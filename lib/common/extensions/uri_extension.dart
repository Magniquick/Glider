import 'dart:async';

import 'package:flutter/material.dart';
import 'package:glider/common/constants/app_uris.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

/// The Hacker News paths the router has a route for.
///
/// Every other path on the same host is a page the app cannot render: a user's
/// `/submitted` or `/threads` list, a comment's `/context`, `/from?site=`, or
/// any section list. Pushing one of those into go_router matched no route and
/// left the reader on the error page instead of opening what they tapped, so
/// they go to the browser like any other link.
const _routableHackerNewsPaths = {'/item', '/user'};

extension UriExtension on Uri {
  Future<bool> tryLaunch(
    BuildContext context, {
    required bool useInAppBrowser,
    String? title,
  }) async {
    if (authority == AppUris.hackerNewsUri.authority &&
        _routableHackerNewsPaths.contains(path)) {
      unawaited(context.push(toString()));
      return true;
    }

    if (await canLaunchUrl(this)) {
      if (await supportsLaunchMode(LaunchMode.externalNonBrowserApplication)) {
        final bool success = await launchUrl(
          this,
          mode: LaunchMode.externalNonBrowserApplication,
          webOnlyWindowName: title,
        );
        if (success) return true;
      }

      if (useInAppBrowser &&
          await supportsLaunchMode(LaunchMode.inAppBrowserView)) {
        final bool success = await launchUrl(
          this,
          mode: LaunchMode.inAppBrowserView,
          webOnlyWindowName: title,
        );
        if (success) return true;
      }

      if (await supportsLaunchMode(LaunchMode.externalApplication)) {
        final bool success = await launchUrl(
          this,
          mode: LaunchMode.externalApplication,
          webOnlyWindowName: title,
        );
        if (success) return true;
      }
    }

    return false;
  }
}
