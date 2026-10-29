import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:chess_app/domain/classification.dart';
import 'package:chess_app/models/analysis_result.dart';
import 'package:chess_app/models/game_record.dart';
import 'package:chess_app/services/analysis_service.dart';
import 'package:chess_app/services/db_service.dart';
import 'package:sqflite/sqflite.dart';

class FakeDbService implements DbService {
  final Map<int, String> analysisStore = {};

  @override
  Future<Database> get database => throw UnimplementedError();

  @override
  Future<void> saveAnalysis(int gameId, String json) async {
    analysisStore[gameId] = json;
  }

  @override
  Future<int> saveGame(GameRecord g) async => 1;

  @override
  Future<List<GameRecord>> listGames() async => [];

  @override
  Future<GameRecord?> getGame(int id) async => null;

  @override
  Future<int> deleteGame(int id) async => 1;

  @override
  Future<int> clearAll() async => 0;

  @override
  Future<void> close() async {}
}

void main() {
  group('AnalysisService - FR6 Algorithm & Persistence', () {
    const scholarsMatePgn = '1. e4 e5 2. Bc4 Nc6 3. Qh5 Nf6 4. Qxf7# 1-0';

    test('analyzeGame produces complete move evaluations, accuracy, and classifications', () async {
      final fakeDb = FakeDbService();
      final service = AnalysisService(dbService: fakeDb);

      final progressList = <double>[];
      final analysis = await service.analyzeGame(
        pgn: scholarsMatePgn,
        gameId: 42,
        onProgress: (p) => progressList.add(p),
      );

      // Verify progress callback reached 1.0
      expect(progressList, isNotEmpty);
      expect(progressList.last, equals(1.0));

      // Scholar's Mate has 7 half moves: e4, e5, Bc4, Nc6, Qh5, Nf6, Qxf7#
      expect(analysis.moves.length, equals(7));

      // Check move 7: White plays Qxf7# (checkmate)
      final mateMove = analysis.moves.last;
      expect(mateMove.san, equals('Qxf7#'));
      expect(mateMove.isWhite, isTrue);
      expect(mateMove.classification, equals(MoveClassification.best));

      // Check White and Black accuracy ranges
      expect(analysis.whiteAccuracy, inInclusiveRange(0.0, 100.0));
      expect(analysis.blackAccuracy, inInclusiveRange(0.0, 100.0));

      // Verify DB caching was invoked with gameId 42
      expect(fakeDb.analysisStore.containsKey(42), isTrue);
      final cachedJson =
          jsonDecode(fakeDb.analysisStore[42]!) as Map<String, dynamic>;
      final reloaded = GameAnalysis.fromJson(cachedJson);
      expect(reloaded.moves.length, equals(7));
      expect(reloaded.whiteAccuracy, equals(analysis.whiteAccuracy));
    });

    test('GameAnalysis JSON serialization roundtrip', () {
      const move = AnalyzedMove(
        ply: 0,
        moveNumber: 1,
        isWhite: true,
        san: 'e4',
        uci: 'e2e4',
        fen: 'rnbqkbnr/pppppppp/8/8/4P3/8/PPPP1PPP/RNBQKBNR b KQkq e3 0 1',
        evalWhiteCp: 35,
        evalBefore: 30,
        evalAfter: 35,
        winLoss: 0.0,
        accuracy: 99.5,
        classification: MoveClassification.best,
        bestMove: 'e2e4',
      );

      final original = GameAnalysis(
        moves: [move],
        whiteAccuracy: 99.5,
        blackAccuracy: 0.0,
        whiteSummary: {MoveClassification.best: 1},
        blackSummary: {},
      );

      final json = original.toJson();
      final restored = GameAnalysis.fromJson(json);

      expect(restored.moves.length, equals(1));
      expect(restored.moves.first.san, equals('e4'));
      expect(
        restored.moves.first.classification,
        equals(MoveClassification.best),
      );
      expect(restored.whiteAccuracy, equals(99.5));
    });
  });
}
