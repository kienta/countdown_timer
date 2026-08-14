import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Simple file logger shared by the main window and every widget sub-window.
///
/// Log file: `<Documents>/countdown_timer/logs/app.log` (same base folder as
/// the database). All isolates append to the SAME file; each line is tagged
/// with its [scope] (e.g. `main` or `widget:1`) so interleaved lines from
/// different windows stay distinguishable.
///
/// Line format (one record per line, easy to read and to grep):
///
///   2026-08-10T20:52:57.020Z  LEVEL  [scope]  message  {k=v, k2=v2}
///
/// Error records are followed by their stack trace, each frame indented by
/// four spaces so it is clearly a continuation of the record above.
class AppLogger {
  AppLogger._();
  static final AppLogger instance = AppLogger._();

  /// Rotate when the current file grows past this size (bytes).
  static const int _maxBytes = 2 * 1024 * 1024; // 2 MB

  String _scope = 'main';
  File? _file;

  /// Fallback used before [init] resolves the real path, or if it fails.
  /// systemTemp is always available synchronously.
  File get _fallback =>
      File(p.join(Directory.systemTemp.path, 'countdown_timer_app.log'));

  /// Resolve the log file path and write a session header. Safe to call once
  /// per isolate. Never throws — logging must not break the app.
  Future<void> init({required String scope}) async {
    _scope = scope;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final logPath = p.join(dir.path, 'countdown_timer', 'logs', 'app.log');
      final logDir = Directory(p.dirname(logPath));
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      final file = File(logPath);
      // Rotate if the file is getting large (keep a single .1 backup).
      if (await file.exists() && await file.length() > _maxBytes) {
        try {
          final backup = File('$logPath.1');
          if (await backup.exists()) await backup.delete();
          await file.rename('$logPath.1');
        } catch (_) {/* rotation is best-effort */}
      }
      _file = file;
    } catch (e) {
      _file = null; // keep using the fallback
      _rawWrite(_fallback, _format('WARN', 'logger init failed, using fallback',
          {'error': '$e'}));
    }
    info('=== session start ===', {
      'scope': scope,
      'pid': pid,
      'debug': kDebugMode,
    });
  }

  void info(String message, [Map<String, Object?>? context]) =>
      _log('INFO', message, context);

  void warn(String message, [Map<String, Object?>? context]) =>
      _log('WARN', message, context);

  /// Log an error with optional [error] object, [stack] trace and [context].
  void error(String message,
      [Object? error, StackTrace? stack, Map<String, Object?>? context]) {
    final ctx = <String, Object?>{...?context};
    if (error != null) ctx['error'] = error.toString();
    var line = _format('ERROR', message, ctx);
    if (stack != null) {
      final frames = stack
          .toString()
          .trimRight()
          .split('\n')
          .map((f) => '    $f')
          .join('\n');
      if (frames.isNotEmpty) line = '$line\n$frames';
    }
    _rawWrite(_file ?? _fallback, line);
  }

  void _log(String level, String message, Map<String, Object?>? context) {
    _rawWrite(_file ?? _fallback, _format(level, message, context));
  }

  String _format(String level, String message, Map<String, Object?>? context) {
    final ts = DateTime.now().toUtc().toIso8601String();
    final lvl = level.padRight(5);
    final scope = '[$_scope]'.padRight(12);
    final buf = StringBuffer('$ts  $lvl  $scope  $message');
    if (context != null && context.isNotEmpty) {
      final pairs = context.entries.map((e) => '${e.key}=${e.value}').join(', ');
      buf.write('  {$pairs}');
    }
    return buf.toString();
  }

  void _rawWrite(File file, String line) {
    try {
      file.writeAsStringSync('$line\n', mode: FileMode.append, flush: true);
    } catch (_) {
      // Never let logging crash the app.
    }
  }
}
