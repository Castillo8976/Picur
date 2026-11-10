import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  final plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      iOS: DarwinInitializationSettings(),
    );
    await plugin.initialize(settings);
    await plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> alert(String state) async {
    await plugin.show(
      1,
      'PICUR · $state',
      'El estado del sistema cambió a $state.',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'picur_alerts',
          'Alertas de sensores',
          channelDescription: 'Cambios de estado de las métricas IoT',
          importance: Importance.max,
          priority: Priority.high,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
