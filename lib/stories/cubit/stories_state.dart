part of 'stories_cubit.dart';

class StoriesState({
  @override final Status status = Status.initial,
  @override final List<int>? data,
  @override final int page = 1,
  final StoryType storyType = StoryType.topStories,
  @override final Object? exception,
}) with DataMixin<List<int>>, PaginatedListMixin, EquatableMixin {
  factory fromMap(Map<String, dynamic> json) => StoriesState(
    status: Status.values.byName(json['status'] as String),
    data: (json['data'] as List<dynamic>?)
        ?.map((e) => e as int)
        .toList(growable: false),
    storyType: StoryType.values.byName(json['storyType'] as String),
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'status': status.name,
    'data': data,
    'storyType': storyType.name,
  };

  @override
  late final List<int>? loadedData = super.loadedData?.toList(growable: false);

  @override
  late final List<int>? currentPageData = super.currentPageData?.toList(
    growable: false,
  );

  StoriesState copyWith({
    Status Function()? status,
    List<int>? Function()? data,
    int Function()? page,
    StoryType Function()? storyType,
    Object? Function()? exception,
  }) => StoriesState(
    status: status != null ? status() : this.status,
    data: data != null ? data() : this.data,
    page: page != null ? page() : this.page,
    storyType: storyType != null ? storyType() : this.storyType,
    exception: exception != null ? exception() : this.exception,
  );

  // loadedData and currentPageData are memoised derivations of data and page,
  // which are already compared below.
  @override
  List<Object?> get props => [status, data, page, storyType, exception];
}
