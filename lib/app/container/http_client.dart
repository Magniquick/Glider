import 'dart:io';

import 'package:cronet_http/cronet_http.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Builds the HTTP client the whole data layer runs on.
///
/// On Android this is Cronet, for connection pooling and HTTP/2 and HTTP/3
/// across the many small requests a comment tree needs. Everywhere else it is
/// the default `dart:io` client.
///
/// How Cronet is delivered is a build-time choice made in Gradle, not here:
/// by default it comes from Google Play Services (a 0.09 MB shim), and
/// building with `--dart-define=cronetHttpNoPlay=true` swaps in the embedded
/// Chromium net stack instead (~3-4 MB per ABI), which is what a build for a
/// store that disallows proprietary Google dependencies would need. The Dart
/// side is identical either way.
///
/// Dropping Cronet altogether means deleting the Android branch below; every
/// service takes its [http.Client] by constructor injection, so nothing else
/// changes.
http.Client createHttpClient() {
  if (!kIsWeb && Platform.isAndroid) {
    try {
      return CronetClient.fromCronetEngine(
        CronetEngine.build(enableHttp2: true, enableQuic: true),
        closeEngine: true,
      );
    } on Object catch (error) {
      // Play Services is absent on de-Googled ROMs and on some emulators, and
      // an embedded build can still fail to load its native library. Neither
      // is a reason to refuse to start.
      debugPrint('Cronet unavailable, falling back to dart:io: $error');
      return IOClient();
    }
  }

  return IOClient();
}
