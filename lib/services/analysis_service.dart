import 'dart:convert';

import 'package:chess/chess.dart' as chess;

import '../domain/classification.dart';
import '../domain/classification_config.dart';
import '../domain/game_logic.dart';
import '../models/analysis_result.dart';
import '../services/db_service.dart';
import '../services/engine_service.dart';

/// Service responsible for performing post-game analysis on recorded chess games.
/// Implements the exact algorithm and math defined in §3.9 of AGENTS.md.
class AnalysisService {
  final EngineService _engineService;
  final DbService? dbService;

  AnalysisService({EngineService? engineService, this.dbService})
    : _engineService =
          engineService ?? SimpleBotEngineService(level: BotLevel.medium);

  /// Analyzes a game given its PGN text.
  /// Reports progress via [onProgress] (0.0 to 1.0).
  /// If [gameId] is provided, automatically caches the JSON in SQLite.
  Future<GameAnalysis> analyzeGame({
    required String pgn,
    int? gameId,
    void Function(double progress)? onProgress,
  }) async {
    // 1. Replay the game to collect all moves and positions
    final replayGame = chess.Chess();
    replayGame.load_pgn(pgn);
    final history = replayGame.getHistory({'verbose': true});

    final stepGame = GameLogic();
    final fens = <String>[stepGame.fen];
    final sanMoves = <String>[];
    final uciMoves = <String>[];

    for (final moveObj in history) {
      final san = moveObj['san']?.toString() ?? '';
      sanMoves.add(san);

      final from = moveObj['from']?.toString() ?? '';
      final to = moveObj['to']?.toString() ?? '';
      final promotion = moveObj['promotion']?.toString().toLowerCase() ?? '';
      final uci = '$from$to$promotion';
      uciMoves.add(uci);

      stepGame.tryMove(
        from,
        to,
        promotion: promotion.isEmpty ? null : promotion,
      );
      fens.add(stepGame.fen);
    }

    final totalPositions = fens.length; // N plies -> N+1 positions
    if (totalPositions == 0 || sanMoves.isEmpty) {
      return const GameAnalysis(
        moves: [],
        whiteAccuracy: 100.0,
        blackAccuracy: 100.0,
        whiteSummary: {},
        blackSummary: {},
      );
    }

    // 2. Evaluate each position once and cache it (§3.9)
    final positionEvals = <int>[]; // centipawns from side-to-move perspective
    final bestMoves = <String?>[]; // engine best move in UCI format

    for (int i = 0; i < totalPositions; i++) {
      final fen = fens[i];
      final posChecker = chess.Chess.fromFEN(fen);

      int cpEval;
      String? bestMove;

      if (posChecker.game_over) {
        if (posChecker.in_checkmate) {
          // Checkmated side to move -> -10000 (§3.9)
          cpEval = -ClassificationConfig.checkmateCentipawns;
        } else {
          // Stalemate or draw -> 0 (§3.9)
          cpEval = ClassificationConfig.drawCentipawns;
        }
        bestMove = null;
      } else {
        // Engine evaluation
        final evalResult = await _engineService.evaluate(fen, movetimeMs: 200);
        if (evalResult.mate != null) {
          cpEval = MoveClassifier.mateToCentipawns(evalResult.mate!);
        } else {
          cpEval = evalResult.cp ?? 0;
        }
        bestMove = evalResult.bestMove;
      }

      positionEvals.add(cpEval);
      bestMoves.add(bestMove);

      if (onProgress != null) {
        onProgress((i + 1) / totalPositions);
      }
    }

    // 3. Classify each move (§3.9)
    final analyzedMoves = <AnalyzedMove>[];
    final whiteAccuracies = <double>[];
    final blackAccuracies = <double>[];
    final whiteSummary = <MoveClassification, int>{
      for (final c in MoveClassification.values) c: 0,
    };
    final blackSummary = <MoveClassification, int>{
      for (final c in MoveClassification.values) c: 0,
    };

    for (int i = 0; i < sanMoves.length; i++) {
      final isWhite = (i % 2 == 0);
      final moveNumber = (i ~/ 2) + 1;
      final san = sanMoves[i];
      final uci = uciMoves[i];
      final fenAfter = fens[i + 1];

      // evalBefore_i = eval(P_i) (side-to-move = the mover)
      final evalBefore = positionEvals[i];

      // evalAfter_i = -eval(P_{i+1}) (side-to-move at P_{i+1} is opponent, so negate)
      final evalAfter = -positionEvals[i + 1];

      // Convert evalAfter to White's perspective for graph plotting
      final evalWhiteCp = isWhite ? evalAfter : -evalAfter;

      final loss = MoveClassifier.winLoss(evalBefore, evalAfter);
      final isEngineTop = (bestMoves[i]?.toLowerCase() == uci.toLowerCase());

      final classification = MoveClassifier.classify(
        loss,
        isEngineTop: isEngineTop,
      );
      final accuracy = MoveClassifier.moveAccuracy(loss);

      if (isWhite) {
        whiteAccuracies.add(accuracy);
        whiteSummary[classification] = (whiteSummary[classification] ?? 0) + 1;
      } else {
        blackAccuracies.add(accuracy);
        blackSummary[classification] = (blackSummary[classification] ?? 0) + 1;
      }

      analyzedMoves.add(
        AnalyzedMove(
          ply: i,
          moveNumber: moveNumber,
          isWhite: isWhite,
          san: san,
          uci: uci,
          fen: fenAfter,
          evalWhiteCp: evalWhiteCp,
          evalBefore: evalBefore,
          evalAfter: evalAfter,
          winLoss: loss,
          accuracy: accuracy,
          classification: classification,
          bestMove: bestMoves[i],
        ),
      );
    }

    final gameAnalysis = GameAnalysis(
      moves: analyzedMoves,
      whiteAccuracy: MoveClassifier.averageAccuracy(whiteAccuracies),
      blackAccuracy: MoveClassifier.averageAccuracy(blackAccuracies),
      whiteSummary: whiteSummary,
      blackSummary: blackSummary,
    );

    // 4. Cache in database if gameId is provided
    final db = dbService;
    if (gameId != null && db != null) {
      await db.saveAnalysis(gameId, jsonEncode(gameAnalysis.toJson()));
    }

    return gameAnalysis;
  }
}
