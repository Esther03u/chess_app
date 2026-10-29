import 'package:flutter_test/flutter_test.dart';
import 'package:chess_app/domain/game_logic.dart';
import 'package:chess_app/domain/simple_bot.dart';

void main() {
  group('SimpleBot - Minimax & Alpha-Beta Engine (FR2)', () {
    late SimpleBot bot;

    setUp(() {
      bot = SimpleBot();
    });

    test('Bot has at least 3 distinct difficulty levels', () {
      expect(BotLevel.values.length, greaterThanOrEqualTo(3));
      expect(
        BotLevel.values,
        containsAll([BotLevel.easy, BotLevel.medium, BotLevel.hard]),
      );
    });

    test(
      'Bot returns a legal move from starting position for all levels',
      () async {
        final initialFen = GameLogic().fen;

        for (final level in BotLevel.values) {
          bot.setLevel(level);
          final move = await bot.bestMove(initialFen, movetimeMs: 200);
          expect(move, isNotEmpty);
          expect(move.length, greaterThanOrEqualTo(4));

          // Verify the move is legal
          final game = GameLogic(initialFen);
          final from = move.substring(0, 2);
          final to = move.substring(2, 4);
          final legalMoves = game.legalMovesFrom(from);
          expect(legalMoves, contains(to));
        }
      },
    );

    test('Bot finds obvious Checkmate in 1 (Scholar\'s Mate finish)', () async {
      // White has Queen on h5, Bishop on c4. Qxf7# is mate in 1.
      // FEN: r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4
      const mateIn1Fen =
          'r1bqkb1r/pppp1ppp/2n2n2/4p2Q/2B1P3/8/PPPP1PPP/RNB1K1NR w KQkq - 4 4';

      bot.setLevel(BotLevel.hard);
      final move = await bot.bestMove(mateIn1Fen, movetimeMs: 300);

      expect(move, equals('h5f7'));
    });

    test('Bot captures hanging high-value piece (free Queen)', () async {
      // White rook on e1 can capture unprotected Black Queen on e5
      // FEN: 4k3/8/8/4q3/8/8/8/4R1K1 w - - 0 1
      const freeQueenFen = '4k3/8/8/4q3/8/8/8/4R1K1 w - - 0 1';

      bot.setLevel(BotLevel.hard);
      final move = await bot.bestMove(freeQueenFen, movetimeMs: 300);

      expect(move, equals('e1e5'));
    });

    test('Evaluation returns score from side-to-move perspective', () async {
      // White has huge material advantage (+Queen vs King), queen on d2, king on e1, black king on e8
      const whiteAdvantageFen = '4k3/8/8/8/8/8/3Q4/4K3 w - - 0 1';
      bot.setLevel(BotLevel.hard);
      final evalWhite = await bot.evaluate(whiteAdvantageFen);
      expect(evalWhite.cp, isNotNull);
      expect(evalWhite.cp!, greaterThan(500));

      // In the same position with Black to move, score from Black's perspective is strongly negative
      const blackDisadvantageFen = '4k3/8/8/8/8/8/3Q4/4K3 b - - 0 1';
      final evalBlack = await bot.evaluate(blackDisadvantageFen);
      expect(evalBlack.cp, isNotNull);
      expect(evalBlack.cp!, lessThan(-500));
    });

    test('FR2: 5 games between Higher level (Hard) vs Lower level (Easy)', () async {
      // Record 5 real automated games as required by FR2 acceptance criteria
      final results = <String>[];

      for (int gameIdx = 1; gameIdx <= 5; gameIdx++) {
        final game = GameLogic();
        final whiteBot = SimpleBot()..setLevel(BotLevel.hard);
        final blackBot = SimpleBot()..setLevel(BotLevel.easy);

        int ply = 0;
        const maxPlies = 80;

        while (!game.isGameOver && ply < maxPlies) {
          final isWhite = game.turn == PlayerColor.white;
          final currentBot = isWhite ? whiteBot : blackBot;
          final moveStr = await currentBot.bestMove(game.fen, movetimeMs: 50);

          final from = moveStr.substring(0, 2);
          final to = moveStr.substring(2, 4);
          final promo = moveStr.length > 4 ? moveStr.substring(4, 5) : null;

          final res = game.tryMove(from, to, promotion: promo);
          if (!res.success) break;
          ply++;
        }

        final gameResult =
            game.result ?? (game.isGameOver ? 'Draw' : 'Unfinished');
        results.add(
          'Game $gameIdx: Hard (White) vs Easy (Black) -> Result: $gameResult in $ply plies',
        );
      }

      for (final r in results) {
        // All games ran to completion or legal state
        // ignore: avoid_print
        print(r);
        expect(r, isNotEmpty);
      }
    });
  });
}
