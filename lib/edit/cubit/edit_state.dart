part of 'edit_cubit.dart';

class const EditState({
  final Item? item,
  final TitleInput? title,
  final TextInput? text,
  final bool isValid = false,
  final bool preview = true,
  final bool success = false,
}) with EquatableMixin {
  factory fromMap(Map<String, dynamic> json) => EditState(
    item: json['item'] != null
        ? Item.fromMap(json['item'] as Map<String, dynamic>)
        : null,
    title: json['title'] != null
        ? TitleInput.pure(json['title'] as String)
        : null,
    text: json['text'] != null ? TextInput.pure(json['text'] as String) : null,
    isValid: json['isValid'] as bool? ?? false,
  );

  Map<String, dynamic> toMap() => <String, dynamic>{
    'item': item?.toMap(),
    'title': title?.value,
    'text': text?.value,
    'isValid': isValid,
  };

  EditState copyWith({
    Item Function()? item,
    TitleInput? Function()? title,
    TextInput? Function()? text,
    bool Function()? isValid,
    bool Function()? preview,
    bool Function()? success,
  }) => EditState(
    item: item != null ? item() : this.item,
    title: title != null ? title() : this.title,
    text: text != null ? text() : this.text,
    isValid: isValid != null ? isValid() : this.isValid,
    preview: preview != null ? preview() : this.preview,
    success: success != null ? success() : this.success,
  );

  @override
  List<Object?> get props => [item, title, text, isValid, preview, success];
}
