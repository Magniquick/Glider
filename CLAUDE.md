# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

Glider is an opinionated Hacker News client in Flutter. This checkout is a fork
(`fork` remote, Magniquick/Glider) of `origin` (Mosc/Glider). It ships Android
APKs from GitHub Releases; it does not publish to F-Droid or the Play Store, so
fastlane metadata under `fastlane/` is inherited and unused.

## Commands

The toolchain is pinned in `mise.toml`, so prefix everything with `mise exec --`
unless mise is already active. `PUB_CACHE` is redirected into the repo.

```sh
mise install                       # pinned Flutter, JDK, Android SDK
flutter pub get                    # resolves the pub workspace (app + both packages)

dart run melos run lint            # analyze + format-check, what CI runs
dart run melos run test            # app tests then package tests
dart run melos run format          # dart format .

flutter test test/some_test.dart                    # one file
flutter test test/some_test.dart --plain-name '...' # one test
cd packages/glider_domain && flutter test           # one package
```

`melos run test` exists because pub workspaces exclude the root package from
melos' package list, so `test:app` and `test:packages` have to run separately.
Likewise `melos run analyze` runs `dart analyze .` once from the root rather
than per package.

Running the app: `flutter run` (debug installs as `nl.viter.glider.debug`, so it
sits beside a release install). Platforms present are `android`, `ios`, `macos`
and `linux`; CI builds only Android and iOS. The Linux target exists mainly
because the Dart VM service can be driven from a script there, which is how the
performance work was measured.

Release builds need `android/key.properties`. Without it a local build falls
back to the debug key and CI fails outright rather than producing an unsigned
artifact.

## Dart dialect

This code uses **declaring constructors** (Dart 3.13), which look unlike normal
Dart and are enforced by the `use_declaring_parameters` and
`use_primary_constructors` lints. Match the surrounding style:

```dart
class const ItemDto({required final int id, final String? by}) {
  /// Doc comment for the constructor itself.
  this;
}

class ItemTreeCubit(final ItemRepository _itemRepository, {required int id})
    extends HydratedCubit<ItemTreeState> {
  this : super(ItemTreeState());   // initializer list
  final int itemId = id;           // capture a constructor parameter as a field
}
```

Declare the parameter rather than referring to a separately declared field:
`(final String action)` creates the field, whereas `(this.action)` plus a
`final String action;` in the body trips `use_declaring_parameters`. Put the
doc comment on the parameter. Keep a `this;` body only when the constructor
itself needs documenting.

`analysis_options.yaml` enables essentially every stable lint. The ones that
bite most: 80-column lines, `public_member_api_docs`, `prefer_single_quotes`,
`require_trailing_commas`, `avoid_catches_without_on_clauses` (write
`on Object catch`), and the pair `specify_nonobvious_local_variable_types` /
`omit_obvious_local_variable_types`. Run `dart format` before analyzing;
`melos run lint` fails on a formatting diff. Infos are not fatal, warnings are
not fatal (`--no-fatal-warnings`), errors are.

`leancode_lint` runs as an analysis-server plugin, and plugin diagnostics honour
neither `// ignore:` comments nor `analyzer: errors:`. A few
`missing_equatable_props` reports are known false positives.

## Architecture

Three layers, wired by constructor injection with no service locator.

```
packages/glider_data     services + DTOs, one class per remote source
packages/glider_domain   repositories + entities, the only layer above knows
lib/                     features, each with cubit/ bloc/ view/ widgets/ models/
```

`lib/app/container/app_container.dart` is the composition root: it builds every
service, repository and cubit factory in one function. Adding a dependency to a
repository means editing that file. `lib/app/container/http_client.dart` builds
the single `http.Client` every service receives.

Routing is go_router in `lib/app/router/app_router.dart`, one `GoRoute` per
`AppRoute` enum case.

### Where data comes from

Three remotes, and which one is used is a deliberate choice per feature:

- **news.ycombinator.com HTML** (`HackerNewsWebsiteService`) is the primary read
  path. It serves comment trees, story lists, login, voting, favoriting,
  flagging, editing and submitting. Threads and story lists are parsed from HTML
  because the Firebase API cannot return a thread at all: a comment carries a
  `parent` but nothing identifying its story, so a tree there costs one request
  per comment. Ordering is the reason this is preferred over Algolia's
  single-request tree endpoint, whose children are chronological while Hacker
  News ranks them.
- **hacker-news.firebaseio.com** (`HackerNewsApiService`) is now only user
  profiles, individual items not already in memory, and post-vote refreshes.
- **hn.algolia.com** (`AlgoliaApiService`) is search, catch-up, similar stories
  and inbox replies.

### The two patterns that cause real bugs

**Seeding, and the emit ordering around it.** `ItemRepository` keeps a
`Map<int, BehaviorSubject<Item>>`, and `getItemStream(id)` calls
`getOrAdd(id, asyncSeed: () => getItem(id))`. The async seed only fires when the
key is absent, so putting an item into the map *before* the UI can build a row
for it is what stops every row fetching itself from the API. This is why
`StoriesCubit` fetches and seeds a page before it emits the ids, and why
`ItemRepository` seeds each chunk before yielding descendants. Emitting ids
first still works, just with tens or thousands of extra requests, so the failure
is silent and only visible in a request count.

**`yield*` inside `async*` does not throw into the enclosing `try`.** It
forwards a delegated stream's errors straight to the listener, which has already
made two separate fallbacks unreachable in this codebase. Use `await for` and
re-yield when you need to catch.

### State

Most cubits extend `HydratedCubit`, which persists on *every* emit by running
`toJson` and writing to Hive. A cubit that emits per item rather than per batch
will re-serialise its whole state each time; this was once 95.8 MB of JSON for
one thread. `lib/common/mixins/data_mixin.dart` gives every list state its
`Status`/`data`/`exception` shape and the `whenOrDefaultSlivers` rendering
switch, where an empty non-null list renders the empty state, so never emit `[]`
mid-stream for a list that is still filling.

### Vendored datasets

`assets/simple_icons/domains.json` and `assets/public_suffix_list.dat` are
generated by `tool/update_*.py` via `melos run update-datasets`. This is
deliberately not part of a build, so that the same commit produces the same APK
on any day and builds work offline; a scheduled workflow refreshes them as a
reviewable pull request.

## Releases

The `Release` workflow triggers on `v*` tags but its build job is gated on an
`ANDROID_KEYSTORE_BASE64` secret this fork does not have, so it always skips.
Releases here are cut by hand, matching v2.9.x and v2.10.0:

```sh
flutter build apk --release --split-per-abi
git tag -a vX.Y.Z -m '...' && git push fork vX.Y.Z
gh release create vX.Y.Z --repo Magniquick/Glider --prerelease \
  --title 'vX.Y.Z: ...' --notes-file notes.md \
  build/app/outputs/flutter-apk/app-*-release.apk
```

Verify the APK signature matches the previous release before publishing, or
nobody can upgrade over an existing install:

```sh
apksigner verify --print-certs build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Push to `fork`, never `origin`.
