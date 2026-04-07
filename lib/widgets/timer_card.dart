import 'package:flutter/material.dart';
import '../models/timer_model.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';

class TimerCard extends StatelessWidget {
  final TimerModel timer;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;

  const TimerCard({
    super.key,
    required this.timer,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: title + status + edit/delete
              Row(
                children: [
                  Expanded(
                    child: Text(
                      timer.title,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.text,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: timer.statusKey, text: timer.statusText),
                  const SizedBox(width: 6),
                  _IconBtn(
                    icon: Icons.edit_outlined,
                    onTap: onEdit,
                    hoverColor: AppColors.accent.withValues(alpha: 0.15),
                    iconColor: AppColors.muted,
                    hoverIconColor: AppColors.accent,
                  ),
                  const SizedBox(width: 2),
                  _IconBtn(
                    icon: Icons.close,
                    onTap: onDelete,
                    hoverColor: AppColors.danger.withValues(alpha: 0.15),
                    iconColor: AppColors.muted,
                    hoverIconColor: AppColors.danger,
                  ),
                ],
              ),

              const SizedBox(height: 4),

              // Time + controls
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${formatTime(timer.remainSeconds)} / ${formatTime(timer.totalSeconds)}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.muted,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  _CardControls(
                    timer: timer,
                    onStart: onStart,
                    onPause: onPause,
                    onReset: onReset,
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Progress bar
              _ProgressBar(progress: timer.progress, isLow: timer.isLow, isDone: timer.finished),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  final String text;

  const _StatusBadge({required this.status, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: statusBadgeDecoration(status),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.6,
          color: statusBadgeTextColor(status),
        ),
      ),
    );
  }
}

class _IconBtn extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color hoverColor;
  final Color iconColor;
  final Color hoverIconColor;

  const _IconBtn({
    required this.icon,
    required this.onTap,
    required this.hoverColor,
    required this.iconColor,
    required this.hoverIconColor,
  });

  @override
  State<_IconBtn> createState() => _IconBtnState();
}

class _IconBtnState extends State<_IconBtn> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: _hovered ? widget.hoverColor : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: 12,
            color: _hovered ? widget.hoverIconColor : widget.iconColor,
          ),
        ),
      ),
    );
  }
}

class _CardControls extends StatelessWidget {
  final TimerModel timer;
  final VoidCallback onStart;
  final VoidCallback onPause;
  final VoidCallback onReset;

  const _CardControls({
    required this.timer,
    required this.onStart,
    required this.onPause,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final canStart = timer.finished || (!timer.running && timer.totalSeconds > 0);
    final canPause = timer.running && !timer.finished;
    final canReset = timer.finished || (!timer.running && timer.elapsedSecs > 0);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Start
        _ControlButton(
          onTap: canStart ? onStart : null,
          gradient: accentGradient,
          child: const Icon(Icons.play_arrow, size: 12, color: Colors.white),
        ),
        const SizedBox(width: 4),
        // Pause
        _ControlButton(
          onTap: canPause ? onPause : null,
          borderColor: AppColors.warn,
          child: Icon(Icons.pause, size: 12, color: canPause ? AppColors.warn : AppColors.warn.withValues(alpha: 0.3)),
        ),
        const SizedBox(width: 4),
        // Reset
        _ControlButton(
          onTap: canReset ? onReset : null,
          borderColor: const Color(0x14FFFFFF),
          child: Icon(Icons.refresh, size: 12, color: canReset ? AppColors.muted : AppColors.muted.withValues(alpha: 0.3)),
        ),
      ],
    );
  }
}

class _ControlButton extends StatelessWidget {
  final VoidCallback? onTap;
  final LinearGradient? gradient;
  final Color? borderColor;
  final Widget child;

  const _ControlButton({
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
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            gradient: gradient,
            border: borderColor != null ? Border.all(color: borderColor!, width: 1.5) : null,
            borderRadius: BorderRadius.circular(5),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final double progress;
  final bool isLow;
  final bool isDone;

  const _ProgressBar({
    required this.progress,
    required this.isLow,
    required this.isDone,
  });

  @override
  Widget build(BuildContext context) {
    LinearGradient grad;
    if (isDone) {
      grad = progressDoneGradient;
    } else if (isLow) {
      grad = progressLowGradient;
    } else {
      grad = progressGradient;
    }

    return Container(
      height: 3,
      decoration: BoxDecoration(
        color: const Color(0x09FFFFFF),
        borderRadius: BorderRadius.circular(99),
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress.clamp(0, 1),
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
