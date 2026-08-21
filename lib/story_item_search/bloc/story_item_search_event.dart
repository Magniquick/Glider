part of 'story_item_search_bloc.dart';

sealed class const StoryItemSearchEvent() with EquatableMixin;

final class const LoadStoryItemSearchEvent() extends StoryItemSearchEvent {
  @override
  List<Object?> get props => [];
}

final class const SetTextStoryItemSearchEvent(this.text)
    extends StoryItemSearchEvent {
  final String? text;

  @override
  List<Object?> get props => [text];
}
