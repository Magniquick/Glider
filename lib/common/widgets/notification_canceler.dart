import 'package:flutter/material.dart';

class const NotificationCanceler<T extends Notification>({
  super.key,
  required this.child,
}) extends StatelessWidget {
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return NotificationListener<T>(
      onNotification: (notification) => true,
      child: child,
    );
  }
}
