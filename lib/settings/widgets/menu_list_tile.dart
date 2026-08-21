import 'package:flutter/material.dart';

class const MenuListTile<T>({
  required final Iterable<T> values,
  required final bool Function(T) selected,
  required final Widget Function(T) childBuilder,
  super.key,
  final Widget? title,
  final Widget? trailing,
  final bool enabled = true,
  final void Function(T)? onChanged,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => MenuAnchor(
    style: Theme.of(context).menuTheme.style
        ?.copyWith(alignment: AlignmentDirectional.bottomEnd),
    menuChildren: [
      for (final value in values)
        MenuItemButton(
          onPressed: () => onChanged?.call(value),
          leadingIcon: Visibility.maintain(
            visible: selected(value),
            child: const Icon(Icons.check_outlined),
          ),
          child: childBuilder(value),
        ),
    ],
    builder: (context, controller, child) => ListTile(
      title: title,
      trailing: trailing,
      enabled: enabled,
      onTap: () => controller.isOpen ? controller.close() : controller.open(),
    ),
  );
}
