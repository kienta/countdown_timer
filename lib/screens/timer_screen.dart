import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/timer_model.dart';
import '../services/timer_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../utils/time_utils.dart';
import '../widgets/hourglass_widget.dart';

class TimerScreen extends StatelessWidget {
  final int timerId;

  const TimerScreen({super.key, required this.timerId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Consumer<TimerService>(
          builder: (context, service, _) {
            final timer = service.timers.where((t) => t.id == timerId).firstOrNull;
            if (timer == null) {
              return const Center(
                child: Text('Timer not found', style: TextStyle(color: AppColors.muted)),
              );
            }
            return _TimerContent(timer: timer, service: service);
          },
        ),
      ),
    );
  }
}

class _TimerContent extends StatelessWidget {
  final TimerModel timer;
  final TimerService service;

  const _TimerContent({required this.timer, required this.service});

  @override
  Widget build(BuildContext context) {
    final useHorizontal = Responsive.useHorizontalTimerLayout(context);

    return Column(
      children: [
        // Title bar
        _TitleBar(timer: timer),

        // Main content
        Expanded(
          child: useHorizontal
              ? _HorizontalLayout(timer: timer, service: service)
              : _VerticalLayout(timer: timer, service: service),
        ),
      ],
    );
  }
}

class _TitleBar extends StatelessWidget {
  final TimerModel timer;

  const _TitleBar({required this.timer});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const Icon(Icons.arrow_back_ios, size: 16, color: AppColors.muted),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              timer.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.muted,
                letterSpacing: 0.4,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Desktop/Tablet: side by side layout
class _HorizontalLayout extends StatelessWidget {
  final TimerModel timer;
  final TimerService service;

  const _HorizontalLayout({required this.timer, required this.service});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Left: countdown + progress + elapsed
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CountdownSection(timer: timer),
                const SizedBox(height: 10),
                _ProgressBarSection(timer: timer),
                const SizedBox(height: 10),
                _ElapsedSection(timer: timer),
              ],
            ),
          ),
        ),

        // Right: controls + hourglass + status
        SizedBox(
          width: Responsive.isDesktop(context) ? 140 : 120,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 8, 18, 10),
            child: Column(
              children: [
                // Controls at top right
                _ControlButtons(timer: timer, service: service),
                // Hourglass in center
                Expanded(
                  child: Center(
                    child: HourglassWidget(
                      size: Responsive.hourglassSize(context) * 0.7,
                      progress: timer.progress,
                      isRunning: timer.running,
                      isDone: timer.finished,
                      isLow: timer.isLow,
                    ),
                  ),
                ),
                // Status badge at bottom right
                Align(
                  alignment: Alignment.centerRight,
                  child: _StatusBadge(timer: timer),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Mobile: stacked vertical layout
class _VerticalLayout extends StatelessWidget {
  final TimerModel timer;
  final TimerService service;

  const _VerticalLayout({required this.timer, required this.service});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hourglass
        Expanded(
          flex: 3,
          child: Center(
            child: HourglassWidget(
              size: Responsive.hourglassSize(context),
              progress: timer.progress,
              isRunning: timer.running,
              isDone: timer.finished,
              isLow: timer.isLow,
            ),
          ),
        ),

        // Countdown
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _SectionLabel('Thời gian còn lại'),
              const SizedBox(height: 6),
              _CountdownDisplay(timer: timer, fontSize: Responsive.countdownFontSize(context)),
            ],
          ),
        ),

        // Progress
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: _ProgressBarSection(timer: timer),
        ),

        // Elapsed
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: [
              _SectionLabel('Đã trôi qua'),
              const SizedBox(height: 6),
              _ElapsedDisplay(timer: timer, fontSize: Responsive.countdownFontSize(context) * 0.8),
            ],
          ),
        ),

        const SizedBox(height: 8),

        // Footer: status + controls
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            children: [
              _StatusBadge(timer: timer),
              const Spacer(),
              _ControlButtons(timer: timer, service: service, large: true),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Shared components ──────────────────────────────────────────────────

class _CountdownSection extends StatelessWidget {
  final TimerModel timer;

  const _CountdownSection({required this.timer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Thời gian còn lại'),
        const SizedBox(height: 6),
        _CountdownDisplay(
          timer: timer,
          fontSize: Responsive.countdownFontSize(context),
        ),
      ],
    );
  }
}

class _ElapsedSection extends StatelessWidget {
  final TimerModel timer;

  const _ElapsedSection({required this.timer});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionLabel('Đã trôi qua'),
        const SizedBox(height: 6),
        _ElapsedDisplay(
          timer: timer,
          fontSize: Responsive.countdownFontSize(context) * 0.85,
        ),
      ],
    );
  }
}

class _CountdownDisplay extends StatelessWidget {
  final TimerModel timer;
  final double fontSize;

  const _CountdownDisplay({required this.timer, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final units = secsToUnits(timer.remainSeconds);
    final showDays = timer.totalSeconds >= 86400;

    Color numColor;
    Color unitColor;
    if (timer.finished) {
      numColor = AppColors.success;
      unitColor = AppColors.success;
    } else if (timer.isLow) {
      numColor = AppColors.warn;
      unitColor = AppColors.warn;
    } else {
      numColor = AppColors.text;
      unitColor = AppColors.muted;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDays) ...[
          _Segment('${units.d}', 'ngày', fontSize, numColor, unitColor),
          SizedBox(width: fontSize * 0.3),
        ],
        _Segment(pad(units.h), 'giờ', fontSize, numColor, unitColor),
        SizedBox(width: fontSize * 0.3),
        _Segment(pad(units.m), 'phút', fontSize, numColor, unitColor),
        SizedBox(width: fontSize * 0.3),
        _Segment(pad(units.s), 'giây', fontSize, numColor, unitColor),
      ],
    );
  }
}

class _ElapsedDisplay extends StatelessWidget {
  final TimerModel timer;
  final double fontSize;

  const _ElapsedDisplay({required this.timer, required this.fontSize});

  @override
  Widget build(BuildContext context) {
    final units = secsToUnits(timer.elapsedSecs);
    final showDays = timer.totalSeconds >= 86400;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showDays) ...[
          _Segment('${units.d}', 'ngày', fontSize, AppColors.success, AppColors.success.withValues(alpha: 0.65)),
          SizedBox(width: fontSize * 0.3),
        ],
        _Segment(pad(units.h), 'giờ', fontSize, AppColors.success, AppColors.success.withValues(alpha: 0.65)),
        SizedBox(width: fontSize * 0.3),
        _Segment(pad(units.m), 'phút', fontSize, AppColors.success, AppColors.success.withValues(alpha: 0.65)),
        SizedBox(width: fontSize * 0.3),
        _Segment(pad(units.s), 'giây', fontSize, AppColors.success, AppColors.success.withValues(alpha: 0.65)),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  final String value;
  final String unit;
  final double fontSize;
  final Color numColor;
  final Color unitColor;

  const _Segment(this.value, this.unit, this.fontSize, this.numColor, this.unitColor);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w800,
            height: 1,
            color: numColor,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          unit,
          style: TextStyle(
            fontSize: fontSize * 0.25,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
            color: unitColor,
          ),
        ),
      ],
    );
  }
}

Widget _SectionLabel(String text) {
  return Text(
    text.toUpperCase(),
    style: const TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      letterSpacing: 1,
      color: AppColors.muted,
    ),
  );
}

class _ProgressBarSection extends StatelessWidget {
  final TimerModel timer;

  const _ProgressBarSection({required this.timer});

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

class _StatusBadge extends StatelessWidget {
  final TimerModel timer;

  const _StatusBadge({required this.timer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: statusBadgeDecoration(timer.statusKey),
      child: Text(
        timer.statusText,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: statusBadgeTextColor(timer.statusKey),
        ),
      ),
    );
  }
}

class _ControlButtons extends StatelessWidget {
  final TimerModel timer;
  final TimerService service;
  final bool large;

  const _ControlButtons({
    required this.timer,
    required this.service,
    this.large = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = large ? 50.0 : 30.0;
    final iconSize = large ? 18.0 : 12.0;
    final gap = large ? 14.0 : 6.0;

    final canStart = timer.finished || (!timer.running && timer.totalSeconds > 0);
    final canPause = timer.running && !timer.finished;
    final canReset = timer.finished || (!timer.running && timer.elapsedSecs > 0);

    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Start
        _RoundButton(
          size: size,
          onTap: canStart ? () => service.startTimer(timer.id) : null,
          gradient: accentGradient,
          child: Icon(Icons.play_arrow, size: iconSize, color: Colors.white),
        ),
        SizedBox(width: gap),
        // Pause
        _RoundButton(
          size: size,
          onTap: canPause ? () => service.pauseTimer(timer.id) : null,
          borderColor: AppColors.warn,
          child: Icon(Icons.pause, size: iconSize * 0.8, color: AppColors.warn),
        ),
        SizedBox(width: gap),
        // Reset
        _RoundButton(
          size: size,
          onTap: canReset ? () => service.resetTimer(timer.id) : null,
          borderColor: const Color(0x18FFFFFF),
          child: Icon(Icons.refresh, size: iconSize, color: AppColors.muted),
        ),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  final double size;
  final VoidCallback? onTap;
  final LinearGradient? gradient;
  final Color? borderColor;
  final Widget child;

  const _RoundButton({
    required this.size,
    this.onTap,
    this.gradient,
    this.borderColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: disabled ? 0.28 : 1.0,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            gradient: gradient,
            shape: BoxShape.circle,
            border: borderColor != null
                ? Border.all(color: borderColor!, width: size > 40 ? 2 : 1.5)
                : null,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}
