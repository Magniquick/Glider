part of 'stories_search_bloc.dart';

sealed class const StoriesSearchEvent() with EquatableMixin;

final class const LoadStoriesSearchEvent() extends StoriesSearchEvent {
  @override
  List<Object?> get props => [];
}

final class const SetTextStoriesSearchEvent(final String? text)
    extends StoriesSearchEvent {
  @override
  List<Object?> get props => [text];
}

final class const SetSearchRangeStoriesSearchEvent(
  final SearchRange? searchRange,
) extends StoriesSearchEvent {
  @override
  List<Object?> get props => [searchRange];
}

final class const SetDateRangeStoriesSearchEvent(final DateTimeRange? dateRange)
    extends StoriesSearchEvent {
  @override
  List<Object?> get props => [dateRange];
}
