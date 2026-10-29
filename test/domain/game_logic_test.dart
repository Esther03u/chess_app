import 'package:flutter_test/flutter_test.dart';
import 'package:chess_app/domain/game_logic.dart';

void main() {
  group('GameLogic - FR1 Full Chess Rules', () {
    late GameLogic game;

    setUp(() {
      game = GameLogic();
    });

    test('Initial board state is correct', () {
      expect(
        game.fen,
        equals('rnbqkbnr/pppppppp/8/8/8/8/PPPPPPPP/RNBQKBNR w KQkq - 0 1'),
      );
      expect(game.isGameOver, isFalse);
      expect(game.turn, equals(PlayerColor.white));
      expect(game.result, isNull);
    });

    test('Legal moves from square returns valid destinations', () {
      final movesE2 = game.legalMovesFrom('e2');
      expect(movesE2, containsAll(['e3', 'e4']));
      expect(movesE2.length, equals(2));

      final movesB1 = game.legalMovesFrom('b1');
      expect(movesB1, containsAll(['a3', 'c3']));

      // Empty square has no legal moves
      expect(game.legalMovesFrom('e4'), isEmpty);
    });

    test('Normal moves alternate turns and update FEN', () {
      final res1 = game.tryMove('e2', 'e4');
      expect(res1.success, isTrue);
      expect(game.turn, equals(PlayerColor.black));

      final res2 = game.tryMove('e7', 'e5');
      expect(res2.success, isTrue);
      expect(game.turn, equals(PlayerColor.white));
    });

    test('Illegal move is rejected without changing state', () {
      final initialFen = game.fen;
      final res = game.tryMove('e2', 'e5'); // illegal leap
      expect(res.success, isFalse);
      expect(game.fen, equals(initialFen));
      expect(game.turn, equals(PlayerColor.white));
    });

    test('Kingside and Queenside castling works when legal', () {
      // Setup White Kingside castling: 1. e4 e5 2. Nf3 Nc6 3. Bc4 Bc5 4. O-O
      game.tryMove('e2', 'e4');
      game.tryMove('e7', 'e5');
      game.tryMove('g1', 'f3');
      game.tryMove('b8', 'c6');
      game.tryMove('f1', 'c4');
      game.tryMove('f8', 'c5');

      final legalKings = game.legalMovesFrom('e1');
      expect(legalKings, contains('g1')); // O-O destination

      final castleRes = game.tryMove('e1', 'g1');
      expect(castleRes.success, isTrue);
      expect(game.getPiece('g1')?.type, equals(PieceType.king));
      expect(game.getPiece('f1')?.type, equals(PieceType.rook));
    });

    test('Castling through check is blocked', () {
      // Position where e1-g1 requires crossing f1, and f1 is attacked by black bishop at a6
      // FEN: r3k2r/8/b7/8/8/8/8/R3K2R w KQkq - 0 1
      game.loadFen('r3k2r/8/b7/8/8/8/8/R3K2R w KQkq - 0 1');

      final legalMoves = game.legalMovesFrom('e1');
      expect(legalMoves, isNot(contains('g1'))); // f1 attacked by bishop on a6

      final res = game.tryMove('e1', 'g1');
      expect(res.success, isFalse);
    });

    test('Castling out of check is blocked', () {
      // White king on e1 is in check from black rook on e2, black king on d8
      // FEN: 3k4/8/8/8/8/8/4r3/R3K2R w KQ - 0 1
      game.loadFen('3k4/8/8/8/8/8/4r3/R3K2R w KQ - 0 1');
      expect(game.isInCheck, isTrue);

      expect(game.legalMovesFrom('e1'), isNot(contains('g1')));
      expect(game.legalMovesFrom('e1'), isNot(contains('c1')));
    });

    test('En passant capture works and removes the target pawn', () {
      // 1. e4 a6 2. e5 d5 3. exd6 (e.p.)
      game.tryMove('e2', 'e4');
      game.tryMove('a7', 'a6');
      game.tryMove('e4', 'e5');
      game.tryMove('d7', 'd5'); // black pawn steps 2 squares

      final legalE5 = game.legalMovesFrom('e5');
      expect(legalE5, contains('d6')); // en passant square

      final epMove = game.tryMove('e5', 'd6');
      expect(epMove.success, isTrue);
      expect(game.getPiece('d6')?.type, equals(PieceType.pawn));
      expect(game.getPiece('d5'), isNull); // Captured en passant
    });

    test('Pawn promotion defaults or promotes to specified piece', () {
      // White pawn on e7, can promote on e8 (black king on a8)
      // FEN: k7/4P3/8/8/8/8/8/4K3 w - - 0 1
      game.loadFen('k7/4P3/8/8/8/8/8/4K3 w - - 0 1');

      final legalE7 = game.legalMovesFrom('e7');
      expect(legalE7, contains('e8'));

      // Promote to Queen
      final resQ = game.tryMove('e7', 'e8', promotion: 'q');
      expect(resQ.success, isTrue);
      expect(game.getPiece('e8')?.type, equals(PieceType.queen));
      expect(game.getPiece('e8')?.color, equals(PlayerColor.white));
    });

    test('Pawn promotion to Knight works', () {
      game.loadFen('k7/4P3/8/8/8/8/8/4K3 w - - 0 1');
      final resN = game.tryMove('e7', 'e8', promotion: 'n');
      expect(resN.success, isTrue);
      expect(game.getPiece('e8')?.type, equals(PieceType.knight));
    });

    test('Checkmate detects game over and sets correct winner', () {
      // Scholar's Mate: 1. e4 e5 2. Qh5 Nc6 3. Bc4 Nf6 4. Qxf7#
      game.tryMove('e2', 'e4');
      game.tryMove('e7', 'e5');
      game.tryMove('d1', 'h5');
      game.tryMove('b8', 'c6');
      game.tryMove('f1', 'c4');
      game.tryMove('g8', 'f6');
      final mateMove = game.tryMove('h5', 'f7');

      expect(mateMove.success, isTrue);
      expect(game.isInCheck, isTrue);
      expect(game.isCheckmate, isTrue);
      expect(game.isGameOver, isTrue);
      expect(game.result, equals('1-0'));
    });

    test('Stalemate detects draw and sets result to 1/2-1/2', () {
      // Classic stalemate position: Black king on a8, White queen on c7, White king on c8
      // FEN: k7/2Q5/2K5/8/8/8/8/8 b - - 0 1
      game.loadFen('k7/2Q5/2K5/8/8/8/8/8 b - - 0 1');

      expect(game.isInCheck, isFalse);
      expect(game.isStalemate, isTrue);
      expect(game.isGameOver, isTrue);
      expect(game.isDraw, isTrue);
      expect(game.result, equals('1/2-1/2'));
    });

    test('Threefold repetition is detected', () {
      // Repeat moves: 1. Nf3 Nf6 2. Ng1 Ng8 3. Nf3 Nf6 4. Ng1 Ng8
      game.tryMove('g1', 'f3');
      game.tryMove('g8', 'f6');
      game.tryMove('f3', 'g1');
      game.tryMove('f6', 'g8'); // 2nd occurrence of initial position

      expect(game.isThreefoldRepetition, isFalse);

      game.tryMove('g1', 'f3');
      game.tryMove('g8', 'f6');
      game.tryMove('f3', 'g1');
      game.tryMove('f6', 'g8'); // 3rd occurrence of initial position

      expect(game.isThreefoldRepetition, isTrue);
      expect(game.isGameOver, isTrue);
      expect(game.result, equals('1/2-1/2'));
    });

    test('50-move rule is detected', () {
      // FEN with half-move clock at 99, White plays a non-pawn non-capture move
      // FEN: 8/5k2/8/8/8/8/5K2/4R3 w - - 99 50
      game.loadFen('8/5k2/8/8/8/8/5K2/4R3 w - - 99 50');
      expect(game.isGameOver, isFalse);

      game.tryMove('e1', 'e2');
      expect(game.isFiftyMoveRule, isTrue);
      expect(game.isGameOver, isTrue);
      expect(game.result, equals('1/2-1/2'));
    });

    test('Insufficient material is detected (King vs King)', () {
      // FEN: 8/8/5k2/8/8/8/5K2/8 w - - 0 1
      game.loadFen('8/8/5k2/8/8/8/5K2/8 w - - 0 1');
      expect(game.isInsufficientMaterial, isTrue);
      expect(game.isGameOver, isTrue);
      expect(game.result, equals('1/2-1/2'));
    });

    test('Insufficient material is detected (King+Bishop vs King)', () {
      game.loadFen('8/8/5k2/8/8/8/5K2/2B5 w - - 0 1');
      expect(game.isInsufficientMaterial, isTrue);
      expect(game.isGameOver, isTrue);
      expect(game.result, equals('1/2-1/2'));
    });

    test('Undo reverses the last move', () {
      game.tryMove('e2', 'e4');
      expect(game.turn, equals(PlayerColor.black));
      expect(game.getPiece('e4')?.type, equals(PieceType.pawn));

      final undoOk = game.undo();
      expect(undoOk, isTrue);
      expect(game.turn, equals(PlayerColor.white));
      expect(game.getPiece('e4'), isNull);
      expect(game.getPiece('e2')?.type, equals(PieceType.pawn));
    });

    test('toPgn produces valid PGN string', () {
      game.tryMove('e2', 'e4');
      game.tryMove('e7', 'e5');
      final pgn = game.toPgn();
      expect(pgn, contains('1. e4 e5'));
    });
  });
}
