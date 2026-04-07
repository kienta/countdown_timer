import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/timer_model.dart';
import 'database_service.dart';

class TimerService extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  List<TimerModel> _timers = [];
  Timer? _tickTimer;
  int _tickCount = 0;

  List<TimerModel> get timers => _timers;

  int get runningCount => _timers.where((t) => t.running && !t.finished).length;

  Future<void> init() async {
    await _db.init();
    await loadTimers();
    _startTicking();
  }

  Future<void> loadTimers() async {
    _timers = await _db.getAllTimers();
    for (final t in _timers) {
      t.adjustForElapsedTime();
    }
    notifyListeners();
  }

  Future<TimerModel?> getTimer(int id) async {
    return _db.getTimer(id);
  }

  Future<TimerModel> createTimer({
    required String title,
    required String mode,
    required int totalSeconds,
    String? targetValue,
  }) async {
    final id = await _db.getNextId();
    final now = DateTime.now().millisecondsSinceEpoch;
    final timer = TimerModel(
      id: id,
      title: title.isEmpty ? 'Bộ đếm' : title,
      mode: mode,
      totalSeconds: totalSeconds,
      remainSeconds: totalSeconds,
      elapsedSecs: 0,
      targetValue: targetValue,
      running: false,
      finished: false,
      savedAt: now,
      createdAt: now,
    );
    await _db.upsertTimer(timer);
    _timers.insert(0, timer);
    notifyListeners();
    return timer;
  }

  Future<void> updateTimerConfig({
    required int id,
    required String title,
    required String mode,
    required int totalSeconds,
    String? targetValue,
  }) async {
    final idx = _timers.indexWhere((t) => t.id == id);
    if (idx < 0) return;

    final old = _timers[idx];
    final updated = TimerModel(
      id: id,
      title: title.isEmpty ? 'Bộ đếm' : title,
      mode: mode,
      totalSeconds: totalSeconds,
      remainSeconds: totalSeconds,
      elapsedSecs: 0,
      targetValue: targetValue,
      running: false,
      finished: false,
      savedAt: DateTime.now().millisecondsSinceEpoch,
      createdAt: old.createdAt,
    );
    _timers[idx] = updated;
    await _db.upsertTimer(updated);
    notifyListeners();
  }

  Future<void> deleteTimer(int id) async {
    _timers.removeWhere((t) => t.id == id);
    await _db.deleteTimer(id);
    notifyListeners();
  }

  void startTimer(int id) {
    final idx = _timers.indexWhere((t) => t.id == id);
    if (idx < 0) return;

    final t = _timers[idx];
    if (t.finished) {
      resetTimer(id);
      // Re-fetch after reset
      final t2 = _timers[_timers.indexWhere((t) => t.id == id)];
      t2.running = true;
      t2.savedAt = DateTime.now().millisecondsSinceEpoch;
      _saveTimer(t2);
      notifyListeners();
      return;
    }

    if (t.running || t.totalSeconds <= 0) return;

    if (t.mode == 'target' && t.targetValue != null) {
      final target = DateTime.parse(t.targetValue!);
      t.remainSeconds = target.difference(DateTime.now()).inSeconds.clamp(0, t.totalSeconds);
      if (t.remainSeconds <= 0) {
        _finishTimer(t);
        return;
      }
    }

    t.running = true;
    t.finished = false;
    t.savedAt = DateTime.now().millisecondsSinceEpoch;
    _saveTimer(t);
    notifyListeners();
  }

  void pauseTimer(int id) {
    final idx = _timers.indexWhere((t) => t.id == id);
    if (idx < 0) return;

    final t = _timers[idx];
    if (!t.running) return;

    t.running = false;
    t.savedAt = DateTime.now().millisecondsSinceEpoch;
    _saveTimer(t);
    notifyListeners();
  }

  void resetTimer(int id) {
    final idx = _timers.indexWhere((t) => t.id == id);
    if (idx < 0) return;

    final t = _timers[idx];
    t.running = false;
    t.finished = false;
    t.elapsedSecs = 0;

    if (t.mode == 'target' && t.targetValue != null) {
      final target = DateTime.parse(t.targetValue!);
      t.remainSeconds = target.difference(DateTime.now()).inSeconds.clamp(0, 999999999);
      t.totalSeconds = t.remainSeconds;
    } else {
      t.remainSeconds = t.totalSeconds;
    }

    t.savedAt = DateTime.now().millisecondsSinceEpoch;
    _saveTimer(t);
    notifyListeners();
  }

  void _finishTimer(TimerModel t) {
    t.running = false;
    t.finished = true;
    t.remainSeconds = 0;
    t.elapsedSecs = t.totalSeconds;
    t.savedAt = DateTime.now().millisecondsSinceEpoch;
    _saveTimer(t);
    notifyListeners();
  }

  void _startTicking() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _tick();
    });
  }

  void _tick() {
    bool changed = false;

    for (final t in _timers) {
      if (!t.running || t.finished) continue;
      changed = true;

      if (t.mode == 'target' && t.targetValue != null) {
        final target = DateTime.parse(t.targetValue!);
        t.remainSeconds = target.difference(DateTime.now()).inSeconds.clamp(0, t.totalSeconds);
      } else {
        if (t.remainSeconds > 0) t.remainSeconds--;
      }
      if (t.elapsedSecs < t.totalSeconds) t.elapsedSecs++;

      if (t.remainSeconds <= 0) {
        _finishTimer(t);
      }
    }

    if (changed) {
      _tickCount++;
      if (_tickCount >= 5) {
        _tickCount = 0;
        _saveAllRunning();
      }
      notifyListeners();
    }
  }

  Future<void> _saveTimer(TimerModel t) async {
    await _db.upsertTimer(t);
  }

  Future<void> _saveAllRunning() async {
    for (final t in _timers) {
      if (t.running) {
        t.savedAt = DateTime.now().millisecondsSinceEpoch;
        await _db.upsertTimer(t);
      }
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    super.dispose();
  }
}
