import 'package:chess/chess.dart' as chess;

/// Represents player color in the chess game.
enum PlayerColor {
  white,
  black;

  PlayerColor get opponent => this == white ? black : white;
}

/// Represents the piece types on a chessboard.
enum PieceType { pawn, knight, bishop, rook, queen, king }

/// High-level representation of a piece on the board.
class PieceInfo {
  final PieceType type;
  final PlayerColor color;

  const PieceInfo({required this.type, required this.color});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PieceInfo &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          color == other.color;

  @override
  int get hashCode => type.hashCode ^ color.hashCode;

  @override
  String toString() => '$color $type';
}

/// The outcome of an attempted move.
class MoveResult {
  final bool success;
  final String? san;
  final bool isCheck;
  final bool isCheckmate;
  final bool isGameOver;
  final String? result;

  const MoveResult({
    required this.success,
    this.san,
    this.isCheck = false,
    this.isCheckmate = false,
    this.isGameOver = false,
    this.result,
  });

  const MoveResult.failure()
    : success = false,
      san = null,
      isCheck = false,
      isCheckmate = false,
      isGameOver = false,
      result = null;
}

/// Domain wrapper around the underlying chess rules engine.
/// Fully encapsulates chess package details and provides a clean, unit-testable interface.
class GameLogic {
  final chess.Chess _chess;

  GameLogic([String? fen])
    : _chess = fen != null ? chess.Chess.fromFEN(fen) : chess.Chess();

  /// Current FEN string.
  String get fen => _chess.fen;

  /// Side whose turn it is to move.
  PlayerColor get turn =>
      _chess.turn == chess.Color.WHITE ? PlayerColor.white : PlayerColor.black;

  /// Whether the side to move is in check.
  bool get isInCheck => _chess.in_check;

  /// Whether the game ended by checkmate.
  bool get isCheckmate => _chess.in_checkmate;

  /// Whether the game ended by stalemate.
  bool get isStalemate => _chess.in_stalemate;

  /// Whether the game is a draw by threefold repetition.
  bool get isThreefoldRepetition => _chess.in_threefold_repetition;

  /// Whether the game is a draw by insufficient material.
  bool get isInsufficientMaterial => _chess.insufficient_material;

  /// Whether the 50-move rule has been reached (100 half-moves without capture or pawn move).
  bool get isFiftyMoveRule => _chess.half_moves >= 100;

  /// Whether the position is any type of draw.
  bool get isDraw => _chess.in_draw;

  /// Whether the game has ended (checkmate, draw, etc.).
  bool get isGameOver => _chess.game_over;

  /// Returns game result: '1-0' (White won), '0-1' (Black won), '1/2-1/2' (Draw), or null if active.
  String? get result {
    if (isCheckmate) {
      // The side whose turn it is got checkmated, so the previous mover won.
      return turn == PlayerColor.white ? '0-1' : '1-0';
    }
    if (isDraw) {
      return '1/2-1/2';
    }
    return null;
  }

  /// History of SAN moves played in this game.
  List<String> get history {
    final moves = _chess.getHistory();
    return moves.map((m) => m.toString()).toList();
  }

  /// Returns piece at the given square ('e4', 'a1', etc.), or null if empty.
  PieceInfo? getPiece(String square) {
    final p = _chess.get(square);
    if (p == null) return null;

    final color = p.color == chess.Color.WHITE
        ? PlayerColor.white
        : PlayerColor.black;
    final type = _mapPieceType(p.type);
    return PieceInfo(type: type, color: color);
  }

  /// Returns all legal target squares that a piece on [square] can move to.
  List<String> legalMovesFrom(String square) {
    final moves = _chess.generate_moves({'square': square});
    final destinations = <String>{};
    for (final m in moves) {
      destinations.add(m.toAlgebraic);
    }
    return destinations.toList()..sort();
  }

  /// Attempts to make a move from [from] square to [to] square, with optional [promotion] ('q', 'r', 'b', 'n').
  MoveResult tryMove(String from, String to, {String? promotion}) {
    // Check if move is legal first
    final moves = _chess.generate_moves({'square': from});
    final isLegal = moves.any(
      (m) =>
          m.toAlgebraic == to &&
          (promotion == null ||
              m.promotion == null ||
              m.promotion?.name.toLowerCase() == promotion.toLowerCase()),
    );

    if (!isLegal) {
      return const MoveResult.failure();
    }

    final moveOptions = <String, String>{'from': from, 'to': to};
    if (promotion != null) {
      moveOptions['promotion'] = promotion.toLowerCase();
    } else {
      // If moving pawn to back rank without specifying promotion, default to queen
      final piece = getPiece(from);
      if (piece?.type == PieceType.pawn &&
          (to.endsWith('8') || to.endsWith('1'))) {
        moveOptions['promotion'] = 'q';
      }
    }

    final success = _chess.move(moveOptions);
    if (!success) {
      return const MoveResult.failure();
    }

    return MoveResult(
      success: true,
      isCheck: isInCheck,
      isCheckmate: isCheckmate,
      isGameOver: isGameOver,
      result: result,
    );
  }

  /// Attempts to make a move from Standard Algebraic Notation (SAN), e.g. 'e4', 'Nf3', 'O-O'.
  bool tryMoveSan(String san) {
    return _chess.move(san);
  }

  /// Undoes the last move. Returns true if a move was undone, false otherwise.
  bool undo() {
    final move = _chess.undo_move();
    return move != null;
  }

  /// Resets the game to the initial standard chess position.
  void reset() {
    _chess.reset();
  }

  /// Loads position from a FEN string.
  void loadFen(String fen) {
    _chess.load(fen);
  }

  /// Loads a game from PGN text.
  void loadPgn(String pgn) {
    _chess.load_pgn(pgn);
  }

  /// Exports current game history in PGN format.
  String toPgn() {
    return _chess.pgn();
  }

  static PieceType _mapPieceType(chess.PieceType pt) {
    if (pt == chess.PieceType.PAWN) return PieceType.pawn;
    if (pt == chess.PieceType.KNIGHT) return PieceType.knight;
    if (pt == chess.PieceType.BISHOP) return PieceType.bishop;
    if (pt == chess.PieceType.ROOK) return PieceType.rook;
    if (pt == chess.PieceType.QUEEN) return PieceType.queen;
    if (pt == chess.PieceType.KING) return PieceType.king;
    return PieceType.pawn;
  }
}
