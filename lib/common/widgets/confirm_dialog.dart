import 'package:flutter/material.dart';
import 'package:glider/l10n/extensions/app_localizations_extension.dart';
import 'package:go_router/go_router.dart';

typedef ConfirmDialogExtra = ({String? title, String? text});

class const ConfirmDialog({super.key, final String? title, final String? text})
    extends StatelessWidget {
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(title ?? context.l10n.confirm),
    content: text != null ? SingleChildScrollView(child: Text(text!)) : null,
    actions: [
      TextButton(
        onPressed: () => context.pop(false),
        child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
      ),
      TextButton(
        onPressed: () => context.pop(true),
        child: Text(MaterialLocalizations.of(context).okButtonLabel),
      ),
    ],
  );
}
