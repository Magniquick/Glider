import 'dart:ui';

import 'package:flutter/foundation.dart';

/// Which favicon won for a host, or null once it is known there is none.
final _resolution = <String, String?>{};

/// Mean luminance of that icon, used to pick the plate behind it.
final _luminance = <String, double?>{};

/// Opaque bounds of that icon, used to trim its padding.
final _bounds = <String, Rect?>{};

/// Hosts with a lookup running right now.
///
/// Resolution is only recorded once a load finishes or runs out of candidates,
/// so without this a second row sharing a domain passes the resolved check
/// while the first is still in flight, and fetches the same icon again.
final _inFlight = <String>{};

/// Whether this caller should start the lookup for [host].
///
/// True for exactly one caller per host: whoever asks first. Everyone else
/// waits for the result, whether the lookup is finished or still running.
bool claimFaviconLookup(String host) =>
    !_resolution.containsKey(host) && _inFlight.add(host);

/// Publishes the outcome of a lookup to every row waiting on [host].
///
/// A null [url] means no candidate loaded, which is still an answer and stops
/// anyone trying again.
void recordFaviconResolution(
  String host, {
  required String? url,
  required double? luminance,
  Rect? bounds,
}) {
  _resolution[host] = url;
  _luminance[host] = luminance;
  _bounds[host] = bounds;
  _inFlight.remove(host);
}

/// The winning favicon URL for [host], if one has been resolved.
String? faviconUrlFor(String host) => _resolution[host];

/// Mean luminance of [host]'s favicon, if it has been measured.
double? faviconLuminanceFor(String host) => _luminance[host];

/// Opaque bounds of [host]'s favicon, if it has been measured.
Rect? faviconBoundsFor(String host) => _bounds[host];

/// Whether [host] has been looked up, successfully or not.
bool hasFaviconResolution(String host) => _resolution.containsKey(host);

/// Clears the shared state so one test cannot leak into the next.
@visibleForTesting
void resetFaviconResolutionsForTest() {
  _resolution.clear();
  _luminance.clear();
  _bounds.clear();
  _inFlight.clear();
}
