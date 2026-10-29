import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/game_logic.dart';
import '../providers/game_controller.dart';

/// Renders a square 8x8 chessboard with highlights for legal moves,
/// last move, selected piece, and king in check.
class BoardView extends StatelessWidget {
  /// Whether the board is flipped (Black perspective at bottom).
  final bool isFlipped;

  /// Callback when a promotion dialog needs to be displayed.
  final Future<String?> Function()? onPromotionRequested;

  const BoardView({
    super.key,
    this.isFlipped = false,
    this.onPromotionRequested,
  });

  static const Color lightSquareColor = Color(0xFFEEEED2);
  static const Color darkSquareColor = Color(0xFF769656);
  static const Color selectedSquareColor = Color(0xFFBBCB43);
  static const Color lastMoveColor = Color(0xFFAAB838);
  static const Color inCheckColor = Color(0xFFEB6161);

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
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
        child: Consumer<GameController>(
          builder: (context, controller, child) {
            return Column(
              children: List.generate(8, (rankIndex) {
                // Rank 8 at top down to Rank 1 at bottom (or inverted if flipped)
                final rank = isFlipped ? rankIndex + 1 : 8 - rankIndex;

                return Expanded(
                  child: Row(
                    children: List.generate(8, (fileIndex) {
                      // File 'a' on left to 'h' on right (or inverted if flipped)
                      final fileChar = isFlipped
                          ? String.fromCharCode('h'.codeUnitAt(0) - fileIndex)
                          : String.fromCharCode('a'.codeUnitAt(0) + fileIndex);
                      final square = '$fileChar$rank';

                      final isLightSquare = (fileIndex + rankIndex) % 2 == 0;
                      return Expanded(
                        child: _SquareWidget(
                          square: square,
                          isLight: isLightSquare,
                          piece: controller.pieceAt(square),
                          isSelected: controller.selectedSquare == square,
                          isLegalDestination: controller.legalDestinations
                              .contains(square),
                          isLastMove:
                              controller.lastMove?.from == square ||
                              controller.lastMove?.to == square,
                          isKingInCheck: controller.kingInCheckSquare == square,
                          showFileLabel: rankIndex == 7,
                          showRankLabel: fileIndex == 0,
                          onTap: () => controller.onSquareTapped(
                            square,
                            onPromotionRequested: onPromotionRequested,
                          ),
                        ),
                      );
                    }),
                  ),
                );
              }),
            );
          },
        ),
      ),
    );
  }
}

class _SquareWidget extends StatelessWidget {
  final String square;
  final bool isLight;
  final PieceInfo? piece;
  final bool isSelected;
  final bool isLegalDestination;
  final bool isLastMove;
  final bool isKingInCheck;
  final bool showFileLabel;
  final bool showRankLabel;
  final VoidCallback onTap;

  const _SquareWidget({
    required this.square,
    required this.isLight,
    required this.piece,
    required this.isSelected,
    required this.isLegalDestination,
    required this.isLastMove,
    required this.isKingInCheck,
    required this.showFileLabel,
    required this.showRankLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
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
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: squareBg,
        child: Stack(
          children: [
            // Rank label on leftmost squares
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

            // File label on bottom squares
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

            // Chess piece
            if (piece != null) Center(child: ChessPieceWidget(piece: piece!)),

            // Legal move indicator
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
}

class ChessPieceWidget extends StatelessWidget {
  final PieceInfo piece;

  const ChessPieceWidget({super.key, required this.piece});

  @override
  Widget build(BuildContext context) {
    final symbol = _getSymbol(piece);
    final isWhite = piece.color == PlayerColor.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final fontSize = constraints.maxWidth * 0.76;
        return Text(
          symbol,
          style: TextStyle(
            fontSize: fontSize,
            height: 1.0,
            fontFamily: 'serif',
            color: isWhite ? const Color(0xFFFFFFFF) : const Color(0xFF1E1E1E),
            shadows: isWhite
                ? const [
                    Shadow(
                      offset: Offset(0.5, 0.5),
                      blurRadius: 1.5,
                      color: Color(0xFF222222),
                    ),
                    Shadow(
                      offset: Offset(-0.5, -0.5),
                      blurRadius: 1.0,
                      color: Color(0xFF444444),
                    ),
                  ]
                : const [
                    Shadow(
                      offset: Offset(0.5, 0.5),
                      blurRadius: 1.5,
                      color: Color(0x66FFFFFF),
                    ),
                  ],
          ),
        );
      },
    );
  }

  static String _getSymbol(PieceInfo piece) {
    switch (piece.type) {
      case PieceType.king:
        return piece.color == PlayerColor.white ? '\u2654' : '\u265A';
      case PieceType.queen:
        return piece.color == PlayerColor.white ? '\u2655' : '\u265B';
      case PieceType.rook:
        return piece.color == PlayerColor.white ? '\u2656' : '\u265C';
      case PieceType.bishop:
        return piece.color == PlayerColor.white ? '\u2657' : '\u265D';
      case PieceType.knight:
        return piece.color == PlayerColor.white ? '\u2658' : '\u265E';
      case PieceType.pawn:
        return piece.color == PlayerColor.white ? '\u2659' : '\u265F';
    }
  }
}
