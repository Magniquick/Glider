import 'package:flutter_test/flutter_test.dart';
import 'package:glider/item/extensions/item_extension.dart';
import 'package:glider_domain/glider_domain.dart';

Item _story(String? title) => Item(id: 1, type: ItemType.story, title: title);

void main() {
  group('prefix', () {
    test('captures both words of a two-word tag', () {
      expect(
        _story('Show HN: Running 104GB Qwen3.8-Flash-Next').prefix,
        'Show HN',
      );
      expect(_story('Launch HN: Nori Robotics').prefix, 'Launch HN');
      expect(_story('Ask HN: Who is hiring?').prefix, 'Ask HN');
      expect(_story('Poll: Which editor?').prefix, 'Poll');
    });

    test('is stripped from the displayed title', () {
      expect(
        _story('Show HN: Running 104GB Qwen3.8-Flash-Next').filteredTitle,
        'Running 104GB Qwen3.8-Flash-Next',
      );
    });

    test('ignores a colon that is not a tag', () {
      expect(_story('Rust 1.90: what changed').prefix, isNull);
    });
  });

  test('suffix is lowercased', () {
    expect(_story('A talk about Dart [Video]').suffix, 'video');
  });

  test('original date and YC batch are picked out', () {
    expect(_story('An old post (2011)').originalDate, '2011');
    expect(_story('Quill is hiring (YC W20)').ycBatch, 'YC W20');
  });

  test('a title-less item has no tags', () {
    final Item untitled = _story(null);
    expect(untitled.prefix, isNull);
    expect(untitled.suffix, isNull);
    expect(untitled.originalDate, isNull);
    expect(untitled.ycBatch, isNull);
    expect(untitled.filteredTitle, isNull);
  });
}
