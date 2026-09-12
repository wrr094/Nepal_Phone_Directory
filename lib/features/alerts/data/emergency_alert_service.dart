import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmergencyAlert {
  const EmergencyAlert({
    required this.title,
    required this.body,
    required this.sourceName,
    required this.sourceUrl,
    required this.receivedAt,
  });

  final String title;
  final String body;
  final String sourceName;
  final String sourceUrl;
  final DateTime receivedAt;

  Map<String, String> toJson() => {
    'title': title,
    'body': body,
    'source_name': sourceName,
    'source_url': sourceUrl,
    'received_at': receivedAt.toIso8601String(),
  };

  factory EmergencyAlert.fromJson(Map<String, Object?> value) {
    return EmergencyAlert(
      title: value['title']?.toString() ?? 'Emergency alert',
      body: value['body']?.toString() ?? '',
      sourceName: value['source_name']?.toString() ?? 'Nepal HelpLine',
      sourceUrl: value['source_url']?.toString() ?? '',
      receivedAt:
          DateTime.tryParse(value['received_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }
}

class EmergencyAlertService {
  EmergencyAlertService._();

  static final instance = EmergencyAlertService._();

  static const topic = 'national_alerts';
  static const _enabledKey = 'national_emergency_alerts_enabled';
  static const _latestAlertKey = 'national_emergency_alert_latest';
  static const _channelId = 'national_emergency_alerts';

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    const channel = AndroidNotificationChannel(
      _channelId,
      'National emergency alerts',
      description: 'Urgent public-safety notices from Nepal HelpLine.',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await _notifications.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        ),
      ),
    );
    await _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.createNotificationChannel(channel);
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
    _initialized = true;
  }

  Future<bool> isEnabled() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getBool(_enabledKey) ?? false;
  }

  Future<bool> setEnabled(bool enabled) async {
    if (enabled) {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final allowed =
          settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;
      if (!allowed) return false;
      await FirebaseMessaging.instance.subscribeToTopic(topic);
    } else {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
    }
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_enabledKey, enabled);
    return enabled;
  }

  Future<EmergencyAlert?> latestAlert() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString(_latestAlertKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, Object?>) return null;
      return EmergencyAlert.fromJson(decoded);
    } catch (_) {
      return null;
    }
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    if (!await isEnabled()) return;
    final alert = _alertFromMessage(message);
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_latestAlertKey, jsonEncode(alert.toJson()));
    await _notifications.show(
      id: DateTime.now().millisecondsSinceEpoch.remainder(1 << 31),
      title: alert.title,
      body: alert.body,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          'National emergency alerts',
          channelDescription:
              'Urgent public-safety notices from Nepal HelpLine.',
          importance: Importance.max,
          priority: Priority.max,
          playSound: true,
          enableVibration: true,
        ),
        iOS: DarwinNotificationDetails(presentAlert: true, presentSound: true),
      ),
    );
  }

  EmergencyAlert _alertFromMessage(RemoteMessage message) {
    final notification = message.notification;
    return EmergencyAlert(
      title:
          notification?.title ??
          message.data['title']?.toString() ??
          'Emergency alert',
      body: notification?.body ?? message.data['body']?.toString() ?? '',
      sourceName: message.data['source_name']?.toString() ?? 'Nepal HelpLine',
      sourceUrl: message.data['source_url']?.toString() ?? '',
      receivedAt: DateTime.now(),
    );
  }
}
