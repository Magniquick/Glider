import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:glider/common/constants/app_spacing.dart';
import 'package:glider/l10n/extensions/app_localizations_extension.dart';
import 'package:http/http.dart' as http;

class const FailureWidget({
  super.key,
  final String? title,
  final Object? exception,
  final VoidCallback? onRetry,
  final bool compact = false,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ListTile(
          title: Text(title ?? context.l10n.failure),
          subtitle: switch (exception) {
            final Object exception => Text(
              _describe(context, exception),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
            null => null,
          },
          trailing: compact && onRetry != null
              ? IconButton.outlined(
                  onPressed: onRetry,
                  style: IconButton.styleFrom(
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  icon: const Icon(Icons.refresh_outlined),
                )
              : null,
          textColor: Theme.of(context).colorScheme.error,
        ),
        if (!compact && onRetry != null)
          Padding(
            padding: AppSpacing.defaultTilePadding,
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onRetry,
                style: OutlinedButton.styleFrom(
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                label: Text(context.l10n.retry),
                icon: const Icon(Icons.refresh_outlined),
              ),
            ),
          ),
      ],
    ),
  );

  /// What went wrong, in words a reader can act on.
  ///
  /// A connection failure says to check the connection rather than naming a
  /// socket class. The app's own exceptions already describe themselves, and
  /// only something that does not falls back to its type.
  String _describe(BuildContext context, Object exception) =>
      switch (exception) {
        SocketException() ||
        HttpException() ||
        TlsException() ||
        TimeoutException() ||
        http.ClientException() => context.l10n.failureNetwork,
        _ when exception.toString().startsWith("Instance of '") =>
          exception.runtimeType.toString(),
        _ => exception.toString(),
      };
}
