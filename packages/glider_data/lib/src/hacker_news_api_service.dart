import 'dart:convert';

import 'package:glider_data/src/dtos/item_dto.dart';
import 'package:glider_data/src/dtos/user_dto.dart';
import 'package:http/http.dart' as http;

// Decoding is done inline rather than with `compute`. These responses are a
// single item, user or id list -- a few kilobytes at most -- and spawning an
// isolate per call costs more than the decode does, while copying the payload
// across the boundary twice. The genuinely large parses (whole Hacker News
// pages) still use `compute`, in HackerNewsWebsiteService.
class const HackerNewsApiService(final http.Client _client) {
  static const authority = 'hacker-news.firebaseio.com';

  Future<List<int>> getTopStoryIds() => _getIds('v0/topstories.json');

  Future<List<int>> getNewStoryIds() => _getIds('v0/newstories.json');

  Future<List<int>> getBestStoryIds() => _getIds('v0/beststories.json');

  Future<List<int>> getAskStoryIds() => _getIds('v0/askstories.json');

  Future<List<int>> getShowStoryIds() => _getIds('v0/showstories.json');

  Future<List<int>> getJobStoryIds() => _getIds('v0/jobstories.json');

  Future<List<int>> _getIds(String path) async {
    final response = await _client.get(Uri.https(authority, path));
    final list = jsonDecode(response.body) as List<dynamic>;
    return list.map((e) => e as int).toList(growable: false);
  }

  Future<ItemDto> getItem(int id) async {
    final path = 'v0/item/$id.json';
    final response = await _client.get(Uri.https(authority, path));
    return ItemDto.fromMap(jsonDecode(response.body) as Map<String, dynamic>);
  }

  Future<UserDto> getUser(String id) async {
    final path = 'v0/user/$id.json';
    final response = await _client.get(Uri.https(authority, path));
    return UserDto.fromMap(jsonDecode(response.body) as Map<String, dynamic>);
  }
}
