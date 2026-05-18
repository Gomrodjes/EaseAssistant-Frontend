import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/secure_storage.dart';
import 'device_token_service.dart';

const AndroidNotificationChannel _notificationChannel = AndroidNotificationChannel(
  'ease_assistant_notifications',
  'Ease Assistant Notifications',
  description: 'Canal principal para notificaciones operativas de Ease Assistant.',
  importance: Importance.high,
);

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    await Firebase.initializeApp();
  } catch (_) {
    return;
  }
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  FirebaseMessaging? _messaging;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  final DeviceTokenService _deviceTokenService = DeviceTokenService();

  bool _isInitialized = false;

  bool get _supportsPush {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<void> initialize() async {
    if (_isInitialized || !_supportsPush) return;

    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _messaging!.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      await _messaging!.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      await _configureLocalNotifications();
      await _cacheCurrentToken();

      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);
      _messaging!.onTokenRefresh.listen(_handleTokenRefresh);

      final initialMessage = await _messaging!.getInitialMessage();
      if (initialMessage != null) {
        _handleMessageOpenedApp(initialMessage);
      }

      _isInitialized = true;
      await syncTokenWithBackend();
    } catch (error) {
      debugPrint('FCM initialization skipped: $error');
    }
  }

  Future<void> syncTokenWithBackend() async {
    if (!_supportsPush || _messaging == null) return;

    try {
      final authToken = await SecureStorage.getToken();
      if (authToken == null || authToken.isEmpty) return;

      final fcmToken = await _messaging!.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      await SecureStorage.saveFcmToken(fcmToken);
      await _deviceTokenService.registerToken(
        token: fcmToken,
        platform: _platformLabel,
        deviceName: 'Flutter mobile app',
      );
    } catch (error) {
      debugPrint('Unable to sync FCM token: $error');
    }
  }

  Future<void> unregisterDeviceFromBackend() async {
    if (!_supportsPush || _messaging == null) return;

    try {
      final fcmToken =
          await SecureStorage.getFcmToken() ?? await _messaging!.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      await _deviceTokenService.unregisterToken(fcmToken);
      await SecureStorage.deleteFcmToken();
    } catch (error) {
      debugPrint('Unable to unregister FCM token: $error');
    }
  }

  Future<void> dispose() async {
    _deviceTokenService.dispose();
  }

  Future<void> _configureLocalNotifications() async {
    const androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInitializationSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidInitializationSettings,
      iOS: iosInitializationSettings,
    );

    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_notificationChannel);
  }

  Future<void> _cacheCurrentToken() async {
    final token = await _messaging!.getToken();
    if (token != null && token.isNotEmpty) {
      await SecureStorage.saveFcmToken(token);
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    final androidDetails = AndroidNotificationDetails(
      _notificationChannel.id,
      _notificationChannel.name,
      channelDescription: _notificationChannel.description,
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails();

    await _localNotifications.show(
      notification.hashCode,
      notification.title,
      notification.body,
      NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      ),
      payload: message.data.toString(),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('Notification opened with payload: ${message.data}');
  }

  Future<void> _handleTokenRefresh(String token) async {
    await SecureStorage.saveFcmToken(token);
    await syncTokenWithBackend();
  }

  String get _platformLabel {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'ANDROID';
      case TargetPlatform.iOS:
        return 'IOS';
      default:
        return 'UNSUPPORTED';
    }
  }
}
