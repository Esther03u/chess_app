import 'dart:math';

import 'package:chess/chess.dart' as chess;

/// Difficulty levels for the chess engine bot (FR2 requires >= 3 levels).
enum BotLevel {
  easy(depth: 1, randomness: 0.35, label: 'ง่าย (Easy)'),
  medium(depth: 2, randomness: 0.05, label: 'ปานกลาง (Medium)'),
  hard(depth: 3, randomness: 0.0, label: 'ยาก (Hard)');

  final int depth;
  final double randomness;
  final String label;

  const BotLevel({
    required this.depth,
    required this.randomness,
    required this.label,
  });
}

/// Evaluation result from the engine.
class EngineEval {
  /// Centipawn score from the SIDE-TO-MOVE perspective.
  final int? cp;

  /// Mate in N moves (positive if side-to-move delivers mate, negative if getting mated).
  final int? mate;

  /// The best UCI move found.
  final String? bestMove;

  const EngineEval({this.cp, this.mate, this.bestMove});
}

/// Fallback and standalone pure Dart chess engine implementing Minimax with Alpha-Beta pruning.
/// Guaranteed to work on all platforms without native C++ compilation or FFI requirements.
class SimpleBot {
  BotLevel _level;
  final Random _random;

  SimpleBot({this._level = BotLevel.medium, int? seed})
    : _random = Random(seed);

  BotLevel get level => _level;

  void setLevel(BotLevel level) {
    _level = level;
  }

  /// Calculates the best move for the position specified by [fen].
  /// Returns a UCI string (e.g. 'e2e4', 'e7e8q').
  Future<String> bestMove(String fen, {int movetimeMs = 500}) async {
    final game = chess.Chess.fromFEN(fen);
    final legalMoves = game.generate_moves();

    if (legalMoves.isEmpty) return '';

    // Check if easy bot should make a slight blunder/random move
    if (_level.randomness > 0 && _random.nextDouble() < _level.randomness) {
      final randomMove = legalMoves[_random.nextInt(legalMoves.length)];
      return _moveToUci(randomMove);
    }

    final isWhite = game.turn == chess.Color.WHITE;
    chess.Move? bestMoveFound;
    int bestValue = isWhite ? -1000000 : 1000000;

    // Sort moves to improve alpha-beta pruning (captures first)
    legalMoves.sort((a, b) {
      final aScore =
          (a.captured != null ? 10 : 0) + (a.promotion != null ? 5 : 0);
      final bScore =
          (b.captured != null ? 10 : 0) + (b.promotion != null ? 5 : 0);
      return bScore.compareTo(aScore);
    });

    int alpha = -1000000;
    int beta = 1000000;

    for (final move in legalMoves) {
      game.make_move(move);
      final value = _minimax(game, _level.depth - 1, alpha, beta, !isWhite);
      game.undo_move();

      if (isWhite) {
        if (value > bestValue) {
          bestValue = value;
          bestMoveFound = move;
        }
        alpha = max(alpha, bestValue);
      } else {
        if (value < bestValue) {
          bestValue = value;
          bestMoveFound = move;
        }
        beta = min(beta, bestValue);
      }

      if (beta <= alpha) break;
    }

    bestMoveFound ??= legalMoves.first;
    return _moveToUci(bestMoveFound);
  }

  /// Evaluates the position and returns [EngineEval] from the SIDE-TO-MOVE perspective.
  Future<EngineEval> evaluate(String fen, {int movetimeMs = 250}) async {
    final game = chess.Chess.fromFEN(fen);
    if (game.in_checkmate) {
      // The side to move is checkmated -> -10000
      return const EngineEval(cp: -10000, mate: -1);
    }
    if (game.in_draw) {
      return const EngineEval(cp: 0);
    }

    final isWhite = game.turn == chess.Color.WHITE;
    final absScore = _evaluatePosition(game);

    // Convert absolute score (White advantage = positive) to side-to-move perspective
    final sideScore = isWhite ? absScore : -absScore;
    final move = await bestMove(fen, movetimeMs: movetimeMs);

    return EngineEval(cp: sideScore, bestMove: move);
  }

  int _minimax(
    chess.Chess game,
    int depth,
    int alpha,
    int beta,
    bool isMaximizingWhite,
  ) {
    if (depth <= 0 || game.game_over) {
      if (game.in_checkmate) {
        return isMaximizingWhite ? -90000 - depth : 90000 + depth;
      }
      if (game.in_draw) return 0;
      return _evaluatePosition(game);
    }

    final legalMoves = game.generate_moves();
    if (legalMoves.isEmpty) {
      if (game.in_check) {
        return isMaximizingWhite ? -90000 - depth : 90000 + depth;
      }
      return 0; // Stalemate
    }

    if (isMaximizingWhite) {
      int maxEval = -1000000;
      for (final move in legalMoves) {
        game.make_move(move);
        final eval = _minimax(game, depth - 1, alpha, beta, false);
        game.undo_move();
        maxEval = max(maxEval, eval);
        alpha = max(alpha, eval);
        if (beta <= alpha) break;
      }
      return maxEval;
    } else {
      int minEval = 1000000;
      for (final move in legalMoves) {
        game.make_move(move);
        final eval = _minimax(game, depth - 1, alpha, beta, true);
        game.undo_move();
        minEval = min(minEval, eval);
        beta = min(beta, eval);
        if (beta <= alpha) break;
      }
      return minEval;
    }
  }

  /// Evaluates the board position from White's absolute perspective (positive = White leads).
  int _evaluatePosition(chess.Chess game) {
    int score = 0;

    for (int i = 0; i < 128; i++) {
      if ((i & 0x88) != 0) {
        continue; // 0x88 board representation in chess package
      }
      final piece = game.board[i];
      if (piece == null) {
        continue;
      }

      final isWhite = piece.color == chess.Color.WHITE;
      final pieceVal = _pieceValue(piece.type);
      final pstBonus = _pieceSquareBonus(piece.type, i, isWhite);

      final total = pieceVal + pstBonus;
      if (isWhite) {
        score += total;
      } else {
        score -= total;
      }
    }

    return score;
  }

  int _pieceValue(chess.PieceType type) {
    if (type == chess.PieceType.PAWN) return 100;
    if (type == chess.PieceType.KNIGHT) return 320;
    if (type == chess.PieceType.BISHOP) return 330;
    if (type == chess.PieceType.ROOK) return 500;
    if (type == chess.PieceType.QUEEN) return 900;
    if (type == chess.PieceType.KING) return 20000;
    return 0;
  }

  int _pieceSquareBonus(chess.PieceType type, int index0x88, bool isWhite) {
    final rank = index0x88 >> 4;
    final file = index0x88 & 7;

    // Reward central control for knights and pawns
    final centerDist = (file - 3.5).abs() + (rank - 3.5).abs();
    final centerBonus = ((7 - centerDist) * 3).toInt();

    if (type == chess.PieceType.KNIGHT || type == chess.PieceType.PAWN) {
      return centerBonus;
    }

    // Pawn advancement bonus
    if (type == chess.PieceType.PAWN) {
      final advancedRanks = isWhite ? (7 - rank) : rank;
      return advancedRanks * 10;
    }

    return 0;
  }

  static String _moveToUci(chess.Move move) {
    final from = move.fromAlgebraic;
    final to = move.toAlgebraic;
    final promo = move.promotion != null
        ? move.promotion!.name.toLowerCase()
        : '';
    return '$from$to$promo';
  }
}
