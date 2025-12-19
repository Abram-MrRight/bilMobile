import 'package:flutter/material.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

Future<bool> showNotificationPermissionDialog(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: Text('Enable Notifications'),
      content: Text(
        'We’d like to send you notifications about new messages and important updates. '
        'You can change your preferences anytime in settings.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text('No Thanks'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text('Allow Notifications'),
        ),
      ],
    ),
  ) ?? false;
}

Future<void> requestPushNotificationPermission(BuildContext context) async {
  bool userAgreed = await showNotificationPermissionDialog(context);

  if (userAgreed) {
    await OneSignal.Notifications.requestPermission(true);
  } else {
    print('User declined notification permission');
  }
}
