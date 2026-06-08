import 'package:flutter_inertia/flutter_inertia.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationController {
  static final _plugin = FlutterLocalNotificationsPlugin();
  static bool _initialized = false;

  static Future<void> _init() async {
    if (_initialized) return;
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: iOS),
    );
    _initialized = true;
  }

  static Future<String> index() async {
    return Inertia.render(
      component: 'Notification/Index',
      props: {},
      url: '/notification',
    );
  }

  static Future<String> send(dynamic req) async {
    final body = req.body as Map<String, dynamic>;
    final text = (body['text'] as String? ?? '').trim();

    if (text.isEmpty) {
      return Inertia.render(
        component: 'Notification/Index',
        props: {'error': 'Please enter some text'},
        url: '/notification',
      );
    }

    await _init();
    await _plugin.show(
      id: 0,
      title: 'New Notification',
      body: text,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'default',
          'Default',
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );

    return Inertia.render(
      component: 'Notification/Index',
      props: {'sent': true},
      url: '/notification',
    );
  }
}
