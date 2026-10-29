import 'dart:async';

import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/game_record.dart';

/// Database service managing SQLite storage for chess games and PGN history (§3.5).
class DbService {
  static const String tableName = 'games';
  static const String settingsTableName = 'settings';
  static const String dbName = 'chess_app.db';
  static const int dbVersion = 2;

  Database? _db;

  /// Creates a DbService, optionally with a pre-configured [database] (useful for tests).
  DbService([Database? database]) : _db = database;

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final databasesPath = await getDatabasesPath();
    final path = p.join(databasesPath, dbName);

    return await openDatabase(
      path,
      version: dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableName (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        pgn TEXT NOT NULL,
        white TEXT,
        black TEXT,
        result TEXT,
        time_control TEXT,
        played_at INTEGER,
        analysis_json TEXT
      )
    ''');
    await db.execute('''
      CREATE TABLE IF NOT EXISTS $settingsTableName (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $settingsTableName (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
    }
  }

  /// Saves a finished game to SQLite, returns the generated ID.
  Future<int> saveGame(GameRecord g) async {
    final db = await database;
    return await db.insert(
      tableName,
      g.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Lists all stored games in descending order (most recent first).
  Future<List<GameRecord>> listGames() async {
    final db = await database;
    final maps = await db.query(tableName, orderBy: 'played_at DESC');
    return maps.map((m) => GameRecord.fromMap(m)).toList();
  }

  /// Fetches a game record by its unique ID.
  Future<GameRecord?> getGame(int id) async {
    final db = await database;
    final maps = await db.query(
      tableName,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );
    if (maps.isNotEmpty) {
      return GameRecord.fromMap(maps.first);
    }
    return null;
  }

  /// Updates or saves cached post-game analysis JSON (§3.4).
  Future<void> saveAnalysis(int gameId, String json) async {
    final db = await database;
    await db.update(
      tableName,
      {'analysis_json': json},
      where: 'id = ?',
      whereArgs: [gameId],
    );
  }

  /// Deletes a game record by ID.
  Future<int> deleteGame(int id) async {
    final db = await database;
    return await db.delete(tableName, where: 'id = ?', whereArgs: [id]);
  }

  /// Clears all game history.
  Future<int> clearAll() async {
    final db = await database;
    return await db.delete(tableName);
  }

  /// Gets a setting value by key from SQLite.
  Future<String?> getSetting(String key) async {
    final db = await database;
    final results = await db.query(
      settingsTableName,
      where: 'key = ?',
      whereArgs: [key],
      limit: 1,
    );
    if (results.isNotEmpty) {
      return results.first['value'] as String?;
    }
    return null;
  }

  /// Sets or updates a setting key-value pair in SQLite.
  Future<void> setSetting(String key, String value) async {
    final db = await database;
    await db.insert(settingsTableName, {
      'key': key,
      'value': value,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Removes a setting by key.
  Future<void> removeSetting(String key) async {
    final db = await database;
    await db.delete(settingsTableName, where: 'key = ?', whereArgs: [key]);
  }

  /// Closes database connection.
  Future<void> close() async {
    if (_db != null && _db!.isOpen) {
      await _db!.close();
      _db = null;
    }
  }
}
