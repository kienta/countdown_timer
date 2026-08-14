import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui' show PlatformDispatcher;

import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:tray_manager/tray_manager.dart';
import 'package:window_manager/window_manager.dart';

import 'models/timer_model.dart';
import 'services/timer_service.dart';
import 'theme/app_theme.dart';
import 'utils/app_logger.dart';
import 'screens/launcher_screen.dart';
import 'screens/widget_view.dart';

void main(List<String> args) {
  final isSubWindow =
      args.firstOrNull == 'multi_window' &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);
  final scope = isSubWindow ? 'widget:${args.length > 1 ? args[1] : '?'}' : 'main';

  // Run everything inside a guarded zone so uncaught async errors are logged.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await AppLogger.instance.init(scope: scope);

    // Route Flutter framework errors and low-level platform errors to the log.
    final previousOnError = FlutterError.onError;
    FlutterError.onError = (details) {
      AppLogger.instance.error(
        'FlutterError: ${details.exceptionAsString()}',
        details.exception,
        details.stack,
        {'library': details.library ?? '-'},
      );
      previousOnError?.call(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      AppLogger.instance.error('PlatformDispatcher error', error, stack);
      return true;
    };

    if (isSubWindow) {
      await _runWidgetWindow(args);
    } else {
      await _runMainWindow();
    }
  }, (error, stack) {
    AppLogger.instance.error('Uncaught zone error', error, stack);
  });
}

/// Lightweight floating widget sub-window. Holds NO timer logic — the main
/// window is the single source of truth and pushes state via IPC.
Future<void> _runWidgetWindow(List<String> args) async {
  final windowId = int.parse(args[1]);
  final argsMap = args[2].isEmpty
      ? <String, dynamic>{}
      : jsonDecode(args[2]) as Map<String, dynamic>;
  final timerId = argsMap['timerId'] as int? ?? 0;
  final timerMap = argsMap['timer'] as Map<String, dynamic>?;
  final initial = timerMap != null
      ? TimerModel.fromMap(timerMap)
      : TimerModel(id: timerId, title: argsMap['title'] as String? ?? 'Timer');

  AppLogger.instance.info('Widget window opening',
      {'windowId': windowId, 'timerId': timerId, 'title': initial.title});

  // NOTE: the sub-window is made frameless + always-on-top + draggable
  // NATIVELY (see windows/runner/flutter_window.cpp `StyleAsWidget`). We must
  // NOT use `window_manager` here: it isn't registered on sub-window engines,
  // and using it across multiple engines corrupts its native state and crashes
  // the app. Sizing/showing is done by the main window via WindowController.

  // The main window is the single source of truth and pushes live state here
  // via the 'update' method. The widget is read-only: its close button shuts
  // its own native window directly (no reverse channel needed), and the main
  // window notices the gone window on its next reconcile pass.
  final notifier = ValueNotifier<TimerModel>(initial);
  DesktopMultiWindow.setMethodHandler((call, fromWindowId) async {
    try {
      switch (call.method) {
        case 'update':
          final map = jsonDecode(call.arguments as String) as Map<String, dynamic>;
          notifier.value = TimerModel.fromMap(map);
          return null;
      }
    } catch (e, st) {
      AppLogger.instance.error('Widget handler failed', e, st,
          {'method': call.method});
    }
    return null;
  });

  runApp(WidgetApp(
    notifier: notifier,
    windowToken: 'cdtwidget_$windowId',
  ));
}

/// The main application window.
Future<void> _runMainWindow() async {
  final isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  if (isDesktop) {
    await windowManager.ensureInitialized();
    await windowManager.setTitle('Countdown Timer');
    await windowManager.setMinimumSize(const Size(400, 300));
    await windowManager.setPreventClose(true);
  }

  final timerService = TimerService();
  await timerService.init();
  AppLogger.instance.info('Main window ready',
      {'timers': timerService.timers.length});

  // WIDGET_SELFTEST=<n> auto-opens n widgets (used to stress-test the
  // multi-window sync). Any positive integer works; '1' keeps its old meaning.
  final selfTestCount = int.tryParse(
          Platform.environment['WIDGET_SELFTEST'] ?? '') ??
      0;
  if (isDesktop && selfTestCount > 0) {
    Future.delayed(const Duration(seconds: 2), () async {
      for (var i = 0; i < selfTestCount; i++) {
        final t = await timerService.createTimer(
            title: 'SelfTest $i', mode: 'duration', totalSeconds: 600);
        final w = await DesktopMultiWindow.createWindow(jsonEncode({
          'timerId': t.id,
          'title': t.title,
          'timer': t.toMap(),
        }));
        w
          ..setFrame(Offset(80 + (i % 6) * 90, 80 + (i ~/ 6) * 200) &
              const Size(272, 182))
          ..setTitle('cdtwidget_${w.windowId}')
          ..show();
        timerService.registerWidget(t.id, w.windowId);
        timerService.startTimer(t.id);
        AppLogger.instance.info('selftest: opened widget $i',
            {'timerId': t.id, 'windowId': w.windowId});
        await Future.delayed(const Duration(milliseconds: 600));
      }
      AppLogger.instance.info('selftest: all $selfTestCount widgets opened');
    });
  }

  runApp(
    ChangeNotifierProvider.value(
      value: timerService,
      child: const CountdownTimerApp(),
    ),
  );
}

class CountdownTimerApp extends StatefulWidget {
  const CountdownTimerApp({super.key});

  @override
  State<CountdownTimerApp> createState() => _CountdownTimerAppState();
}

class _CountdownTimerAppState extends State<CountdownTimerApp>
    with WindowListener, TrayListener {
  @override
  void initState() {
    super.initState();
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.addListener(this);
      trayManager.addListener(this);
      _initTray();
    }
  }

  @override
  void dispose() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      windowManager.removeListener(this);
      trayManager.removeListener(this);
    }
    super.dispose();
  }

  Future<void> _initTray() async {
    String iconPath;
    if (Platform.isWindows) {
      final exeDir = File(Platform.resolvedExecutable).parent.path;
      iconPath = '$exeDir\\app_icon.ico';
    } else {
      iconPath = 'assets/app_icon.png';
    }

    await trayManager.setIcon(iconPath);
    await trayManager.setToolTip('Countdown Timer');

    final menu = Menu(items: [
      MenuItem(key: 'show', label: 'Mở Countdown Timer'),
      MenuItem.separator(),
      MenuItem(key: 'exit', label: 'Thoát'),
    ]);
    await trayManager.setContextMenu(menu);
  }

  // WindowListener: intercept close → hide to tray
  @override
  void onWindowClose() async {
    await windowManager.hide();
  }

  // TrayListener: handle tray menu clicks
  @override
  void onTrayMenuItemClick(MenuItem menuItem) async {
    switch (menuItem.key) {
      case 'show':
        await windowManager.show();
        await windowManager.focus();
        break;
      case 'exit':
        // Close widget sub-windows first — otherwise they keep the process
        // alive and the app appears to "not close".
        await context.read<TimerService>().closeAllWidgets();
        await trayManager.destroy();
        await windowManager.setPreventClose(false);
        await windowManager.destroy();
        // Guarantee the process terminates even if a window/engine lingers.
        exit(0);
    }
  }

  // TrayListener: double-click tray icon → show window
  @override
  void onTrayIconMouseDown() async {
    await windowManager.show();
    await windowManager.focus();
  }

  @override
  void onTrayIconRightMouseDown() async {
    await trayManager.popUpContextMenu();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Countdown Timer',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const LauncherScreen(),
    );
  }
}
