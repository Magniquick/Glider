import 'package:flutter_test/flutter_test.dart';
import 'package:glider/reply/cubit/reply_cubit.dart';
import 'package:glider/reply/models/text_input.dart';
import 'package:glider_domain/glider_domain.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

/// Mirrors [ReplyCubit]'s persistence wiring without its repositories, so that
/// the state's own serialisation is what gets exercised.
class _ReplyStateCubit() extends HydratedCubit<ReplyState> {
  this : super(const ReplyState());

  void put(ReplyState state) => emit(state);

  @override
  ReplyState? fromJson(Map<String, dynamic> json) => ReplyState.fromMap(json);

  @override
  Map<String, dynamic>? toJson(ReplyState state) => state.toMap();
}

class _InMemoryStorage() implements Storage {
  final _store = <String, Object?>{};

  @override
  Object? read(String key) => _store[key];

  @override
  Future<void> write(String key, Object? value) async {
    _store[key] = value;
  }

  @override
  Future<void> delete(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> clear() async {
    _store.clear();
  }

  @override
  Future<void> close() async {}
}

void main() {
  final parentItem = Item(
    id: 42,
    type: ItemType.comment,
    username: 'someone',
    text: 'parent text',
  );

  setUp(() => HydratedBloc.storage = _InMemoryStorage());

  test('keeps emitting once a parent item is known', () {
    final cubit = _ReplyStateCubit()
      ..put(const ReplyState().copyWith(parentItem: () => parentItem));

    expect(
      () => cubit.put(
        cubit.state.copyWith(
          text: () => const TextInput.dirty('hello'),
          isValid: () => true,
        ),
      ),
      returnsNormally,
    );
    expect(cubit.state.isValid, isTrue);
  });

  test('round-trips a parent item through storage', () {
    _ReplyStateCubit().put(
      const ReplyState().copyWith(parentItem: () => parentItem),
    );

    expect(_ReplyStateCubit().state.parentItem, parentItem);
  });
}
