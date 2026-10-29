import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:chess_app/models/game_record.dart';
import 'package:chess_app/services/db_service.dart';

void main() {
  // Setup FFI for SQLite on desktop test runner
  sqfliteFfiInit();

  group('DbService - FR4 SQLite Game Persistence', () {
    late Database database;
    late DbService dbService;

    setUp(() async {
      // Use in-memory SQLite database for clean, isolated tests
      final dbFactory = databaseFactoryFfi;
      database = await dbFactory.openDatabase(inMemoryDatabasePath);
      await database.execute('''
        CREATE TABLE ${DbService.tableName} (
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
      dbService = DbService(database);
    });

    tearDown(() async {
      await dbService.close();
    });

    test(
      'saveGame persists a game record and returns auto-incremented ID',
      () async {
        const record = GameRecord(
          pgn: '1. e4 e5 2. Nf3 Nc6',
          white: 'Player 1',
          black: 'Bot (Medium)',
          result: '1-0',
          timeControl: '10 + 0',
          playedAt: 1730200000000,
        );

        final id = await dbService.saveGame(record);
        expect(id, isPositive);

        final fetched = await dbService.getGame(id);
        expect(fetched, isNotNull);
        expect(fetched!.pgn, equals(record.pgn));
        expect(fetched.white, equals('Player 1'));
        expect(fetched.black, equals('Bot (Medium)'));
        expect(fetched.result, equals('1-0'));
        expect(fetched.timeControl, equals('10 + 0'));
        expect(fetched.playedAt, equals(1730200000000));
        expect(fetched.analysisJson, isNull);
      },
    );

    test(
      'listGames returns all records sorted by played_at descending',
      () async {
        await dbService.saveGame(
          const GameRecord(pgn: '1. e4', playedAt: 1000, result: '1-0'),
        );
        await dbService.saveGame(
          const GameRecord(pgn: '1. d4', playedAt: 3000, result: '0-1'),
        );
        await dbService.saveGame(
          const GameRecord(pgn: '1. c4', playedAt: 2000, result: '1/2-1/2'),
        );

        final list = await dbService.listGames();
        expect(list.length, equals(3));
        // Most recent first: 3000, 2000, 1000
        expect(list[0].playedAt, equals(3000));
        expect(list[1].playedAt, equals(2000));
        expect(list[2].playedAt, equals(1000));
      },
    );

    test('saveAnalysis updates analysis_json field', () async {
      final id = await dbService.saveGame(
        const GameRecord(pgn: '1. e4 e5', playedAt: 1000),
      );

      await dbService.saveAnalysis(id, '{"accuracy": 92.5}');

      final updated = await dbService.getGame(id);
      expect(updated?.analysisJson, equals('{"accuracy": 92.5}'));
    });

    test('deleteGame removes the record from database', () async {
      final id = await dbService.saveGame(
        const GameRecord(pgn: '1. e4 e5', playedAt: 1000),
      );

      final deletedCount = await dbService.deleteGame(id);
      expect(deletedCount, equals(1));

      final fetched = await dbService.getGame(id);
      expect(fetched, isNull);
    });
  });
}
