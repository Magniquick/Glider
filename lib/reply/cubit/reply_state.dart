part of 'reply_cubit.dart';

class const ReplyState({
  final Item? parentItem,
  final TextInput text = const TextInput.pure(''),
  final bool isValid = false,
  final bool preview = true,
  final bool success = false,
}) with EquatableMixin {
  factory fromMap(Map<String, dynamic> json) => ReplyState(
    parentItem: json['parentItem'] != null
        ? Item.fromMap(json['parentItem'] as Map<String, dynamic>)
        : null,
    text: TextInput.pure(json['text'] as String? ?? ''),
    isValid: json['isValid'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'parentItem': parentItem?.toMap(),
    'text': text.value,
    'isValid': isValid,
  };

  ReplyState copyWith({
    Item Function()? parentItem,
    TextInput Function()? text,
    bool Function()? isValid,
    bool Function()? preview,
    bool Function()? success,
  }) => ReplyState(
    parentItem: parentItem != null ? parentItem() : this.parentItem,
    text: text != null ? text() : this.text,
    isValid: isValid != null ? isValid() : this.isValid,
    preview: preview != null ? preview() : this.preview,
    success: success != null ? success() : this.success,
  );

  @override
  List<Object?> get props => [parentItem, text, isValid, preview, success];
}
