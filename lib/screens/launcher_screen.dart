import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/timer_service.dart';
import '../theme/app_theme.dart';
import '../utils/responsive.dart';
import '../widgets/timer_card.dart';
import '../widgets/create_timer_dialog.dart';
import 'timer_screen.dart';

class LauncherScreen extends StatelessWidget {
  const LauncherScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Column(
          children: [
            // App bar
            _AppBar(),
            // Toolbar
            _Toolbar(),
            // Timer list
            const Expanded(child: _TimerList()),
          ],
        ),
      ),
    );
  }
}

class _AppBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          const Text(
            'Countdown Timer',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.muted,
              letterSpacing: 0.4,
            ),
          ),
          const Spacer(),
          if (Responsive.isDesktop(context))
            Consumer<TimerService>(
              builder: (_, service, __) {
                final count = service.runningCount;
                if (count == 0) return const SizedBox();
                return Text(
                  '$count đang chạy',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => _openCreateDialog(context),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('+', style: TextStyle(fontSize: 17, color: AppColors.accentText)),
                SizedBox(width: 4),
                Text(
                  'Thêm bộ đếm',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accentText,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (!Responsive.isDesktop(context))
            Consumer<TimerService>(
              builder: (_, service, __) {
                final count = service.runningCount;
                if (count == 0) return const SizedBox();
                return Text(
                  '$count đang chạy',
                  style: const TextStyle(fontSize: 11, color: AppColors.muted),
                );
              },
            ),
          const Spacer(),
          Consumer<TimerService>(
            builder: (_, service, __) => _SortDropdown(
              value: service.sortOption,
              onChanged: (o) => service.setSortOption(o),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerList extends StatelessWidget {
  const _TimerList();

  @override
  Widget build(BuildContext context) {
    return Consumer<TimerService>(
      builder: (context, service, _) {
        final timers = service.sortedTimers;

        if (timers.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('⏳', style: TextStyle(fontSize: 42)),
                const SizedBox(height: 8),
                const Text(
                  'Chưa có bộ đếm nào',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.muted),
                ),
                const SizedBox(height: 4),
                GestureDetector(
                  onTap: () => _openCreateDialog(context),
                  child: RichText(
                    text: const TextSpan(
                      style: TextStyle(fontSize: 12, color: AppColors.muted),
                      children: [
                        TextSpan(text: 'Nhấn '),
                        TextSpan(
                          text: '+ Thêm bộ đếm',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.accentText,
                          ),
                        ),
                        TextSpan(text: ' để bắt đầu'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final columns = Responsive.gridColumns(context);
        final padding = Responsive.screenPadding(context);

        if (columns == 1) {
          // List layout for mobile
          return ListView.separated(
            padding: padding,
            itemCount: timers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _buildTimerCard(context, service, timers[index]);
            },
          );
        }

        // Grid layout for tablet/desktop
        return GridView.builder(
          padding: padding,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.8,
          ),
          itemCount: timers.length,
          itemBuilder: (context, index) {
            return _buildTimerCard(context, service, timers[index]);
          },
        );
      },
    );
  }

  Widget _buildTimerCard(BuildContext context, TimerService service, timer) {
    return TimerCard(
      timer: timer,
      onTap: () => _openTimerScreen(context, timer.id),
      onEdit: () => _openEditDialog(context, timer),
      onDelete: () => _showDeleteConfirm(context, service, timer),
      onStart: () => service.startTimer(timer.id),
      onPause: () => service.pauseTimer(timer.id),
      onReset: () => service.resetTimer(timer.id),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final TimerSortOption value;
  final ValueChanged<TimerSortOption> onChanged;

  const _SortDropdown({required this.value, required this.onChanged});

  static const _labels = {
    TimerSortOption.newestFirst: 'Mới nhất',
    TimerSortOption.oldestFirst: 'Cũ nhất',
    TimerSortOption.nameAZ: 'Tên A-Z',
    TimerSortOption.remaining: 'Còn lại',
    TimerSortOption.statusFirst: 'Đang chạy',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.border),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<TimerSortOption>(
          value: value,
          isDense: true,
          icon: const Icon(Icons.swap_vert, size: 12, color: AppColors.muted),
          dropdownColor: AppColors.surface,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
          items: TimerSortOption.values.map((o) {
            return DropdownMenuItem(value: o, child: Text(_labels[o]!));
          }).toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

// ── Navigation helpers ──────────────────────────────────────────────────

void _openCreateDialog(BuildContext context) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => const CreateTimerDialog(),
  );
  if (result == null) return;

  if (!context.mounted) return;
  final service = context.read<TimerService>();
  final timer = await service.createTimer(
    title: result['title'],
    mode: result['mode'],
    totalSeconds: result['totalSeconds'],
    targetValue: result['targetValue'],
  );

  // Auto-start and navigate
  service.startTimer(timer.id);
  if (context.mounted) {
    _openTimerScreen(context, timer.id);
  }
}

void _openEditDialog(BuildContext context, timer) async {
  final result = await showDialog<Map<String, dynamic>>(
    context: context,
    builder: (_) => CreateTimerDialog(editTimer: timer),
  );
  if (result == null || !context.mounted) return;

  final service = context.read<TimerService>();
  await service.updateTimerConfig(
    id: timer.id,
    title: result['title'],
    mode: result['mode'],
    totalSeconds: result['totalSeconds'],
    targetValue: result['targetValue'],
  );
}

void _openTimerScreen(BuildContext context, int timerId) {
  final isDesktop = Responsive.isDesktop(context);

  if (isDesktop) {
    // On desktop, show as a dialog/overlay
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: SizedBox(
          width: 500,
          height: 380,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: TimerScreen(timerId: timerId),
          ),
        ),
      ),
    );
  } else {
    // On mobile/tablet, navigate to full screen
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TimerScreen(timerId: timerId)),
    );
  }
}

void _showDeleteConfirm(BuildContext context, TimerService service, timer) {
  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 290,
        padding: const EdgeInsets.fromLTRB(32, 28, 32, 24),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment(-0.3, -1),
            end: Alignment(0.3, 1),
            colors: [Color(0xFF1E1E36), Color(0xFF1A1A2E)],
            stops: [0, 0.4],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0x12FFFFFF)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 48,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🗑', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 12),
            Text(
              timer.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.text,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            const Text(
              'Bộ đếm sẽ bị xóa vĩnh viễn và không thể khôi phục.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: AppColors.muted, height: 1.5),
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 9),
                      side: const BorderSide(color: Color(0x10FFFFFF)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Hủy bỏ', style: TextStyle(color: Color(0xFF94A3B8))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.danger, Color(0xFFDC2626)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.danger.withValues(alpha: 0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () {
                        service.deleteTimer(timer.id);
                        Navigator.of(ctx).pop();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Xóa bộ đếm', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}
