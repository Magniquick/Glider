import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:glider/common/extensions/bloc_base_extension.dart';
import 'package:glider/common/mixins/data_mixin.dart';
import 'package:glider/common/mixins/paginated_list_mixin.dart';
import 'package:glider/common/models/status.dart';
import 'package:glider/stories/models/story_type.dart';
import 'package:glider_domain/glider_domain.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'stories_state.dart';

class StoriesCubit(final ItemRepository _itemRepository)
    extends HydratedCubit<StoriesState> {
  this : super(StoriesState());

  @override
  String id = StoryType.topStories.name;

  Future<void> load() async {
    safeEmit(
      state.copyWith(
        status: () => Status.loading,
        page: () => 1,
        exception: () => null,
      ),
    );

    try {
      final page = await _itemRepository.getStories(state.storyType.path);
      safeEmit(
        state.copyWith(
          status: () => Status.success,
          data: () => [for (final item in page.items) item.id],
          hasMore: () => page.hasMore,
        ),
      );
    } on Object catch (exception) {
      safeEmit(
        state.copyWith(
          status: () => Status.failure,
          exception: () => exception,
        ),
      );
    }
  }

  Future<void> showMore() async {
    final int nextPage = state.page + 1;
    safeEmit(
      state.copyWith(status: () => Status.loading, exception: () => null),
    );

    try {
      final page = await _itemRepository.getStories(
        state.storyType.path,
        page: nextPage,
      );
      safeEmit(
        state.copyWith(
          status: () => Status.success,
          // Hacker News reranks between requests, so a story can appear on two
          // consecutive pages. A set keeps insertion order while dropping the
          // repeat, which would otherwise render twice.
          data: () => <int>{
            ...?state.data,
            for (final item in page.items) item.id,
          }.toList(growable: false),
          page: () => nextPage,
          hasMore: () => page.hasMore,
        ),
      );
    } on Object catch (exception) {
      safeEmit(
        state.copyWith(
          status: () => Status.failure,
          exception: () => exception,
        ),
      );
    }
  }

  Future<void> setStoryType(StoryType storyType) async {
    id = storyType.name;
    safeEmit(state.copyWith(storyType: () => storyType));
    await load();
  }

  @override
  StoriesState? fromJson(Map<String, dynamic> json) =>
      StoriesState.fromMap(json);

  @override
  Map<String, dynamic>? toJson(StoriesState state) =>
      state.status == Status.success ? state.toMap() : null;
}
