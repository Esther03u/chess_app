import 'package:flutter/foundation.dart';

import '../core/strings.dart';
import '../domain/game_logic.dart';

class MoveHistoryItem {
  final String from;
  final String to;
  final String? san;

  const MoveHistoryItem({required this.from, required this.to, this.san});
}

/// Controller managing the state of an ongoing chess game.
class GameController extends ChangeNotifier {
  final GameLogic _game;

  String? _selectedSquare;
  List<String> _legalDestinations = [];
  MoveHistoryItem? _lastMove;
  bool _isAwaitingPromotion = false;

  GameController({GameLogic? game}) : _game = game ?? GameLogic();

  GameLogic get game => _game;
  PlayerColor get turn => _game.turn;
  bool get isGameOver => _game.isGameOver;
  bool get isInCheck => _game.isInCheck;
  String? get selectedSquare => _selectedSquare;
  List<String> get legalDestinations => List.unmodifiable(_legalDestinations);
  MoveHistoryItem? get lastMove => _lastMove;
  bool get isAwaitingPromotion => _isAwaitingPromotion;
  List<String> get history => _game.history;
  String get fen => _game.fen;

  /// Returns the square ('e1', 'e8', etc.) of the king currently in check, or null if not in check.
  String? get kingInCheckSquare {
    if (!isInCheck) return null;
    final currentTurn = turn;
    for (int file = 0; file < 8; file++) {
      for (int rank = 1; rank <= 8; rank++) {
        final square = '${String.fromCharCode('a'.codeUnitAt(0) + file)}$rank';
        final piece = _game.getPiece(square);
        if (piece != null &&
            piece.type == PieceType.king &&
            piece.color == currentTurn) {
          return square;
        }
      }
    }
    return null;
  }

  /// User-friendly status message describing the current game state.
  String get statusMessage {
    if (_game.isCheckmate) {
      return turn == PlayerColor.white
          ? AppStrings.blackWon
          : AppStrings.whiteWon;
    }
    if (_game.isStalemate) return AppStrings.stalemate;
    if (_game.isThreefoldRepetition) return AppStrings.drawThreefold;
    if (_game.isFiftyMoveRule) return AppStrings.drawFiftyMove;
    if (_game.isInsufficientMaterial) return AppStrings.drawInsufficient;
    if (_game.isDraw) return AppStrings.drawResult;
    if (isInCheck) {
      return '${turn == PlayerColor.white ? AppStrings.white : AppStrings.black}: ${AppStrings.check}';
    }

    return turn == PlayerColor.white
        ? AppStrings.whiteTurn
        : AppStrings.blackTurn;
  }

  PieceInfo? pieceAt(String square) => _game.getPiece(square);

  /// Handles a tap on a square of the board.
  void onSquareTapped(
    String square, {
    Future<String?> Function()? onPromotionRequested,
  }) async {
    if (isGameOver || _isAwaitingPromotion) return;

    if (_selectedSquare == null) {
      // Trying to select a piece
      final piece = _game.getPiece(square);
      if (piece != null && piece.color == turn) {
        _selectedSquare = square;
        _legalDestinations = _game.legalMovesFrom(square);
        notifyListeners();
      }
      return;
    }

    // A piece is already selected
    if (_selectedSquare == square) {
      // Deselect
      _clearSelection();
      notifyListeners();
      return;
    }

    // Check if tapping another friendly piece instead
    final targetPiece = _game.getPiece(square);
    if (targetPiece != null && targetPiece.color == turn) {
      _selectedSquare = square;
      _legalDestinations = _game.legalMovesFrom(square);
      notifyListeners();
      return;
    }

    // Check if move is legal
    if (_legalDestinations.contains(square)) {
      final from = _selectedSquare!;
      final movingPiece = _game.getPiece(from);

      // Check if this move is a pawn promotion
      final isPromotionMove =
          movingPiece?.type == PieceType.pawn &&
          ((movingPiece?.color == PlayerColor.white && square.endsWith('8')) ||
              (movingPiece?.color == PlayerColor.black &&
                  square.endsWith('1')));

      if (isPromotionMove) {
        String? chosenPiece;
        if (onPromotionRequested != null) {
          _isAwaitingPromotion = true;
          notifyListeners();

          chosenPiece = await onPromotionRequested();
          _isAwaitingPromotion = false;
        }

        // Default to Queen if cancelled or not provided
        chosenPiece ??= 'q';
        _executeMove(from, square, promotion: chosenPiece);
      } else {
        _executeMove(from, square);
      }
    } else {
      _clearSelection();
      notifyListeners();
    }
  }

  void _executeMove(String from, String to, {String? promotion}) {
    final result = _game.tryMove(from, to, promotion: promotion);
    if (result.success) {
      _lastMove = MoveHistoryItem(from: from, to: to, san: result.san);
      _clearSelection();
      notifyListeners();
    } else {
      _clearSelection();
      notifyListeners();
    }
  }

  /// Undoes the last move.
  void undo() {
    if (_game.undo()) {
      _clearSelection();
      _lastMove = null;
      notifyListeners();
    }
  }

  /// Resets the game to start a new match.
  void reset() {
    _game.reset();
    _clearSelection();
    _lastMove = null;
    _isAwaitingPromotion = false;
    notifyListeners();
  }

  void _clearSelection() {
    _selectedSquare = null;
    _legalDestinations = [];
  }
}
