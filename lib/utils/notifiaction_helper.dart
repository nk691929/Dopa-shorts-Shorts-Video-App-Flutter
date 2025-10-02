// configure background service task 3
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

abstract class NotificationHelper {
  static final notification = FlutterLocalNotificationsPlugin();

  static initialize() async {
    InitializationSettings initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );
    notification.initialize(initializationSettings);
  }

  static show(int progress) async {
    NotificationDetails notificationDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        "upload_channel",
        "Upload Video",
        silent: true,
      ),
    );
    await notification.show(
      12,
      'Uploading',
      'Video is uploading $progress%',
      notificationDetails,
    );
  }
}
