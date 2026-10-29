import 'package:flutter_test/flutter_test.dart';
import 'package:chess_app/domain/game_logic.dart';

void main() {
  group('PGN Round-Trip - FR4 History Replayability', () {
    test(
      'Round-trip of standard moves produces identical board state and history',
      () {
        final original = GameLogic();

        // Play Scholar's mate moves: 1. e4 e5 2. Bc4 Nc6 3. Qh5 Nf6 4. Qxf7#
        expect(original.tryMove('e2', 'e4').success, isTrue);
        expect(original.tryMove('e7', 'e5').success, isTrue);
        expect(original.tryMove('f1', 'c4').success, isTrue);
        expect(original.tryMove('b8', 'c6').success, isTrue);
        expect(original.tryMove('d1', 'h5').success, isTrue);
        expect(original.tryMove('g8', 'f6').success, isTrue);
        expect(original.tryMove('h5', 'f7').success, isTrue);

        expect(original.isCheckmate, isTrue);
        expect(original.result, equals('1-0'));

        // Export to PGN
        final pgn = original.toPgn();
        expect(pgn.isNotEmpty, isTrue);

        // Replay on fresh GameLogic
        final reloaded = GameLogic();
        reloaded.loadPgn(pgn);

        expect(reloaded.fen, equals(original.fen));
        expect(reloaded.isCheckmate, isTrue);
        expect(reloaded.turn, equals(original.turn));
        expect(reloaded.history, equals(original.history));
      },
    );

    test('Round-trip preserves castling and en passant moves', () {
      final original = GameLogic();

      // Setup castling: 1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. O-O
      expect(original.tryMove('e2', 'e4').success, isTrue);
      expect(original.tryMove('e7', 'e5').success, isTrue);
      expect(original.tryMove('g1', 'f3').success, isTrue);
      expect(original.tryMove('b8', 'c6').success, isTrue);
      expect(original.tryMove('f1', 'c4').success, isTrue);
      expect(original.tryMove('f8', 'c5').success, isTrue);
      expect(original.tryMove('e1', 'g1').success, isTrue); // Kingside castling

      final pgn = original.toPgn();

      final reloaded = GameLogic();
      reloaded.loadPgn(pgn);
      expect(reloaded.fen, equals(original.fen));
      expect(reloaded.history, equals(original.history));
      expect(reloaded.getPiece('g1')?.type, equals(PieceType.king));
      expect(reloaded.getPiece('f1')?.type, equals(PieceType.rook));
    });

    test('Round-trip preserves pawn promotion', () {
      final original = GameLogic();

      final moves = [
        ['e2', 'e4'],
        ['d7', 'd5'],
        ['e4', 'd5'],
        ['c7', 'c6'],
        ['d5', 'c6'],
        ['a7', 'a6'],
        ['c6', 'b7'],
        ['a6', 'a5'],
      ];

      for (final move in moves) {
        expect(original.tryMove(move[0], move[1]).success, isTrue);
      }

      // Promote pawn by capturing Rook on a8 as Queen
      final promoResult = original.tryMove('b7', 'a8', promotion: 'q');
      expect(promoResult.success, isTrue);
      expect(original.getPiece('a8')?.type, equals(PieceType.queen));

      final pgn = original.toPgn();

      final reloaded = GameLogic();
      reloaded.loadPgn(pgn);
      expect(reloaded.fen, equals(original.fen));
      expect(reloaded.getPiece('a8')?.type, equals(PieceType.queen));
    });
  });
}
