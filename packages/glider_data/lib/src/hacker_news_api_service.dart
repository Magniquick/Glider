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
