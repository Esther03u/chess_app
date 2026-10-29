import 'package:flutter_test/flutter_test.dart';
import 'package:chess_app/core/strings.dart';
import 'package:chess_app/domain/game_logic.dart';
import 'package:chess_app/providers/game_controller.dart';
import 'package:chess_app/services/engine_service.dart';

class FakeEngineService implements EngineService {
  String nextMove = 'e7e5';
  bool disposed = false;
  BotLevel level = BotLevel.medium;

  @override
  Future<void> init() async {}

  @override
  Future<void> setLevel(int skill0to20) async {}

  @override
  Future<String> bestMove(String fen, {int movetimeMs = 500}) async {
    return nextMove;
  }

  @override
  Future<EngineEval> evaluate(String fen, {int movetimeMs = 250}) async {
    return const EngineEval(cp: 0, bestMove: 'e7e5');
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}

void main() {
  group('GameController with Bot Integration (FR2)', () {
    late FakeEngineService fakeEngine;
    late GameController controller;

    setUp(() {
      fakeEngine = FakeEngineService();
      controller = GameController(
        engineService: fakeEngine,
        gameMode: GameMode.humanVsHuman,
      );
    });

    test('Initial mode is humanVsHuman and no bot move is triggered', () {
      expect(controller.gameMode, equals(GameMode.humanVsHuman));
      expect(controller.isBotThinking, isFalse);
      expect(controller.isBotTurn, isFalse);
    });

    test('Switching to vsBot triggers bot move on bot turn', () async {
      fakeEngine.nextMove = 'e7e5';
      controller.setGameMode(
        GameMode.vsBot,
        playerColor: PlayerColor.white,
        botLevel: BotLevel.hard,
      );

      expect(controller.gameMode, equals(GameMode.vsBot));
      expect(controller.playerColor, equals(PlayerColor.white));
      expect(controller.botLevel, equals(BotLevel.hard));

      // White (human) plays e2 -> e4
      controller.onSquareTapped('e2');
      controller.onSquareTapped('e4');

      expect(controller.history.first, equals('e4'));

      // Allow async bot response
      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.history.length, equals(2));
      expect(controller.history[1], equals('e5'));
      expect(controller.turn, equals(PlayerColor.white));
      expect(controller.isBotThinking, isFalse);
    });

    test('Playing as Black vs Bot: Bot plays first move', () async {
      fakeEngine.nextMove = 'd2d4';
      controller.setGameMode(
        GameMode.vsBot,
        playerColor: PlayerColor.black,
        botLevel: BotLevel.medium,
      );

      await Future<void>.delayed(const Duration(milliseconds: 10));

      expect(controller.history.length, equals(1));
      expect(controller.history.first, equals('d4'));
      expect(controller.turn, equals(PlayerColor.black));
    });

    test('Undo in vsBot reverts both bot move and player move', () async {
      fakeEngine.nextMove = 'e7e5';
      controller.setGameMode(GameMode.vsBot, playerColor: PlayerColor.white);

      // Player plays e4
      controller.onSquareTapped('e2');
      controller.onSquareTapped('e4');

      await Future<void>.delayed(const Duration(milliseconds: 10));
      expect(controller.history.length, equals(2));

      // Player undos
      controller.undo();
      expect(controller.history.length, equals(0));
      expect(controller.turn, equals(PlayerColor.white));
    });

    test('Board tap is ignored while bot is thinking or on bot turn', () async {
      fakeEngine.nextMove = 'e7e5';
      controller.setGameMode(GameMode.vsBot, playerColor: PlayerColor.black);

      // It is White's turn (Bot). Black tapping a piece does nothing
      controller.onSquareTapped('e7');
      expect(controller.selectedSquare, isNull);
    });

    test('Checkmate message shows playerWon or botWon in vsBot mode', () {
      final mateGame = GameLogic(
        'rnb1kbnr/pppp1ppp/8/4p3/6Pq/5P2/PPPPP2P/RNBQKBNR w KQkq - 1 3', // Fool's mate
      );

      final botController = GameController(
        game: mateGame,
        gameMode: GameMode.vsBot,
        playerColor: PlayerColor.white, // White was checkmated
      );

      expect(botController.isGameOver, isTrue);
      expect(botController.statusMessage, equals(AppStrings.botWon));
    });
  });
}
