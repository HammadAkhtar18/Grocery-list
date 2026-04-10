import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  static const AndroidNotificationChannel _pantryChannel =
      AndroidNotificationChannel(
    'pantry_alerts',
    'Pantry Alerts',
    description: 'Alerts for low-stock and expiring pantry items',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) return;

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(initializationSettings);

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidImplementation?.createNotificationChannel(_pantryChannel);

    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await initialize();

    final androidImplementation = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    final granted =
        await androidImplementation?.requestNotificationsPermission();
    return granted ?? true;
  }

  Future<void> showNotificationsEnabledConfirmation() async {
    await initialize();
    await _plugin.show(
      1001,
      'Notifications enabled',
      'You will receive pantry alerts for low stock and expiring items.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _pantryChannel.id,
          _pantryChannel.name,
          channelDescription: _pantryChannel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }

  Future<void> showPantryStatusDigest({
    required int expiringSoonCount,
    required int lowStockCount,
  }) async {
    await initialize();

    final title = expiringSoonCount > 0 && lowStockCount > 0
        ? 'Pantry needs attention'
        : expiringSoonCount > 0
            ? 'Items expiring soon'
            : 'Low stock items';

    final parts = <String>[];
    if (expiringSoonCount > 0) {
      parts.add('$expiringSoonCount expiring soon');
    }
    if (lowStockCount > 0) {
      parts.add('$lowStockCount low stock');
    }

    await _plugin.show(
      1002,
      title,
      'Pantry update: ${parts.join(' and ')}.',
      NotificationDetails(
        android: AndroidNotificationDetails(
          _pantryChannel.id,
          _pantryChannel.name,
          channelDescription: _pantryChannel.description,
          importance: Importance.high,
          priority: Priority.high,
          styleInformation: BigTextStyleInformation(
            'Pantry update: ${parts.join(' and ')}. Open the app to review and take action.',
          ),
        ),
      ),
    );
  }
}
