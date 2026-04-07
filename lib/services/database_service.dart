import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import '../models/timer_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Database? _db;

  Future<void> init() async {
    if (_db != null) return;

    // Use FFI for desktop platforms
    if (!kIsWeb && (Platform.isWindows || Platform.isLinux || Platform.isMacOS)) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    final dir = await getApplicationDocumentsDirectory();
    final dbPath = p.join(dir.path, 'countdown_timer', 'timers.db');

    // Ensure directory exists
    final dbDir = Directory(p.dirname(dbPath));
    if (!await dbDir.exists()) {
      await dbDir.create(recursive: true);
    }

    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE IF NOT EXISTS timers (
            id            INTEGER PRIMARY KEY,
            title         TEXT    NOT NULL DEFAULT 'Bộ đếm',
            mode          TEXT    NOT NULL DEFAULT 'duration',
            totalSeconds  INTEGER NOT NULL DEFAULT 0,
            remainSeconds INTEGER NOT NULL DEFAULT 0,
            elapsedSecs   INTEGER NOT NULL DEFAULT 0,
            fallenCount   INTEGER NOT NULL DEFAULT 0,
            targetValue   TEXT,
            running       INTEGER NOT NULL DEFAULT 0,
            finished      INTEGER NOT NULL DEFAULT 0,
            savedAt       INTEGER,
            createdAt     INTEGER NOT NULL DEFAULT 0
          )
        ''');
        await db.execute('''
          CREATE TABLE IF NOT EXISTS meta (
            key   TEXT PRIMARY KEY,
            value TEXT
          )
        ''');
      },
    );
  }

  Future<List<TimerModel>> getAllTimers() async {
    final maps = await _db!.query('timers', orderBy: 'createdAt DESC');
    return maps.map((m) => TimerModel.fromMap(m)).toList();
  }

  Future<TimerModel?> getTimer(int id) async {
    final maps = await _db!.query('timers', where: 'id = ?', whereArgs: [id]);
    if (maps.isEmpty) return null;
    return TimerModel.fromMap(maps.first);
  }

  Future<void> upsertTimer(TimerModel timer) async {
    await _db!.insert(
      'timers',
      timer.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> deleteTimer(int id) async {
    await _db!.delete('timers', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> getMaxId() async {
    final result = await _db!.query('meta', where: "key = 'maxId'");
    if (result.isNotEmpty) {
      return int.tryParse(result.first['value'] as String? ?? '0') ?? 0;
    }
    return 0;
  }

  Future<void> setMaxId(int n) async {
    await _db!.insert(
      'meta',
      {'key': 'maxId', 'value': '$n'},
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<int> getNextId() async {
    final maxId = await getMaxId();
    final nextId = maxId + 1;
    await setMaxId(nextId);
    return nextId;
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }
}
