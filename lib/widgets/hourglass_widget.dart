import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HourglassWidget extends StatefulWidget {
  final double size;
  final double progress; // 0.0 = full top, 1.0 = full bottom
  final bool isRunning;
  final bool isDone;
  final bool isLow;

  const HourglassWidget({
    super.key,
    this.size = 100,
    this.progress = 0,
    this.isRunning = false,
    this.isDone = false,
    this.isLow = false,
  });

  @override
  State<HourglassWidget> createState() => _HourglassWidgetState();
}

class _HourglassWidgetState extends State<HourglassWidget>
    with TickerProviderStateMixin {
  late AnimationController _waveController;
  late AnimationController _floatController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _glowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _updateAnimations();
  }

  @override
  void didUpdateWidget(HourglassWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isDone != widget.isDone ||
        oldWidget.isRunning != widget.isRunning) {
      _updateAnimations();
    }
  }

  void _updateAnimations() {
    if (widget.isDone) {
      _floatController.repeat(reverse: true);
      _glowController.repeat(reverse: true);
    } else {
      _floatController.stop();
      _glowController.stop();
    }
  }

  @override
  void dispose() {
    _waveController.dispose();
    _floatController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_waveController, _floatController, _glowController]),
      builder: (context, child) {
        final floatOffset = widget.isDone
            ? sin(_floatController.value * pi * 2) * 5
            : 0.0;

        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: CustomPaint(
            size: Size(widget.size, widget.size * 1.55),
            painter: _HourglassPainter(
              progress: widget.progress,
              wavePhase: _waveController.value * pi * 2,
              isRunning: widget.isRunning,
              isDone: widget.isDone,
              isLow: widget.isLow,
              glowValue: _glowController.value,
            ),
          ),
        );
      },
    );
  }
}

class _HourglassPainter extends CustomPainter {
  final double progress;
  final double wavePhase;
  final bool isRunning;
  final bool isDone;
  final bool isLow;
  final double glowValue;

  _HourglassPainter({
    required this.progress,
    required this.wavePhase,
    required this.isRunning,
    required this.isDone,
    required this.isLow,
    required this.glowValue,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Proportional coordinates based on viewBox 0 0 40 62
    double sx(double x) => x / 40 * w;
    double sy(double y) => y / 62 * h;

    final capY1 = sy(1);
    final capH = sy(7);
    final topY = sy(8);
    final neckY = sy(31);
    final botY = sy(54);
    final capY2 = sy(54);

    // Color based on state
    Color mainColor;
    if (isDone) {
      mainColor = AppColors.success;
    } else if (isLow) {
      mainColor = AppColors.warn;
    } else {
      mainColor = AppColors.accent;
    }

    // Water colors
    const waterColor = Color(0xCC38BDF8);
    const waterLight = Color(0x807DD3FC);

    // ── Glass body path
    final glassPath = Path();
    glassPath.moveTo(sx(3), topY);
    glassPath.lineTo(sx(37), topY);
    glassPath.quadraticBezierTo(sx(36), sy(24), sx(21), neckY);
    glassPath.quadraticBezierTo(sx(36), sy(38), sx(37), botY);
    glassPath.lineTo(sx(3), botY);
    glassPath.quadraticBezierTo(sx(4), sy(38), sx(19), neckY);
    glassPath.quadraticBezierTo(sx(4), sy(24), sx(3), topY);
    glassPath.close();

    // ── Glass fill (subtle)
    canvas.drawPath(
      glassPath,
      Paint()..color = mainColor.withValues(alpha: 0.03),
    );

    // ── Top cap
    final capPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          mainColor.withValues(alpha: 0.12),
          mainColor.withValues(alpha: 0.55),
          mainColor.withValues(alpha: 0.55),
          mainColor.withValues(alpha: 0.12),
        ],
        stops: const [0, 0.35, 0.65, 1],
      ).createShader(Rect.fromLTWH(sx(1), capY1, sx(38), capH));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(sx(1), capY1, sx(38), capH),
        Radius.circular(sx(3.5)),
      ),
      capPaint,
    );

    // Cap line
    canvas.drawLine(
      Offset(sx(4), capY1 + sy(1.5)),
      Offset(sx(36), capY1 + sy(1.5)),
      Paint()
        ..color = mainColor.withValues(alpha: 0.45)
        ..strokeWidth = 0.5
        ..strokeCap = StrokeCap.round,
    );

    // ── Bottom cap
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(sx(1), capY2, sx(38), capH),
        Radius.circular(sx(3.5)),
      ),
      capPaint,
    );
    canvas.drawLine(
      Offset(sx(4), capY2 + sy(1.5)),
      Offset(sx(36), capY2 + sy(1.5)),
      Paint()
        ..color = mainColor.withValues(alpha: 0.35)
        ..strokeWidth = 0.5
        ..strokeCap = StrokeCap.round,
    );

    // ── Water in top chamber (clip to top half of glass)
    if (progress < 0.99) {
      canvas.save();

      // Clip path for top chamber
      final clipTop = Path();
      clipTop.moveTo(sx(3), topY);
      clipTop.lineTo(sx(37), topY);
      clipTop.quadraticBezierTo(sx(36), sy(24), sx(21), neckY);
      clipTop.lineTo(sx(19), neckY);
      clipTop.quadraticBezierTo(sx(4), sy(24), sx(3), topY);
      clipTop.close();
      canvas.clipPath(clipTop);

      final topSurfaceY = topY + (neckY - topY) * progress;
      final amplitude = isRunning ? w * 0.008 : w * 0.004;

      final waterPath = Path();
      waterPath.moveTo(0, neckY + sy(2));
      waterPath.lineTo(0, topSurfaceY + amplitude * sin(wavePhase));
      for (int i = 1; i <= 20; i++) {
        final x = i / 20 * w;
        final y = topSurfaceY + amplitude * sin(wavePhase + (x / w) * pi * 2);
        waterPath.lineTo(x, y);
      }
      waterPath.lineTo(w, neckY + sy(2));
      waterPath.close();

      canvas.drawPath(
        waterPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [waterLight, waterColor, const Color(0xE60284C7)],
            stops: const [0, 0.4, 1],
          ).createShader(Rect.fromLTRB(0, topSurfaceY, w, neckY + sy(2))),
      );

      canvas.restore();
    }

    // ── Water in bottom chamber
    if (progress > 0.01) {
      canvas.save();

      final clipBot = Path();
      clipBot.moveTo(sx(19), neckY);
      clipBot.quadraticBezierTo(sx(4), sy(38), sx(3), botY);
      clipBot.lineTo(sx(37), botY);
      clipBot.quadraticBezierTo(sx(36), sy(38), sx(21), neckY);
      clipBot.close();
      canvas.clipPath(clipBot);

      final botSurfaceY = botY - (botY - neckY) * progress;
      final amplitude = isRunning ? w * 0.006 : w * 0.003;

      final waterPath = Path();
      waterPath.moveTo(0, botY + sy(2));
      waterPath.lineTo(0, botSurfaceY + amplitude * sin(wavePhase + pi));
      for (int i = 1; i <= 20; i++) {
        final x = i / 20 * w;
        final y = botSurfaceY + amplitude * sin(wavePhase + pi + (x / w) * pi * 2);
        waterPath.lineTo(x, y);
      }
      waterPath.lineTo(w, botY + sy(2));
      waterPath.close();

      canvas.drawPath(
        waterPath,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [waterLight, waterColor, const Color(0xE60284C7)],
            stops: const [0, 0.4, 1],
          ).createShader(Rect.fromLTRB(0, botSurfaceY, w, botY + sy(2))),
      );

      canvas.restore();
    }

    // ── Water stream through neck (when running)
    if (isRunning && progress < 0.99) {
      final streamOpacity = 0.12 + 0.18 * sin(wavePhase * 0.7).abs();
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(sx(19), sy(28), sx(2), sy(6)),
          Radius.circular(sx(1)),
        ),
        Paint()..color = waterColor.withValues(alpha: streamOpacity),
      );
    }

    // ── Glass outline
    final glassPaint = Paint()
      ..color = mainColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.045
      ..strokeJoin = StrokeJoin.round;

    if (isRunning) {
      // Glow effect
      canvas.drawPath(
        glassPath,
        Paint()
          ..color = mainColor.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.08
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
      );
    }

    if (isDone) {
      final glowAlpha = 0.15 + 0.25 * glowValue;
      canvas.drawPath(
        glassPath,
        Paint()
          ..color = mainColor.withValues(alpha: glowAlpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.12
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
      );
    }

    canvas.drawPath(glassPath, glassPaint);

    // ── Glass shine highlights
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018
      ..strokeCap = StrokeCap.round;

    final shinePath = Path();
    shinePath.moveTo(sx(33), sy(4));
    shinePath.lineTo(sx(36), topY);
    shinePath.quadraticBezierTo(sx(35.5), sy(19), sx(26), sy(27));
    canvas.drawPath(shinePath, shinePaint);

    final shinePath2 = Path();
    shinePath2.moveTo(sx(26), sy(35));
    shinePath2.quadraticBezierTo(sx(35.5), sy(43), sx(36), sy(53));
    canvas.drawPath(
      shinePath2,
      shinePaint..color = Colors.white.withValues(alpha: 0.1),
    );
  }

  @override
  bool shouldRepaint(_HourglassPainter old) =>
      progress != old.progress ||
      wavePhase != old.wavePhase ||
      isRunning != old.isRunning ||
      isDone != old.isDone ||
      isLow != old.isLow ||
      glowValue != old.glowValue;
}
