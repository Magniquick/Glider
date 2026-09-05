import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Builds the HTTP client the whole data layer runs on.
///
/// Android used Cronet, for HTTP/2 and QUIC across the many small requests a
/// comment tree needed. A thread is one request now, and neither host we talk
/// to offers HTTP/3, so it was dropped: one implementation everywhere, and the
/// idle timeout below reaches every platform.
http.Client createHttpClient() =>
    IOClient(HttpClient()..idleTimeout = _idleTimeout);

/// How long an idle connection is kept for reuse.
///
/// `dart:io` defaults to 15 seconds, which discards a connection Hacker News
/// would have kept. Measured, it holds one for somewhere between 45 and 70
/// seconds, matching nginx's default `keepalive_timeout 65`. Going past that
/// would only mean reaching for a socket it had already closed.
const _idleTimeout = Duration(seconds: 60);
