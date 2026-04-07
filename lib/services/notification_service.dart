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

    // Initialize local notifications
    if (!kIsWeb) {
      if (Platform.isWindows) {
        const windowsSettings = WindowsInitializationSettings(
          appName: 'Countdown Timer',
          appUserModelId: 'com.countdown.timer',
        );
        await _notifications.initialize(
          const InitializationSettings(windows: windowsSettings),
        );
      } else if (Platform.isAndroid) {
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
    if (!_initialized) return;

    try {
      NotificationDetails? details;

      if (!kIsWeb && Platform.isWindows) {
        details = const NotificationDetails(
          windows: WindowsNotificationDetails(),
        );
      } else if (!kIsWeb && Platform.isAndroid) {
        details = const NotificationDetails(
          android: AndroidNotificationDetails(
            'timer_finished',
            'Timer hoàn thành',
            channelDescription: 'Thông báo khi timer kết thúc',
            importance: Importance.high,
            priority: Priority.high,
          ),
        );
      } else if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        details = const NotificationDetails(
          iOS: DarwinNotificationDetails(),
          macOS: DarwinNotificationDetails(),
        );
      } else if (!kIsWeb && Platform.isLinux) {
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
