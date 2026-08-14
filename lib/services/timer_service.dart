import 'dart:async';
import 'dart:convert';
import 'package:desktop_multi_window/desktop_multi_window.dart';
import 'package:flutter/foundation.dart';
import '../models/timer_model.dart';
import '../utils/app_logger.dart';
import '../utils/native_window.dart';
import 'database_service.dart';
import 'notification_service.dart';

enum TimerSortOption { newestFirst, oldestFirst, nameAZ, remaining, statusFirst }

class TimerService extends ChangeNotifier {
  final DatabaseService _db = DatabaseService();
  final NotificationService _notify = NotificationService();
  List<TimerModel> _timers = [];
  Timer? _tickTimer;
  int _tickCount = 0;
  TimerSortOption _sortOption = TimerSortOption.newestFirst;

  // Widget windows currently open: timerId -> desktop_multi_window windowId.
  // The main window is the single source of truth and pushes live state to
  // each open widget via DesktopMultiWindow.invokeMethod.
  final Map<int, int> _widgetWindows = {};

  // Widgets close their own native window. We can't be notified of that
  // directly, so the main window periodically reconciles its map against the
  // set of live sub-windows. This is a single IPC call per pass regardless of
  // how many widgets are open (an earlier design polled every widget on a
  // short interval, which saturated the shared UI thread and froze the app).
  Timer? _reconcileTimer;

  List<TimerModel> get timers => _timers;

  TimerSortOption get sortOption => _sortOption;

  void setSortOption(TimerSortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  List<TimerModel> get sortedTimers {
    final sorted = List<TimerModel>.from(_timers);
    switch (_sortOption) {
      case TimerSortOption.newestFirst:
        sorted.sort((a, b) => (b.createdAt ?? 0).compareTo(a.createdAt ?? 0));
      case TimerSortOption.oldestFirst:
        sorted.sort((a, b) => (a.createdAt ?? 0).compareTo(b.createdAt ?? 0));
      case TimerSortOption.nameAZ:
        sorted.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
      case TimerSortOption.remaining:
        sorted.sort((a, b) => a.remainSeconds.compareTo(b.remainSeconds));
      case TimerSortOption.statusFirst:
        sorted.sort((a, b) {
          final aOrder = _statusOrder(a);
          final bOrder = _statusOrder(b);
          if (aOrder != bOrder) return aOrder.compareTo(bOrder);
          return a.remainSeconds.compareTo(b.remainSeconds);
        });
    }
    return sorted;
  }

  int _statusOrder(TimerModel t) {
    if (t.running && !t.finished) return 0;
    if (!t.running && !t.finished && t.elapsedSecs > 0) return 1;
    if (!t.running && !t.finished) return 2;
    return 3; // finished
  }

  int get runningCount => _timers.where((t) => t.running && !t.finished).length;

  // ── Widget window sync (desktop multi-window IPC) ──────────────────────

  /// Whether a widget window is currently open for [timerId].
  bool hasWidget(int timerId) => _widgetWindows.containsKey(timerId);

  /// Register an open widget window for [timerId] and push the current state.
  void registerWidget(int timerId, int windowId) {
    _widgetWindows[timerId] = windowId;
    AppLogger.instance.info('Widget registered',
        {'timerId': timerId, 'windowId': windowId});
    _pushUpdate(timerId);
    _ensureReconcile();
  }

  /// Re-show the widget window for [timerId], bring it to the front and refresh
  /// its state. Widgets are hidden rather than destroyed on "close" (destroying
  /// a sub-window engine in this plugin version spins the CPU) and are no longer
  /// always-on-top, so reopening a timer un-hides the existing window and raises
  /// it above other windows.
  void showWidget(int timerId) {
    final windowId = _widgetWindows[timerId];
    if (windowId == null) return;
    showWidgetWindow('cdtwidget_$windowId');
    _pushUpdate(timerId);
  }

  /// Push the latest state of [timerId] to its widget window, if any.
  void _pushUpdate(int timerId) {
    final windowId = _widgetWindows[timerId];
    if (windowId == null) return;
    final idx = _timers.indexWhere((t) => t.id == timerId);
    if (idx < 0) return;
    final payload = jsonEncode(_timers[idx].toMap());
    DesktopMultiWindow.invokeMethod(windowId, 'update', payload).catchError((e) {
      // Widget window is gone — stop tracking it.
      _dropWidget(timerId, 'update failed: $e');
    });
  }

  void _dropWidget(int timerId, String reason) {
    if (_widgetWindows.remove(timerId) != null) {
      AppLogger.instance.warn('Dropped widget window',
          {'timerId': timerId, 'reason': reason});
    }
    if (_widgetWindows.isEmpty) {
      _reconcileTimer?.cancel();
      _reconcileTimer = null;
    }
  }

  void _ensureReconcile() {
    if (_reconcileTimer != null || _widgetWindows.isEmpty) return;
    _reconcileTimer = Timer.periodic(
        const Duration(seconds: 1), (_) => _reconcileWidgets());
  }

  /// Drop any widget whose native window the user has closed. One cheap IPC
  /// call (`getAllSubWindowIds`) covers every widget, so cost does not grow
  /// with the number of open widgets.
  Future<void> _reconcileWidgets() async {
    if (_widgetWindows.isEmpty) {
      _reconcileTimer?.cancel();
      _reconcileTimer = null;
      return;
    }
    List<int> liveIds;
    try {
      liveIds = await DesktopMultiWindow.getAllSubWindowIds();
    } catch (_) {
      return; // transient — retry next pass
    }
    final live = liveIds.toSet();
    final gone = _widgetWindows.entries
        .where((e) => !live.contains(e.value))
        .map((e) => e.key)
        .toList();
    for (final timerId in gone) {
      _dropWidget(timerId, 'window closed by user');
    }
  }

  /// Stop reconciling and forget all widget windows, called on app exit. We do
  /// NOT call `WindowController.close()` here: destroying a sub-window engine in
  /// this plugin version spins the CPU. The caller follows this with `exit(0)`,
  /// and process termination reaps every window cleanly without that teardown.
  Future<void> closeAllWidgets() async {
    _reconcileTimer?.cancel();
    _reconcileTimer = null;
    _widgetWindows.clear();
  }

  Future<void> init() async {
    await _db.init();
    await _notify.init();
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
      _pushUpdate(id);
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
    _pushUpdate(id);
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
    _pushUpdate(id);
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
    _pushUpdate(id);
  }

  void _finishTimer(TimerModel t) {
    t.running = false;
    t.finished = true;
    t.remainSeconds = 0;
    t.elapsedSecs = t.totalSeconds;
    t.savedAt = DateTime.now().millisecondsSinceEpoch;
    _saveTimer(t);
    _notify.playAlarm();
    _notify.showTimerFinishedNotification(id: t.id, title: t.title);
    notifyListeners();
    _pushUpdate(t.id);
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
      } else {
        _pushUpdate(t.id);
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
    _reconcileTimer?.cancel();
    super.dispose();
  }
}
