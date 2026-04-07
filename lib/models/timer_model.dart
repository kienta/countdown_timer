class TimerModel {
  final int id;
  String title;
  String mode; // 'duration' or 'target'
  int totalSeconds;
  int remainSeconds;
  int elapsedSecs;
  String? targetValue;
  bool running;
  bool finished;
  int? savedAt;
  int? createdAt;

  TimerModel({
    required this.id,
    this.title = 'Bộ đếm',
    this.mode = 'duration',
    this.totalSeconds = 0,
    this.remainSeconds = 0,
    this.elapsedSecs = 0,
    this.targetValue,
    this.running = false,
    this.finished = false,
    this.savedAt,
    this.createdAt,
  });

  factory TimerModel.fromMap(Map<String, dynamic> map) {
    return TimerModel(
      id: map['id'] as int,
      title: (map['title'] as String?) ?? 'Bộ đếm',
      mode: (map['mode'] as String?) ?? 'duration',
      totalSeconds: (map['totalSeconds'] as int?) ?? 0,
      remainSeconds: (map['remainSeconds'] as int?) ?? 0,
      elapsedSecs: (map['elapsedSecs'] as int?) ?? 0,
      targetValue: map['targetValue'] as String?,
      running: (map['running'] as int?) == 1,
      finished: (map['finished'] as int?) == 1,
      savedAt: map['savedAt'] as int?,
      createdAt: map['createdAt'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'mode': mode,
      'totalSeconds': totalSeconds,
      'remainSeconds': remainSeconds,
      'elapsedSecs': elapsedSecs,
      'targetValue': targetValue,
      'running': running ? 1 : 0,
      'finished': finished ? 1 : 0,
      'savedAt': savedAt ?? DateTime.now().millisecondsSinceEpoch,
      'createdAt': createdAt ?? DateTime.now().millisecondsSinceEpoch,
    };
  }

  TimerModel copyWith({
    int? id,
    String? title,
    String? mode,
    int? totalSeconds,
    int? remainSeconds,
    int? elapsedSecs,
    String? targetValue,
    bool? running,
    bool? finished,
    int? savedAt,
    int? createdAt,
  }) {
    return TimerModel(
      id: id ?? this.id,
      title: title ?? this.title,
      mode: mode ?? this.mode,
      totalSeconds: totalSeconds ?? this.totalSeconds,
      remainSeconds: remainSeconds ?? this.remainSeconds,
      elapsedSecs: elapsedSecs ?? this.elapsedSecs,
      targetValue: targetValue ?? this.targetValue,
      running: running ?? this.running,
      finished: finished ?? this.finished,
      savedAt: savedAt ?? this.savedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Adjust timer data for time passed while app was closed
  void adjustForElapsedTime() {
    if (!running || finished) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final real = ((now - (savedAt ?? now)) / 1000).floor();
    if (real <= 0) return;

    if (mode == 'target' && targetValue != null) {
      final target = DateTime.parse(targetValue!);
      remainSeconds = (target.difference(DateTime.now()).inSeconds).clamp(0, totalSeconds);
    } else {
      remainSeconds = (remainSeconds - real).clamp(0, totalSeconds);
    }
    elapsedSecs = (elapsedSecs + real).clamp(0, totalSeconds);

    if (remainSeconds <= 0) {
      finished = true;
      running = false;
    }
  }

  String get statusText {
    if (finished) return 'Hoàn thành';
    if (running) return 'Đang chạy';
    if (elapsedSecs > 0) return 'Tạm dừng';
    return 'Sẵn sàng';
  }

  String get statusKey {
    if (finished) return 'done';
    if (running) return 'running';
    if (elapsedSecs > 0) return 'paused';
    return 'ready';
  }

  double get progress {
    if (totalSeconds <= 0) return 0;
    return ((totalSeconds - remainSeconds) / totalSeconds).clamp(0.0, 1.0);
  }

  bool get isLow {
    if (totalSeconds <= 0) return false;
    final pct = remainSeconds / totalSeconds;
    return (pct <= 0.1 || remainSeconds <= 10) && !finished;
  }
}
