import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static NotificationService? _instance;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._();

  static NotificationService get instance {
    _instance ??= NotificationService._();
    return _instance!;
  }

  Future<void> initialize() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _localNotifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  void showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) {
    _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'auto_monpoto_channel',
          'Auto Monpoto',
          channelDescription: 'Notifications de l\'application',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      payload: payload,
    );
  }
}
