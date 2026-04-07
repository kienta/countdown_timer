import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final AudioPlayer _player = AudioPlayer();
  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    if (!kIsWeb) {
      try {
        if (Platform.isAndroid) {
          const androidSettings =
              AndroidInitializationSettings('@mipmap/ic_launcher');
          await _notifications.initialize(
            const InitializationSettings(android: androidSettings),
          );
        } else if (Platform.isIOS || Platform.isMacOS) {
          const darwinSettings = DarwinInitializationSettings();
          await _notifications.initialize(
            const InitializationSettings(
              iOS: darwinSettings,
              macOS: darwinSettings,
            ),
          );
        } else if (Platform.isLinux) {
          const linuxSettings =
              LinuxInitializationSettings(defaultActionName: 'Open');
          await _notifications.initialize(
            const InitializationSettings(linux: linuxSettings),
          );
        }
        // Windows: flutter_local_notifications does not support Windows yet.
        // Audio alarm still works via audioplayers.
      } catch (e) {
        debugPrint('Failed to init notifications: $e');
      }
    }

    _initialized = true;
  }

  Future<void> playAlarm() async {
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/alarm.wav'));
    } catch (e) {
      debugPrint('Failed to play alarm: $e');
    }
  }

  Future<void> showTimerFinishedNotification({
    required int id,
    required String title,
  }) async {
    if (!_initialized || kIsWeb) return;

    try {
      // Skip notification on Windows (not supported by flutter_local_notifications)
      if (Platform.isWindows) return;

      NotificationDetails? details;

      if (Platform.isAndroid) {
        details = const NotificationDetails(
          android: AndroidNotificationDetails(
            'timer_finished',
            'Timer hoàn thành',
            channelDescription: 'Thông báo khi timer kết thúc',
            importance: Importance.high,
            priority: Priority.high,
          ),
        );
      } else if (Platform.isIOS || Platform.isMacOS) {
        details = const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        );
      } else if (Platform.isLinux) {
        details = const NotificationDetails(
          linux: LinuxNotificationDetails(),
        );
      }

      if (details != null) {
        await _notifications.show(
          id,
          'Hết giờ!',
          '$title đã hoàn thành',
          details,
        );
      }
    } catch (e) {
      debugPrint('Failed to show notification: $e');
    }
  }

  void dispose() {
    _player.dispose();
  }
}
