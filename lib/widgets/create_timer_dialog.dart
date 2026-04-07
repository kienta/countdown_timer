import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';
import '../utils/time_utils.dart';
import '../utils/responsive.dart';
import '../models/timer_model.dart';

class CreateTimerDialog extends StatefulWidget {
  final TimerModel? editTimer; // null = create mode

  const CreateTimerDialog({super.key, this.editTimer});

  @override
  State<CreateTimerDialog> createState() => _CreateTimerDialogState();
}

class _CreateTimerDialogState extends State<CreateTimerDialog> {
  final _titleController = TextEditingController();
  String _mode = 'quick';
  final _durValueController = TextEditingController(text: '5');
  String _durUnit = 'minute';
  DateTime? _targetDate;
  String _targetPreview = '';
  bool _targetError = false;

  bool get isEdit => widget.editTimer != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final t = widget.editTimer!;
      _titleController.text = t.title;
      if (t.mode == 'target' && t.targetValue != null) {
        _mode = 'target';
        _targetDate = DateTime.tryParse(t.targetValue!);
        _updateTargetPreview();
      } else {
        _mode = 'quick';
        _reverseCalcDuration(t.totalSeconds);
      }
    }
  }

  void _reverseCalcDuration(int secs) {
    if (secs >= 86400 && secs % 86400 == 0) {
      _durValueController.text = '${secs ~/ 86400}';
      _durUnit = 'day';
    } else if (secs >= 3600 && secs % 3600 == 0) {
      _durValueController.text = '${secs ~/ 3600}';
      _durUnit = 'hour';
    } else if (secs >= 60) {
      _durValueController.text = '${(secs / 60).round()}';
      _durUnit = 'minute';
    } else {
      _durValueController.text = '${(secs / 60).clamp(1, 999999).round()}';
      _durUnit = 'minute';
    }
  }

  void _updateTargetPreview() {
    if (_targetDate == null) {
      setState(() {
        _targetPreview = '';
        _targetError = false;
      });
      return;
    }
    final diff = _targetDate!.difference(DateTime.now()).inSeconds;
    if (diff <= 0) {
      setState(() {
        _targetPreview = 'Thời gian đã qua — chọn lại!';
        _targetError = true;
      });
    } else {
      setState(() {
        _targetPreview = '→ Còn ${formatDuration(diff)}';
        _targetError = false;
      });
    }
  }

  void _submit() {
    final title = _titleController.text.trim();

    if (_mode == 'quick') {
      final val = int.tryParse(_durValueController.text) ?? 0;
      if (val <= 0) return;

      final totalSeconds = durationToSeconds(val, _durUnit);
      Navigator.of(context).pop({
        'title': title.isEmpty ? 'Bộ đếm' : title,
        'mode': 'duration',
        'totalSeconds': totalSeconds,
        'targetValue': null,
      });
    } else {
      if (_targetDate == null || _targetError) return;
      final diff = _targetDate!.difference(DateTime.now()).inSeconds;
      if (diff <= 0) return;

      Navigator.of(context).pop({
        'title': title.isEmpty ? 'Bộ đếm' : title,
        'mode': 'target',
        'totalSeconds': diff,
        'targetValue': _targetDate!.toIso8601String(),
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _durValueController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = Responsive.dialogWidth(context);

    return Dialog(
      backgroundColor: AppColors.bg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: dialogWidth,
        constraints: const BoxConstraints(maxHeight: 500),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Title bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Text(
                    isEdit ? 'Chỉnh sửa bộ đếm' : 'Thêm bộ đếm mới',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.muted,
                      letterSpacing: 0.4,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close, size: 16, color: AppColors.muted),
                  ),
                ],
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Timer name
                    _buildLabel('Tên bộ đếm'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _titleController,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.text),
                      decoration: const InputDecoration(
                        hintText: 'Bộ đếm của tôi',
                      ),
                      maxLength: 50,
                      buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
                    ),

                    const SizedBox(height: 16),

                    // Mode toggle
                    _buildLabel('Loại thời gian'),
                    const SizedBox(height: 6),
                    _ModeToggle(
                      mode: _mode,
                      onChanged: (m) => setState(() => _mode = m),
                    ),

                    const SizedBox(height: 16),

                    // Mode panel
                    if (_mode == 'quick') _buildQuickMode(),
                    if (_mode == 'target') _buildTargetMode(),
                  ],
                ),
              ),
            ),

            // Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 38),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: accentGradient,
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.25),
                            blurRadius: 14,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          minimumSize: const Size(0, 38),
                        ),
                        child: Text(isEdit ? 'Lưu thay đổi' : 'Tạo bộ đếm'),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
        color: AppColors.muted,
      ),
    );
  }

  Widget _buildQuickMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 80,
              child: TextField(
                controller: _durValueController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: AppColors.text,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  fillColor: AppColors.bg,
                  filled: true,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0x10FFFFFF), width: 1.5),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x10FFFFFF), width: 1.5),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _durUnit,
                    isExpanded: true,
                    dropdownColor: AppColors.surface,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.text),
                    items: const [
                      DropdownMenuItem(value: 'minute', child: Text('Phút')),
                      DropdownMenuItem(value: 'hour', child: Text('Giờ')),
                      DropdownMenuItem(value: 'day', child: Text('Ngày')),
                      DropdownMenuItem(value: 'week', child: Text('Tuần')),
                      DropdownMenuItem(value: 'month', child: Text('Tháng')),
                      DropdownMenuItem(value: 'year', child: Text('Năm')),
                    ],
                    onChanged: (v) => setState(() => _durUnit = v!),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 5,
          runSpacing: 5,
          children: [
            const Text('Nhanh: ', style: TextStyle(fontSize: 10, color: AppColors.muted)),
            _PresetChip('5p', 5, 'minute'),
            _PresetChip('10p', 10, 'minute'),
            _PresetChip('25p', 25, 'minute'),
            _PresetChip('1g', 1, 'hour'),
            _PresetChip('1 ngày', 1, 'day'),
            _PresetChip('1 tuần', 1, 'week'),
          ],
        ),
      ],
    );
  }

  Widget _PresetChip(String label, int value, String unit) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _durValueController.text = '$value';
          _durUnit = unit;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0x12FFFFFF)),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.muted),
        ),
      ),
    );
  }

  Widget _buildTargetMode() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'CHỌN NGÀY & GIỜ MỤC TIÊU',
          style: TextStyle(
            fontSize: 9,
            color: AppColors.muted,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () async {
            final date = await showDatePicker(
              context: context,
              initialDate: _targetDate ?? DateTime.now().add(const Duration(days: 1)),
              firstDate: DateTime.now(),
              lastDate: DateTime.now().add(const Duration(days: 3650)),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.accent,
                      surface: AppColors.surface,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (date == null) return;

            if (!mounted) return;
            final time = await showTimePicker(
              context: context,
              initialTime: TimeOfDay.fromDateTime(_targetDate ?? DateTime.now()),
              builder: (context, child) {
                return Theme(
                  data: Theme.of(context).copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: AppColors.accent,
                      surface: AppColors.surface,
                    ),
                  ),
                  child: child!,
                );
              },
            );
            if (time == null) return;

            setState(() {
              _targetDate = DateTime(date.year, date.month, date.day, time.hour, time.minute);
              _updateTargetPreview();
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0x10FFFFFF), width: 1.5),
            ),
            child: Text(
              _targetDate != null
                  ? '${_targetDate!.day}/${_targetDate!.month}/${_targetDate!.year} ${_targetDate!.hour.toString().padLeft(2, '0')}:${_targetDate!.minute.toString().padLeft(2, '0')}'
                  : 'Chọn ngày giờ...',
              style: TextStyle(
                fontSize: 13,
                color: _targetDate != null ? AppColors.text : AppColors.muted,
              ),
            ),
          ),
        ),
        if (_targetPreview.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            _targetPreview,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _targetError ? AppColors.danger : AppColors.success,
            ),
          ),
        ],
      ],
    );
  }
}

class _ModeToggle extends StatelessWidget {
  final String mode;
  final ValueChanged<String> onChanged;

  const _ModeToggle({required this.mode, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ModeBtn('Nhập nhanh', 'quick', mode == 'quick', () => onChanged('quick')),
          const SizedBox(width: 2),
          _ModeBtn('Ngày cụ thể', 'target', mode == 'target', () => onChanged('target')),
        ],
      ),
    );
  }
}

class _ModeBtn extends StatelessWidget {
  final String label;
  final String value;
  final bool active;
  final VoidCallback onTap;

  const _ModeBtn(this.label, this.value, this.active, this.onTap);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: active ? AppColors.accent : Colors.transparent,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: active ? Colors.white : AppColors.muted,
          ),
        ),
      ),
    );
  }
}
