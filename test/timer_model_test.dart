import 'package:flutter_test/flutter_test.dart';
import 'package:countdown_timer/models/timer_model.dart';

void main() {
  group('TimerModel.fromMap', () {
    test('parses all fields correctly', () {
      final map = {
        'id': 1,
        'title': 'Test',
        'mode': 'duration',
        'totalSeconds': 300,
        'remainSeconds': 200,
        'elapsedSecs': 100,
        'targetValue': null,
        'running': 1,
        'finished': 0,
        'savedAt': 1000000,
        'createdAt': 900000,
      };
      final t = TimerModel.fromMap(map);
      expect(t.id, 1);
      expect(t.title, 'Test');
      expect(t.mode, 'duration');
      expect(t.totalSeconds, 300);
      expect(t.remainSeconds, 200);
      expect(t.elapsedSecs, 100);
      expect(t.running, true);
      expect(t.finished, false);
      expect(t.savedAt, 1000000);
      expect(t.createdAt, 900000);
    });

    test('uses defaults for missing values', () {
      final map = {'id': 2};
      final t = TimerModel.fromMap(map);
      expect(t.title, 'Bộ đếm');
      expect(t.mode, 'duration');
      expect(t.totalSeconds, 0);
      expect(t.remainSeconds, 0);
      expect(t.elapsedSecs, 0);
      expect(t.running, false);
      expect(t.finished, false);
    });
  });

  group('TimerModel.toMap', () {
    test('serializes booleans to integers', () {
      final t = TimerModel(id: 1, running: true, finished: false);
      final map = t.toMap();
      expect(map['running'], 1);
      expect(map['finished'], 0);
    });

    test('includes all fields', () {
      final t = TimerModel(
        id: 5,
        title: 'My Timer',
        mode: 'target',
        totalSeconds: 600,
        remainSeconds: 300,
        elapsedSecs: 300,
        targetValue: '2026-12-31T00:00:00',
        running: false,
        finished: true,
        savedAt: 100,
        createdAt: 50,
      );
      final map = t.toMap();
      expect(map['id'], 5);
      expect(map['title'], 'My Timer');
      expect(map['mode'], 'target');
      expect(map['totalSeconds'], 600);
      expect(map['targetValue'], '2026-12-31T00:00:00');
    });
  });

  group('TimerModel.copyWith', () {
    test('overrides specified fields only', () {
      final t = TimerModel(id: 1, title: 'A', totalSeconds: 100);
      final t2 = t.copyWith(title: 'B');
      expect(t2.title, 'B');
      expect(t2.id, 1);
      expect(t2.totalSeconds, 100);
    });

    test('preserves all fields when no overrides', () {
      final t = TimerModel(
        id: 3,
        title: 'Test',
        mode: 'target',
        totalSeconds: 500,
        remainSeconds: 250,
        elapsedSecs: 250,
        running: true,
        finished: false,
      );
      final t2 = t.copyWith();
      expect(t2.id, t.id);
      expect(t2.title, t.title);
      expect(t2.mode, t.mode);
      expect(t2.totalSeconds, t.totalSeconds);
      expect(t2.running, t.running);
    });
  });

  group('TimerModel.progress', () {
    test('returns 0 when totalSeconds is 0', () {
      final t = TimerModel(id: 1, totalSeconds: 0, remainSeconds: 0);
      expect(t.progress, 0.0);
    });

    test('returns 0 at start', () {
      final t = TimerModel(id: 1, totalSeconds: 100, remainSeconds: 100);
      expect(t.progress, 0.0);
    });

    test('returns 0.5 at halfway', () {
      final t = TimerModel(id: 1, totalSeconds: 100, remainSeconds: 50);
      expect(t.progress, 0.5);
    });

    test('returns 1.0 when done', () {
      final t = TimerModel(id: 1, totalSeconds: 100, remainSeconds: 0);
      expect(t.progress, 1.0);
    });
  });

  group('TimerModel.isLow', () {
    test('returns false when totalSeconds is 0', () {
      final t = TimerModel(id: 1, totalSeconds: 0, remainSeconds: 0);
      expect(t.isLow, false);
    });

    test('returns false when above 10%', () {
      final t = TimerModel(id: 1, totalSeconds: 100, remainSeconds: 20);
      expect(t.isLow, false);
    });

    test('returns true when at 10%', () {
      final t = TimerModel(id: 1, totalSeconds: 100, remainSeconds: 10);
      expect(t.isLow, true);
    });

    test('returns true when remain <= 10 seconds', () {
      final t = TimerModel(id: 1, totalSeconds: 1000, remainSeconds: 8);
      expect(t.isLow, true);
    });

    test('returns false when finished', () {
      final t = TimerModel(
        id: 1,
        totalSeconds: 100,
        remainSeconds: 0,
        finished: true,
      );
      expect(t.isLow, false);
    });
  });

  group('TimerModel.statusText', () {
    test('returns Hoàn thành when finished', () {
      final t = TimerModel(id: 1, finished: true);
      expect(t.statusText, 'Hoàn thành');
      expect(t.statusKey, 'done');
    });

    test('returns Đang chạy when running', () {
      final t = TimerModel(id: 1, running: true);
      expect(t.statusText, 'Đang chạy');
      expect(t.statusKey, 'running');
    });

    test('returns Tạm dừng when paused', () {
      final t = TimerModel(id: 1, running: false, elapsedSecs: 10);
      expect(t.statusText, 'Tạm dừng');
      expect(t.statusKey, 'paused');
    });

    test('returns Sẵn sàng when ready', () {
      final t = TimerModel(id: 1, running: false, elapsedSecs: 0);
      expect(t.statusText, 'Sẵn sàng');
      expect(t.statusKey, 'ready');
    });
  });

  group('TimerModel.adjustForElapsedTime', () {
    test('does nothing when not running', () {
      final t = TimerModel(
        id: 1,
        totalSeconds: 100,
        remainSeconds: 80,
        elapsedSecs: 20,
        running: false,
        savedAt: DateTime.now().subtract(const Duration(seconds: 30)).millisecondsSinceEpoch,
      );
      t.adjustForElapsedTime();
      expect(t.remainSeconds, 80);
      expect(t.elapsedSecs, 20);
    });

    test('does nothing when finished', () {
      final t = TimerModel(
        id: 1,
        totalSeconds: 100,
        remainSeconds: 0,
        elapsedSecs: 100,
        running: false,
        finished: true,
        savedAt: DateTime.now().subtract(const Duration(seconds: 30)).millisecondsSinceEpoch,
      );
      t.adjustForElapsedTime();
      expect(t.remainSeconds, 0);
      expect(t.elapsedSecs, 100);
    });

    test('reduces remainSeconds for elapsed time in duration mode', () {
      final saved = DateTime.now().subtract(const Duration(seconds: 10)).millisecondsSinceEpoch;
      final t = TimerModel(
        id: 1,
        mode: 'duration',
        totalSeconds: 100,
        remainSeconds: 50,
        elapsedSecs: 50,
        running: true,
        savedAt: saved,
      );
      t.adjustForElapsedTime();
      expect(t.remainSeconds, closeTo(40, 2));
      expect(t.elapsedSecs, closeTo(60, 2));
    });

    test('marks as finished when time runs out', () {
      final saved = DateTime.now().subtract(const Duration(seconds: 100)).millisecondsSinceEpoch;
      final t = TimerModel(
        id: 1,
        mode: 'duration',
        totalSeconds: 60,
        remainSeconds: 30,
        elapsedSecs: 30,
        running: true,
        savedAt: saved,
      );
      t.adjustForElapsedTime();
      expect(t.finished, true);
      expect(t.running, false);
      expect(t.remainSeconds, 0);
    });
  });
}
