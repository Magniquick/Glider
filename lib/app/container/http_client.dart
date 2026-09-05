import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Builds the HTTP client the whole data layer runs on.
///
/// One implementation on every platform. `package:http` is the abstraction but
/// selects nothing for you, so this is the per-platform factory the Dart team
/// documents; it just happens to have no per-platform branch left.
///
/// Android used Cronet, justified by connection pooling and HTTP/2 and HTTP/3
/// across the many small requests a comment tree needed. Every part of that has
/// since stopped being true. A thread is one request now rather than two
/// thousand. Neither host we talk to offers HTTP/3: neither sends `alt-svc`,
/// and forcing h3 against news.ycombinator.com fails outright. The Firebase
/// host answers HTTP/1.1 only, so HTTP/2 never applied to it either, leaving
/// header compression on a single request per screen as the whole benefit.
///
/// Dropping it also gains something concrete, rather than merely costing
/// nothing. Cronet runs its own connection pool with no way to tune it, so the
/// idle timeout below did not reach the one platform that ships. Measured
/// against news.ycombinator.com, that timeout is worth about 600 ms on the
/// first request after any pause longer than fifteen seconds.
http.Client createHttpClient() =>
    IOClient(HttpClient()..idleTimeout = _idleTimeout);

/// How long an idle connection is kept for reuse.
///
/// `dart:io` defaults to 15 seconds, which throws away a connection Hacker
/// News would have kept. Measured: a request after 5, 20 and 45 seconds idle
/// reused the connection and returned in 0.22 to 0.33 seconds, while one after
/// 70 seconds cost 1.17 seconds because the handshake had to be repeated. That
/// puts the server's own limit between 45 and 70 seconds, which is nginx's
/// default `keepalive_timeout 65`.
///
/// Sixty stays inside that. Reading a story list for half a minute before
/// opening a thread is ordinary, and it should not cost a fresh TCP and TLS
/// handshake. Going beyond the server's limit would only mean reaching for a
/// socket it had already closed.
const _idleTimeout = Duration(seconds: 60);
