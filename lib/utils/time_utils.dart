String pad(int n) => n.toString().padLeft(2, '0');

String formatTime(int secs) {
  if (secs <= 0) return '00:00';
  final d = secs ~/ 86400;
  final h = (secs % 86400) ~/ 3600;
  final m = (secs % 3600) ~/ 60;
  final s = secs % 60;
  if (d > 0) return '${d}d ${pad(h)}:${pad(m)}:${pad(s)}';
  if (h > 0) return '${pad(h)}:${pad(m)}:${pad(s)}';
  return '${pad(m)}:${pad(s)}';
}

String formatDuration(int secs) {
  final d = secs ~/ 86400;
  final h = (secs % 86400) ~/ 3600;
  final m = (secs % 3600) ~/ 60;
  final s = secs % 60;
  final parts = <String>[];
  if (d > 0) parts.add('$d ngày');
  if (h > 0) parts.add('$h giờ');
  if (m > 0) parts.add('$m phút');
  if (s > 0 || parts.isEmpty) parts.add('$s giây');
  return parts.join(' ');
}

({int d, int h, int m, int s}) secsToUnits(int secs) {
  return (
    d: secs ~/ 86400,
    h: (secs % 86400) ~/ 3600,
    m: (secs % 3600) ~/ 60,
    s: secs % 60,
  );
}

int durationToSeconds(int value, String unit) {
  switch (unit) {
    case 'minute':
      return value * 60;
    case 'hour':
      return value * 3600;
    case 'day':
      return value * 86400;
    case 'week':
      return value * 7 * 86400;
    case 'month':
      final now = DateTime.now();
      final target = DateTime(now.year, now.month + value, now.day, now.hour, now.minute, now.second);
      return target.difference(now).inSeconds;
    case 'year':
      final now = DateTime.now();
      final target = DateTime(now.year + value, now.month, now.day, now.hour, now.minute, now.second);
      return target.difference(now).inSeconds;
    default:
      return value * 60;
  }
}
