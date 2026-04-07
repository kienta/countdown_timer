import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/timer_service.dart';
import 'theme/app_theme.dart';
import 'screens/launcher_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final timerService = TimerService();
  await timerService.init();

  runApp(
    ChangeNotifierProvider.value(
      value: timerService,
      child: const CountdownTimerApp(),
    ),
  );
}

class CountdownTimerApp extends StatelessWidget {
  const CountdownTimerApp({super.key});

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
