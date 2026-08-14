import 'dart:async';

import 'package:flutter/material.dart';

import '../models/timer_model.dart';
import '../theme/app_theme.dart';
import '../utils/native_window.dart';
import '../utils/time_utils.dart';
import '../widgets/hourglass_widget.dart';

/// Root app for a floating widget sub-window. It holds no timer logic:
/// the main window drives everything and pushes state into [notifier].
/// [windowToken] is the unique OS window title the main window tagged this
/// sub-window with; the close button and resize grip act on exactly this
/// window via that token (see native_window.dart).
class WidgetApp extends StatelessWidget {
  final ValueNotifier<TimerModel> notifier;
  final String windowToken;

  const WidgetApp(
      {super.key, required this.notifier, required this.windowToken});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: TimerWidgetView(notifier: notifier, windowToken: windowToken),
    );
  }
}

/// Compact always-on-top widget: title/drag bar on top, big countdown, elapsed
/// time and progress bar. Read-only — the close button hides its own native
/// window; timer controls live on the main window.
class TimerWidgetView extends StatelessWidget {
  final ValueNotifier<TimerModel> notifier;
  final String windowToken;

  const TimerWidgetView(
      {super.key, required this.notifier, required this.windowToken});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: ValueListenableBuilder<TimerModel>(
        valueListenable: notifier,
        builder: (context, timer, _) {
          return Stack(
            children: [
              Column(
                children: [
                  _DragBar(
                    title: timer.title,
                    onClose: () => hideWidgetWindow(windowToken),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 6, 14, 10),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Expanded(
                            child: Row(
                              children: [
                                HourglassWidget(
                                  size: 58,
                                  // Many widgets share one desktop UI thread, so
                                  // keep each one's repaint rate low (~10fps).
                                  frameMs: 100,
                                  progress: timer.progress,
                                  isRunning: timer.running,
                                  isDone: timer.finished,
                                  isLow: timer.isLow,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      _Countdown(timer: timer),
                                      const SizedBox(height: 7),
                                      _Elapsed(timer: timer),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          _ProgressBar(timer: timer),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              // Drag this corner to resize the frameless window.
              Positioned(
                right: 0,
                bottom: 0,
                child: _ResizeGrip(windowToken: windowToken),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _DragBar extends StatelessWidget {
  final String title;
  final VoidCallback onClose;

  const _DragBar({required this.title, required this.onClose});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 30,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          // Drag the frameless window by grabbing the title strip. Uses a
          // native WM_NCLBUTTONDOWN via FFI (see native_window.dart).
          Expanded(
            child: Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: (_) => startWindowDrag(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                      letterSpacing: 0.4,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 30,
              height: 30,
              alignment: Alignment.center,
              child: const Icon(Icons.close, size: 15, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

/// Bottom-right grip that resizes the frameless widget window by dragging.
///
/// Anchors on the window's physical size at drag start, accumulates the
/// (DPI-scaled) pointer delta as a target size, and applies it from a throttle
/// timer — never directly in `onPanUpdate`. Resizing the window synchronously
/// inside the pointer handler re-enters the Flutter renderer mid-frame and
/// white-outs / crashes the widget; a timer applies the latest target between
/// frames instead. The resize targets this exact window by [windowToken].
class _ResizeGrip extends StatefulWidget {
  final String windowToken;

  const _ResizeGrip({required this.windowToken});

  @override
  State<_ResizeGrip> createState() => _ResizeGripState();
}

class _ResizeGripState extends State<_ResizeGrip> {
  static const int _minW = 220, _minH = 150, _maxW = 900, _maxH = 700;

  int _startW = 0, _startH = 0;
  double _accX = 0, _accY = 0;
  int _targetW = 0, _targetH = 0;
  int _appliedW = 0, _appliedH = 0;
  Timer? _throttle;

  void _onStart(DragStartDetails _) {
    final size = widgetWindowSize(widget.windowToken);
    _startW = size?.width ?? 0;
    _startH = size?.height ?? 0;
    _accX = 0;
    _accY = 0;
    _targetW = _startW;
    _targetH = _startH;
    _appliedW = _startW;
    _appliedH = _startH;
    _throttle?.cancel();
    // ~16fps: applies the pending target off the gesture stack (see class doc).
    _throttle = Timer.periodic(const Duration(milliseconds: 60), (_) => _apply());
  }

  void _onUpdate(DragUpdateDetails d) {
    if (_startW == 0) return;
    final dpr = MediaQuery.of(context).devicePixelRatio;
    _accX += d.delta.dx;
    _accY += d.delta.dy;
    _targetW = (_startW + _accX * dpr).round().clamp(_minW, _maxW);
    _targetH = (_startH + _accY * dpr).round().clamp(_minH, _maxH);
  }

  void _onEnd(DragEndDetails _) {
    _throttle?.cancel();
    _throttle = null;
    _apply(); // ensure the final size is applied
  }

  void _apply() {
    if (_startW == 0) return;
    if (_targetW == _appliedW && _targetH == _appliedH) return;
    _appliedW = _targetW;
    _appliedH = _targetH;
    resizeWidgetWindow(widget.windowToken, _targetW, _targetH);
  }

  @override
  void dispose() {
    _throttle?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.resizeUpLeftDownRight,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onPanStart: _onStart,
        onPanUpdate: _onUpdate,
        onPanEnd: _onEnd,
        child: const SizedBox(
          width: 20,
          height: 20,
          child: CustomPaint(painter: _GripPainter()),
        ),
      ),
    );
  }
}

class _GripPainter extends CustomPainter {
  const _GripPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.muted.withValues(alpha: 0.5)
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;
    // Three short diagonal ticks in the corner.
    for (final o in [5.0, 9.5, 14.0]) {
      canvas.drawLine(
        Offset(size.width - 2, size.height - o),
        Offset(size.width - o, size.height - 2),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_GripPainter oldDelegate) => false;
}

class _Countdown extends StatelessWidget {
  final TimerModel timer;

  const _Countdown({required this.timer});

  @override
  Widget build(BuildContext context) {
    Color color;
    if (timer.finished) {
      color = AppColors.success;
    } else if (timer.isLow) {
      color = AppColors.warn;
    } else {
      color = AppColors.text;
    }

    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Text(
        formatTime(timer.remainSeconds),
        style: TextStyle(
          fontSize: 36,
          fontWeight: FontWeight.w800,
          height: 1,
          color: color,
          fontFeatures: const [FontFeature.tabularFigures()],
        ),
      ),
    );
  }
}

/// Small "elapsed time" line under the big remaining countdown.
class _Elapsed extends StatelessWidget {
  final TimerModel timer;

  const _Elapsed({required this.timer});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(Icons.history, size: 15, color: AppColors.muted),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            'Đã trôi ${formatTime(timer.elapsedSecs)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final TimerModel timer;

  const _ProgressBar({required this.timer});

  @override
  Widget build(BuildContext context) {
    LinearGradient grad;
    if (timer.finished) {
      grad = progressDoneGradient;
    } else if (timer.isLow) {
      grad = progressLowGradient;
    } else {
      grad = progressGradient;
    }

    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0x09FFFFFF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: timer.progress.clamp(0, 1),
        child: Container(
          decoration: BoxDecoration(
            gradient: grad,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}

