part of 'stories_search_bloc.dart';

sealed class const StoriesSearchEvent() with EquatableMixin;

final class const LoadStoriesSearchEvent() extends StoriesSearchEvent {
  @override
  List<Object?> get props => [];
}

final class const SetTextStoriesSearchEvent(this.text)
    extends StoriesSearchEvent {
  final String? text;

  @override
  List<Object?> get props => [text];
}

final class const SetSearchRangeStoriesSearchEvent(this.searchRange)
    extends StoriesSearchEvent {
  final SearchRange? searchRange;

  @override
  List<Object?> get props => [searchRange];
}

final class const SetDateRangeStoriesSearchEvent(this.dateRange)
    extends StoriesSearchEvent {
  final DateTimeRange? dateRange;

  @override
  List<Object?> get props => [dateRange];
}
