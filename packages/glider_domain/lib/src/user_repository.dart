import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:glider_data/glider_data.dart';
import 'package:glider_domain/src/entities/user.dart';
import 'package:glider_domain/src/extensions/behavior_subject_map_extension.dart';
import 'package:rxdart/subjects.dart';

class UserRepository(final HackerNewsApiService _hackerNewsApiService) {
  this : _userStreamControllers = {};

  final Map<String, BehaviorSubject<User>> _userStreamControllers;

  Stream<User> getUserStream(String username) => _userStreamControllers
      .getOrAdd(username, asyncSeed: () => getUser(username))
      .stream;

  Future<User> getUser(String username) async {
    try {
      final dto = await _hackerNewsApiService.getUser(username);
      final user = await compute(User.fromDto, dto);
      _userStreamControllers.getOrAdd(username).add(user);
      return user;
    } on Object catch (e, st) {
      _userStreamControllers.getOrAdd(username).addError(e, st);
      rethrow;
    }
  }
}
