import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chess_app/domain/game_logic.dart';
import 'package:chess_app/models/puzzle.dart';
import 'package:chess_app/services/lichess_api.dart';

void main() {
  group('Lichess Daily Puzzle API & Model', () {
    late Map<String, dynamic> fixtureJson;

    setUpAll(() {
      final file = File('test/fixtures/puzzle_daily.json');
      final jsonString = file.readAsStringSync();
      fixtureJson = jsonDecode(jsonString) as Map<String, dynamic>;
    });

    test(
      'DailyPuzzle parser accurately parses real Lichess response fixture',
      () {
        final puzzle = DailyPuzzle.fromJson(fixtureJson);

        expect(puzzle.id, equals('Ba42D'));
        expect(puzzle.rating, equals(1763));
        expect(puzzle.plays, equals(50169));
        expect(
          puzzle.solution,
          equals(['c4a5', 'c6b5', 'e6c4', 'b5a5', 'c4a4']),
        );
        expect(
          puzzle.themes,
          containsAll([
            'exposedKing',
            'middlegame',
            'long',
            'mateIn3',
            'sacrifice',
          ]),
        );
        expect(
          puzzle.fen,
          equals('rn5r/ppp3pp/2kbQn2/8/2N1p3/1P2B3/P1P2PPP/qN2K2R w K - 0 1'),
        );
        expect(puzzle.lastMove, equals('d4a1'));
        expect(puzzle.initialPly, equals(23));

        expect(puzzle.gameId, equals('LoUKdeXr'));
        expect(puzzle.whitePlayerName, equals('davidzapl'));
        expect(puzzle.whitePlayerRating, equals(1563));
        expect(puzzle.blackPlayerName, equals('DimKus'));
        expect(puzzle.blackPlayerRating, equals(1534));
      },
    );

    test('Starting position derivation: puzzle.fen matches starting turn and solution[0] is legal', () {
      final puzzle = DailyPuzzle.fromJson(fixtureJson);
      final game = GameLogic(puzzle.fen);

      // In this puzzle, it's White's turn
      expect(game.turn, equals(PlayerColor.white));

      // The first move in the solution is 'c4a5' (from c4 to a5)
      final firstMoveFrom = puzzle.solution[0].substring(0, 2); // 'c4'
      final firstMoveTo = puzzle.solution[0].substring(2, 4); // 'a5'

      final legalMovesFromC4 = game.legalMovesFrom(firstMoveFrom);
      expect(legalMovesFromC4, contains(firstMoveTo));

      // Execute the first move (player's move)
      final moveRes1 = game.tryMove(firstMoveFrom, firstMoveTo);
      expect(moveRes1.success, isTrue);
      expect(game.turn, equals(PlayerColor.black));

      // Execute the second move (opponent's response 'c6b5')
      final secondMoveFrom = puzzle.solution[1].substring(0, 2); // 'c6'
      final secondMoveTo = puzzle.solution[1].substring(2, 4); // 'b5'
      final moveRes2 = game.tryMove(secondMoveFrom, secondMoveTo);
      expect(moveRes2.success, isTrue);
    });

    test('Deriving puzzle starting position by replaying game.pgn up to initialPly', () {
      final puzzle = DailyPuzzle.fromJson(fixtureJson);

      // Replay pgn moves in game logic
      final game = GameLogic();
      game.loadPgn(puzzle.gamePgn);

      // PGN has 24 plies (12 full moves), matching initialPly index 23
      expect(game.history.length, equals(24));

      // Confirm puzzle.fen is valid and has expected pieces
      final puzzleGame = GameLogic(puzzle.fen);
      expect(puzzleGame.getPiece('c4')?.type, equals(PieceType.knight));
      expect(puzzleGame.getPiece('c4')?.color, equals(PlayerColor.white));
      expect(puzzleGame.getPiece('c6')?.type, equals(PieceType.king));
      expect(puzzleGame.getPiece('c6')?.color, equals(PlayerColor.black));
    });

    test('DailyPuzzle parser handles null/empty/malformed JSON safely without crashing', () {
      final emptyPuzzle = DailyPuzzle.fromJson({});
      expect(emptyPuzzle.id, equals(''));
      expect(emptyPuzzle.rating, equals(0));
      expect(emptyPuzzle.solution, isEmpty);
      expect(emptyPuzzle.themes, isEmpty);
      expect(emptyPuzzle.fen, equals(''));
      expect(emptyPuzzle.whitePlayerName, isNull);
    });

    test(
      'LichessApi handles network errors with user-friendly ApiException',
      () async {
        final dio = Dio();
        // Use an invalid host to trigger DioExceptionType.connectionError
        final api = LichessApi(
          dio: dio,
          endpoint: 'https://invalid-non-existent-lichess-domain-xyz.org/api/puzzle/daily',
        );

        expect(
          () async => await api.dailyPuzzle(),
          throwsA(isA<ApiException>()),
        );
      },
    );
  });
}
