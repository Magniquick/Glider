import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:formz/formz.dart';
import 'package:glider/common/extensions/bloc_base_extension.dart';
import 'package:glider/edit/models/text_input.dart';
import 'package:glider/edit/models/title_input.dart';
import 'package:glider_domain/glider_domain.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

part 'edit_state.dart';

class EditCubit(
  final ItemRepository _itemRepository,
  final ItemInteractionRepository _itemInteractionRepository, {
  required int id,
}) extends HydratedCubit<EditState> {
  this : super(const EditState()) {
    _itemSubscription = _itemRepository
        .getItemStream(itemId)
        .listen(
          (item) => safeEmit(
            state.copyWith(
              item: () => item,
              title: state.title == null && item.title != null
                  ? () => TitleInput.dirty(item.title!)
                  : null,
              text: state.text == null && item.text != null
                  ? () => TextInput.dirty(item.text!)
                  : null,
            ),
          ),
        );
  }

  final int itemId = id;

  late final StreamSubscription<Item> _itemSubscription;

  @override
  String get id => itemId.toString();

  void setTitle(String title) {
    final titleInput = TitleInput.dirty(title);
    safeEmit(
      state.copyWith(
        title: () => titleInput,
        isValid: () => Formz.validate([titleInput, ?state.text]),
      ),
    );
  }

  void setText(String text) {
    final textInput = TextInput.dirty(text);
    safeEmit(
      state.copyWith(
        text: () => textInput,
        isValid: () => Formz.validate([?state.title, textInput]),
      ),
    );
  }

  void setPreview(bool preview) {
    safeEmit(state.copyWith(preview: () => preview));
  }

  Future<void> edit() async {
    final bool success = await _itemInteractionRepository.edit(
      itemId,
      title: state.title?.value,
      text: state.text?.value,
    );
    safeEmit(
      success
          ? const EditState(success: true)
          : state.copyWith(success: () => false),
    );
  }

  @override
  EditState? fromJson(Map<String, dynamic> json) => EditState.fromMap(json);

  @override
  Map<String, dynamic>? toJson(EditState state) => state.toMap();

  @override
  Future<void> close() async {
    await _itemSubscription.cancel();
    return await super.close();
  }
}
