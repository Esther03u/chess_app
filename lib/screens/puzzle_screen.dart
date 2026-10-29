import 'dart:async';

import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../domain/game_logic.dart';
import '../models/puzzle.dart';
import '../services/lichess_api.dart';
import '../widgets/board_view.dart';

/// Screen presenting the Lichess Daily Puzzle with interactive board,
/// solution verification, opponent auto-reply, themes, and offline error handling (FR5).
class PuzzleScreen extends StatefulWidget {
  final LichessApi? api;
  final DailyPuzzle? initialPuzzle;
  final bool isEmbeddedInHub;

  const PuzzleScreen({
    super.key,
    this.api,
    this.initialPuzzle,
    this.isEmbeddedInHub = false,
  });

  @override
  State<PuzzleScreen> createState() => _PuzzleScreenState();
}

class _PuzzleScreenState extends State<PuzzleScreen> {
  late final LichessApi _api;

  bool _isLoading = true;
  String? _errorMessage;
  DailyPuzzle? _puzzle;

  late GameLogic _game;
  int _solutionStep = 0;
  PlayerColor _playerColor = PlayerColor.white;

  String? _selectedSquare;
  List<String> _legalDestinations = [];
  String? _lastMoveFrom;
  String? _lastMoveTo;

  bool _isOpponentMoving = false;
  bool _isSolved = false;
  bool _isWrongMove = false;
  bool _showSolution = false;

  @override
  void initState() {
    super.initState();
    _api = widget.api ?? LichessApi();
    _game = GameLogic();
    if (widget.initialPuzzle != null) {
      _initPuzzle(widget.initialPuzzle!);
    } else {
      _loadDailyPuzzle();
    }
  }

  Future<void> _loadDailyPuzzle() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final puzzle = await _api.dailyPuzzle();
      if (!mounted) return;
      _initPuzzle(puzzle);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e is ApiException
            ? e.message
            : AppStrings.puzzleLoadFailed;
      });
    }
  }

  void _initPuzzle(DailyPuzzle puzzle) {
    _puzzle = puzzle;
    _game = GameLogic(puzzle.fen);
    _solutionStep = 0;
    _playerColor = _game.turn;
    _isSolved = false;
    _isWrongMove = false;
    _showSolution = false;
    _selectedSquare = null;
    _legalDestinations = [];

    // Set initial last move highlight from puzzle if available
    if (puzzle.lastMove.length >= 4) {
      _lastMoveFrom = puzzle.lastMove.substring(0, 2);
      _lastMoveTo = puzzle.lastMove.substring(2, 4);
    } else {
      _lastMoveFrom = null;
      _lastMoveTo = null;
    }

    setState(() {
      _isLoading = false;
      _errorMessage = null;
    });
  }

  void _restartPuzzle() {
    if (_puzzle == null) return;
    setState(() {
      _game = GameLogic(_puzzle!.fen);
      _solutionStep = 0;
      _isSolved = false;
      _isWrongMove = false;
      _showSolution = false;
      _selectedSquare = null;
      _legalDestinations = [];
      if (_puzzle!.lastMove.length >= 4) {
        _lastMoveFrom = _puzzle!.lastMove.substring(0, 2);
        _lastMoveTo = _puzzle!.lastMove.substring(2, 4);
      } else {
        _lastMoveFrom = null;
        _lastMoveTo = null;
      }
    });
  }

  Future<void> _onSquareTapped(String square) async {
    if (_isLoading || _isOpponentMoving || _isSolved || _puzzle == null) {
      return;
    }

    final piece = _game.getPiece(square);

    // If no piece is currently selected
    if (_selectedSquare == null) {
      if (piece != null && piece.color == _playerColor) {
        setState(() {
          _selectedSquare = square;
          _legalDestinations = _game.legalMovesFrom(square);
          _isWrongMove = false;
        });
      }
      return;
    }

    // Tapping the same square deselects it
    if (_selectedSquare == square) {
      setState(() {
        _selectedSquare = null;
        _legalDestinations = [];
      });
      return;
    }

    // Tapping another piece of the player's own color switches selection
    if (piece != null && piece.color == _playerColor) {
      setState(() {
        _selectedSquare = square;
        _legalDestinations = _game.legalMovesFrom(square);
        _isWrongMove = false;
      });
      return;
    }

    // If tapping a legal destination square, attempt the move
    if (_legalDestinations.contains(square)) {
      final from = _selectedSquare!;
      final to = square;

      // Handle promotion if pawn reaches end rank
      String? promotion;
      final movingPiece = _game.getPiece(from);
      if (movingPiece?.type == PieceType.pawn &&
          (to.endsWith('8') || to.endsWith('1'))) {
        promotion = await _promptPromotionDialog();
        if (promotion == null && mounted) {
          // Cancelled promotion
          return;
        }
      }

      final moveUci = '$from$to${promotion ?? ''}'.toLowerCase();
      final expectedUci = _puzzle!.solution[_solutionStep].toLowerCase();

      // Check if player's move matches the expected solution
      if (moveUci == expectedUci) {
        // Correct move!
        final result = _game.tryMove(from, to, promotion: promotion);
        if (!result.success) return;

        setState(() {
          _selectedSquare = null;
          _legalDestinations = [];
          _lastMoveFrom = from;
          _lastMoveTo = to;
          _isWrongMove = false;
          _solutionStep++;
        });

        // Check if puzzle is fully solved
        if (_solutionStep >= _puzzle!.solution.length) {
          setState(() {
            _isSolved = true;
          });
          return;
        }

        // Auto-play opponent response after a brief natural delay
        setState(() {
          _isOpponentMoving = true;
        });

        await Future.delayed(const Duration(milliseconds: 400));
        if (!mounted) return;

        final opponentUci = _puzzle!.solution[_solutionStep];
        _game.tryMoveUci(opponentUci);

        setState(() {
          _lastMoveFrom = opponentUci.substring(0, 2);
          _lastMoveTo = opponentUci.substring(2, 4);
          _solutionStep++;
          _isOpponentMoving = false;
        });

        // Check if opponent's move was the final move in solution
        if (_solutionStep >= _puzzle!.solution.length) {
          setState(() {
            _isSolved = true;
          });
        }
      } else {
        // Wrong move!
        setState(() {
          _isWrongMove = true;
          _selectedSquare = null;
          _legalDestinations = [];
        });
      }
    } else {
      // Tapped outside legal destinations: deselect
      setState(() {
        _selectedSquare = null;
        _legalDestinations = [];
      });
    }
  }

  Future<String?> _promptPromotionDialog() async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text(
          AppStrings.choosePromotion,
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text(
                AppStrings.queen,
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.of(ctx).pop('q'),
            ),
            ListTile(
              title: const Text(
                AppStrings.rook,
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.of(ctx).pop('r'),
            ),
            ListTile(
              title: const Text(
                AppStrings.bishop,
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.of(ctx).pop('b'),
            ),
            ListTile(
              title: const Text(
                AppStrings.knight,
                style: TextStyle(color: Colors.white),
              ),
              onTap: () => Navigator.of(ctx).pop('n'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbeddedInHub,
        title: const Text(
          AppStrings.dailyPuzzle,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: AppTheme.surface,
        foregroundColor: AppTheme.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.retry,
            onPressed: _loadDailyPuzzle,
          ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white70),
                    SizedBox(height: 16),
                    Text(
                      AppStrings.loadingPuzzle,
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              )
            : _errorMessage != null
            ? _buildErrorView()
            : _buildPuzzleContent(),
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 64,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? AppStrings.puzzleLoadFailed,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70, fontSize: 15),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text(AppStrings.retry),
              onPressed: _loadDailyPuzzle,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPuzzleContent() {
    final puzzle = _puzzle!;
    final isFlipped = _playerColor == PlayerColor.black;

    return Column(
      children: [
        // Puzzle Metadata Card
        _buildMetadataCard(puzzle),

        // Status Feedback Banner
        _buildStatusBanner(),

        // Chess Board
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: AspectRatio(
                aspectRatio: 1.0,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(6.0),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.18),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    children: List.generate(8, (rankIndex) {
                      final rank = isFlipped ? rankIndex + 1 : 8 - rankIndex;
                      return Expanded(
                        child: Row(
                          children: List.generate(8, (fileIndex) {
                            final fileChar = isFlipped
                                ? String.fromCharCode(
                                    'h'.codeUnitAt(0) - fileIndex,
                                  )
                                : String.fromCharCode(
                                    'a'.codeUnitAt(0) + fileIndex,
                                  );
                            final square = '$fileChar$rank';
                            final isLightSquare =
                                (fileIndex + rankIndex) % 2 == 0;
                            final piece = _game.getPiece(square);

                            return Expanded(
                              child: _buildSquare(
                                square: square,
                                isLight: isLightSquare,
                                piece: piece,
                                isSelected: _selectedSquare == square,
                                isLegalDestination: _legalDestinations.contains(
                                  square,
                                ),
                                isLastMove:
                                    _lastMoveFrom == square ||
                                    _lastMoveTo == square,
                                isKingInCheck:
                                    _game.isInCheck &&
                                    piece?.type == PieceType.king &&
                                    piece?.color == _game.turn,
                                showFileLabel: rankIndex == 7,
                                showRankLabel: fileIndex == 0,
                                onTap: () => _onSquareTapped(square),
                              ),
                            );
                          }),
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
          ),
        ),

        // Solution display if revealed
        if (_showSolution) _buildSolutionView(puzzle),

        // Bottom Controls
        _buildBottomControls(),
      ],
    );
  }

  Widget _buildMetadataCard(DailyPuzzle puzzle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      margin: const EdgeInsets.fromLTRB(16.0, 10.0, 16.0, 8.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14.0),
        border: Border.all(color: AppTheme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      gradient: AppTheme.greenGradient,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.military_tech_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          '${AppStrings.puzzleRating}: ${puzzle.rating}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    '#${puzzle.id}',
                    style: const TextStyle(
                      color: AppTheme.textMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: _playerColor == PlayerColor.white
                      ? Colors.white.withValues(alpha: 0.12)
                      : Colors.black.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: _playerColor == PlayerColor.white
                            ? Colors.white
                            : Colors.black,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey, width: 0.8),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _playerColor == PlayerColor.white
                          ? 'คุณเล่นหมากขาว'
                          : 'คุณเล่นหมากดำ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (puzzle.themes.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 26,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: puzzle.themes.length,
                separatorBuilder: (_, _) => const SizedBox(width: 6),
                itemBuilder: (context, index) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Text(
                      '# ${puzzle.themes[index]}',
                      style: const TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusBanner() {
    Color bgColor;
    Color textColor = Colors.white;
    IconData icon;
    String message;

    if (_isSolved) {
      bgColor = AppTheme.primaryGreenDark;
      icon = Icons.emoji_events_rounded;
      message = AppStrings.puzzleSolved;
    } else if (_isWrongMove) {
      bgColor = AppTheme.errorRed;
      icon = Icons.error_outline_rounded;
      message = AppStrings.wrongMove;
    } else if (_isOpponentMoving) {
      bgColor = AppTheme.accentAmberDark;
      icon = Icons.smart_toy_rounded;
      message = AppStrings.botThinking;
    } else {
      bgColor = AppTheme.surfaceCard;
      icon = Icons.psychology_rounded;
      message = AppStrings.yourTurnToMove;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: bgColor.withValues(alpha: 0.35),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: textColor, size: 20),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquare({
    required String square,
    required bool isLight,
    required PieceInfo? piece,
    required bool isSelected,
    required bool isLegalDestination,
    required bool isLastMove,
    required bool isKingInCheck,
    required bool showFileLabel,
    required bool showRankLabel,
    required VoidCallback onTap,
  }) {
    Color squareBg = isLight
        ? BoardView.lightSquareColor
        : BoardView.darkSquareColor;

    if (isKingInCheck) {
      squareBg = BoardView.inCheckColor;
    } else if (isSelected) {
      squareBg = BoardView.selectedSquareColor;
    } else if (isLastMove) {
      squareBg = BoardView.lastMoveColor.withValues(alpha: 0.85);
    }

    final file = square[0];
    final rank = square[1];
    final labelColor = isLight
        ? BoardView.darkSquareColor
        : BoardView.lightSquareColor;

    return GestureDetector(
      key: Key('square_$square'),
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: squareBg,
        child: Stack(
          children: [
            if (showRankLabel)
              Positioned(
                top: 2,
                left: 3,
                child: Text(
                  rank,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: labelColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            if (showFileLabel)
              Positioned(
                bottom: 1,
                right: 3,
                child: Text(
                  file,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: labelColor.withValues(alpha: 0.8),
                  ),
                ),
              ),
            if (piece != null) Center(child: ChessPieceWidget(piece: piece)),
            if (isLegalDestination)
              Center(
                child: piece == null
                    ? Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.22),
                          shape: BoxShape.circle,
                        ),
                      )
                    : Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withValues(alpha: 0.25),
                            width: 4,
                          ),
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSolutionView(DailyPuzzle puzzle) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 6.0),
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: AppTheme.border),
      ),
      child: Row(
        children: [
          const Text(
            AppStrings.solutionLabel,
            style: TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              puzzle.solution.join('  '),
              style: const TextStyle(
                color: Colors.amberAccent,
                fontSize: 13,
                fontFamily: 'monospace',
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomControls() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white70,
              side: const BorderSide(color: Colors.white24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text(AppStrings.retryPuzzle),
            onPressed: _restartPuzzle,
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.amberAccent,
              side: const BorderSide(color: Colors.amber),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: const Text(AppStrings.showSolution),
            onPressed: () {
              setState(() {
                _showSolution = !_showSolution;
              });
            },
          ),
        ],
      ),
    );
  }
}
