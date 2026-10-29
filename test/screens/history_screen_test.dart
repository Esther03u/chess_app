import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:chess_app/core/strings.dart';
import 'package:chess_app/models/game_record.dart';
import 'package:chess_app/screens/history_screen.dart';
import 'package:chess_app/services/db_service.dart';

class FakeDbService implements DbService {
  final List<GameRecord> _records = [];
  int _nextId = 1;

  @override
  Future<Database> get database => throw UnimplementedError();

  @override
  Future<int> saveGame(GameRecord g) async {
    final id = _nextId++;
    final recordWithId = g.copyWith(id: id);
    _records.add(recordWithId);
    return id;
  }

  @override
  Future<List<GameRecord>> listGames() async {
    return List.from(_records.reversed);
  }

  @override
  Future<GameRecord?> getGame(int id) async {
    return _records.cast<GameRecord?>().firstWhere(
      (g) => g?.id == id,
      orElse: () => null,
    );
  }

  @override
  Future<void> saveAnalysis(int gameId, String json) async {}

  @override
  Future<int> deleteGame(int id) async {
    _records.removeWhere((g) => g.id == id);
    return 1;
  }

  @override
  Future<int> clearAll() async {
    final count = _records.length;
    _records.clear();
    return count;
  }

  final Map<String, String> _settings = {};

  @override
  Future<String?> getSetting(String key) async => _settings[key];

  @override
  Future<void> setSetting(String key, String value) async {
    _settings[key] = value;
  }

  @override
  Future<void> removeSetting(String key) async {
    _settings.remove(key);
  }

  @override
  Future<void> close() async {}
}

void main() {
  group('HistoryScreen and GameReplayScreen - FR4 UI Acceptance', () {
    late FakeDbService fakeDb;

    setUp(() {
      fakeDb = FakeDbService();
    });

    testWidgets('Displays empty state message when no games are recorded', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(home: HistoryScreen(dbService: fakeDb)),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text(AppStrings.noGamesYet), findsOneWidget);
    });

    testWidgets('Displays game cards and opens GameReplayScreen on tap', (
      WidgetTester tester,
    ) async {
      // Scholar's mate PGN
      const pgn = '1. e4 e5 2. Bc4 Nc6 3. Qh5 Nf6 4. Qxf7# 1-0';
      await fakeDb.saveGame(
        const GameRecord(
          pgn: pgn,
          white: 'Somchai',
          black: 'Bot (Hard)',
          result: '1-0',
          timeControl: '3 + 2',
          playedAt: 1730200000000,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(home: HistoryScreen(dbService: fakeDb)),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Verify card content
      expect(find.text('Somchai vs Bot (Hard)'), findsOneWidget);
      expect(find.text('1-0'), findsOneWidget);
      expect(find.text('3 + 2'), findsOneWidget);

      // Tap card to open Replay screen
      await tester.tap(find.text('Somchai vs Bot (Hard)'));
      await tester.pump();
      await tester.pump(
        const Duration(milliseconds: 300),
      ); // finish route transition

      // Verify GameReplayScreen is open with replay controls
      expect(find.byType(GameReplayScreen), findsOneWidget);
      expect(find.byIcon(Icons.first_page), findsOneWidget);
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      expect(find.byIcon(Icons.last_page), findsOneWidget);
      expect(find.textContaining('ตาเดิน:'), findsOneWidget);
    });
  });
}
