import 'package:flutter/material.dart';

class const NotificationCanceler<T extends Notification>({
  required final Widget child,
  super.key,
}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) => NotificationListener<T>(
    onNotification: (notification) => true,
    child: child,
  );
}
