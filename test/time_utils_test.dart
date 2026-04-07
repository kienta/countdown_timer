import 'package:flutter_test/flutter_test.dart';
import 'package:countdown_timer/utils/time_utils.dart';

void main() {
  group('pad', () {
    test('pads single digit', () {
      expect(pad(5), '05');
    });

    test('keeps double digit', () {
      expect(pad(12), '12');
    });

    test('pads zero', () {
      expect(pad(0), '00');
    });
  });

  group('formatTime', () {
    test('returns 00:00 for 0 seconds', () {
      expect(formatTime(0), '00:00');
    });

    test('returns 00:00 for negative seconds', () {
      expect(formatTime(-5), '00:00');
    });

    test('formats minutes and seconds', () {
      expect(formatTime(90), '01:30');
    });

    test('formats hours', () {
      expect(formatTime(3661), '01:01:01');
    });

    test('formats days', () {
      expect(formatTime(90061), '1d 01:01:01');
    });
  });

  group('formatDuration', () {
    test('formats zero as 0 giây', () {
      expect(formatDuration(0), '0 giây');
    });

    test('formats seconds only', () {
      expect(formatDuration(45), '45 giây');
    });

    test('formats minutes and seconds', () {
      expect(formatDuration(125), '2 phút 5 giây');
    });

    test('formats hours', () {
      expect(formatDuration(7200), '2 giờ');
    });

    test('formats days', () {
      expect(formatDuration(86400), '1 ngày');
    });

    test('formats mixed units', () {
      expect(formatDuration(90061), '1 ngày 1 giờ 1 phút 1 giây');
    });
  });

  group('secsToUnits', () {
    test('decomposes zero', () {
      final u = secsToUnits(0);
      expect(u.d, 0);
      expect(u.h, 0);
      expect(u.m, 0);
      expect(u.s, 0);
    });

    test('decomposes simple seconds', () {
      final u = secsToUnits(45);
      expect(u.d, 0);
      expect(u.h, 0);
      expect(u.m, 0);
      expect(u.s, 45);
    });

    test('decomposes complex value', () {
      final u = secsToUnits(90061); // 1d 1h 1m 1s
      expect(u.d, 1);
      expect(u.h, 1);
      expect(u.m, 1);
      expect(u.s, 1);
    });
  });

  group('durationToSeconds', () {
    test('converts minutes', () {
      expect(durationToSeconds(5, 'minute'), 300);
    });

    test('converts hours', () {
      expect(durationToSeconds(2, 'hour'), 7200);
    });

    test('converts days', () {
      expect(durationToSeconds(1, 'day'), 86400);
    });

    test('converts weeks', () {
      expect(durationToSeconds(1, 'week'), 604800);
    });

    test('month returns positive value', () {
      expect(durationToSeconds(1, 'month'), greaterThan(0));
    });

    test('year returns positive value', () {
      expect(durationToSeconds(1, 'year'), greaterThan(0));
    });

    test('defaults to minutes for unknown unit', () {
      expect(durationToSeconds(3, 'unknown'), 180);
    });
  });
}
