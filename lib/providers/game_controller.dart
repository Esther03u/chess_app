import 'package:flutter/foundation.dart';

import '../core/strings.dart';
import '../domain/game_logic.dart';
import '../services/engine_service.dart';

export '../domain/simple_bot.dart' show BotLevel;

enum GameMode { humanVsHuman, vsBot }

class MoveHistoryItem {
  final String from;
  final String to;
  final String? san;

  const MoveHistoryItem({required this.from, required this.to, this.san});
}

/// Controller managing the state of an ongoing chess game.
class GameController extends ChangeNotifier {
  final GameLogic _game;
  final EngineService _engineService;

  GameMode _gameMode;
  PlayerColor _playerColor;
  BotLevel _botLevel;

  String? _selectedSquare;
  List<String> _legalDestinations = [];
  MoveHistoryItem? _lastMove;
  bool _isAwaitingPromotion = false;
  bool _isBotThinking = false;
  bool _disposed = false;

  GameController({
    GameLogic? game,
    EngineService? engineService,
    this._gameMode = GameMode.humanVsHuman,
    this._playerColor = PlayerColor.white,
    BotLevel botLevel = BotLevel.medium,
  }) : _game = game ?? GameLogic(),
       _engineService =
           engineService ?? SimpleBotEngineService(level: botLevel),
       _botLevel = botLevel {
    if (_gameMode == GameMode.vsBot && _game.turn != _playerColor) {
      _triggerBotMove();
    }
  }

  GameLogic get game => _game;
  GameMode get gameMode => _gameMode;
  PlayerColor get playerColor => _playerColor;
  BotLevel get botLevel => _botLevel;
  PlayerColor get turn => _game.turn;
  bool get isGameOver => _game.isGameOver;
  bool get isInCheck => _game.isInCheck;
  bool get isBotThinking => _isBotThinking;
  bool get isBotTurn =>
      _gameMode == GameMode.vsBot && turn != _playerColor && !isGameOver;
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
    if (_isBotThinking) {
      return AppStrings.botThinking;
    }
    if (_game.isCheckmate) {
      if (_gameMode == GameMode.vsBot) {
        final winner = turn == PlayerColor.white
            ? PlayerColor.black
            : PlayerColor.white;
        return winner == _playerColor
            ? AppStrings.playerWon
            : AppStrings.botWon;
      }
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

  /// Configures game mode, player color, and bot difficulty, then resets board.
  void setGameMode(
    GameMode mode, {
    PlayerColor? playerColor,
    BotLevel? botLevel,
  }) {
    _gameMode = mode;
    if (playerColor != null) _playerColor = playerColor;
    if (botLevel != null) setBotLevel(botLevel);
    reset();
  }

  /// Sets the bot difficulty level (FR2).
  void setBotLevel(BotLevel level) {
    _botLevel = level;
    final engine = _engineService;
    if (engine is SimpleBotEngineService) {
      engine.setBotLevel(level);
    }
    notifyListeners();
  }

  /// Handles a tap on a square of the board.
  void onSquareTapped(
    String square, {
    Future<String?> Function()? onPromotionRequested,
  }) async {
    // If it is the bot's turn or bot is thinking, disallow human interaction
    if (isGameOver || _isAwaitingPromotion || isBotTurn || _isBotThinking) {
      return;
    }

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

  void _executeMove(
    String from,
    String to, {
    String? promotion,
    bool isBotMove = false,
  }) {
    final result = _game.tryMove(from, to, promotion: promotion);
    if (result.success) {
      _lastMove = MoveHistoryItem(from: from, to: to, san: result.san);
      _clearSelection();
      notifyListeners();

      // Trigger bot response if in vsBot mode and now it's bot's turn
      if (!isBotMove && _gameMode == GameMode.vsBot && !isGameOver) {
        _triggerBotMove();
      }
    } else {
      _clearSelection();
      notifyListeners();
    }
  }

  Future<void> _triggerBotMove() async {
    if (_gameMode != GameMode.vsBot ||
        isGameOver ||
        _isBotThinking ||
        turn == _playerColor) {
      return;
    }

    _isBotThinking = true;
    notifyListeners();

    try {
      final uci = await _engineService.bestMove(_game.fen);
      if (_disposed) return;

      if (_gameMode == GameMode.vsBot &&
          !isGameOver &&
          turn != _playerColor &&
          uci.length >= 4) {
        final from = uci.substring(0, 2);
        final to = uci.substring(2, 4);
        final promotion = uci.length > 4 ? uci.substring(4, 5) : null;
        _executeMove(from, to, promotion: promotion, isBotMove: true);
      }
    } catch (e) {
      debugPrint('Bot move error: $e');
    } finally {
      if (!_disposed) {
        _isBotThinking = false;
        notifyListeners();
      }
    }
  }

  /// Undoes the last move.
  /// When playing vs bot, reverts both the bot's response and the player's move.
  void undo() {
    if (_isBotThinking || isGameOver) return;

    if (_gameMode == GameMode.vsBot) {
      if (turn == _playerColor) {
        // Undo bot move then player move
        if (_game.undo()) {
          _game.undo();
          _clearSelection();
          _lastMove = null;
          notifyListeners();
        }
      } else {
        // Bot hasn't moved yet, undo 1 player move
        if (_game.undo()) {
          _clearSelection();
          _lastMove = null;
          notifyListeners();
        }
      }
    } else {
      if (_game.undo()) {
        _clearSelection();
        _lastMove = null;
        notifyListeners();
      }
    }
  }

  /// Resets the game to start a new match.
  void reset() {
    _game.reset();
    _clearSelection();
    _lastMove = null;
    _isAwaitingPromotion = false;
    _isBotThinking = false;
    notifyListeners();

    // If playing as Black vs Bot, White (Bot) makes the opening move
    if (_gameMode == GameMode.vsBot && _playerColor == PlayerColor.black) {
      _triggerBotMove();
    }
  }

  void _clearSelection() {
    _selectedSquare = null;
    _legalDestinations = [];
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
