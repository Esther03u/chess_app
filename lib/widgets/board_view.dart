import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../domain/game_logic.dart';
import '../models/customization_options.dart';
import '../providers/game_controller.dart';
import '../providers/settings_provider.dart';
import 'chess_piece_painter.dart';

export 'chess_piece_painter.dart' show ChessPieceWidget;

/// Renders a square 8x8 tournament chessboard with vector pieces,
/// customizable board themes, piece styles, move animations, and coordinates.
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

  static const Color lightSquareColor = AppTheme.boardLight;
  static const Color darkSquareColor = AppTheme.boardDark;
  static const Color selectedSquareColor = AppTheme.boardSelected;
  static const Color lastMoveColor = AppTheme.boardLastMove;
  static const Color inCheckColor = AppTheme.boardInCheck;

  @override
  Widget build(BuildContext context) {
    // Attempt to watch SettingsProvider if available in widget tree
    SettingsProvider? settings;
    try {
      settings = context.watch<SettingsProvider>();
    } catch (_) {}

    final boardTheme = settings?.boardTheme ?? BoardThemePreset.tournamentGreen;
    final pieceStyle = settings?.pieceStyle ?? PieceStylePreset.staunton;
    final showCoords = settings?.showCoordinates ?? true;
    final showHints = settings?.showLegalMoveHints ?? true;
    final enableAnim = settings?.enableMoveAnimation ?? true;

    return AspectRatio(
      aspectRatio: 1.0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: AppTheme.border, width: 3.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.35),
              blurRadius: 18,
              offset: const Offset(0, 8),
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
                          showFileLabel: showCoords && rankIndex == 7,
                          showRankLabel: showCoords && fileIndex == 0,
                          showHints: showHints,
                          enableAnimation: enableAnim,
                          boardTheme: boardTheme,
                          pieceStyle: pieceStyle,
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
  final bool showHints;
  final bool enableAnimation;
  final BoardThemePreset boardTheme;
  final PieceStylePreset pieceStyle;
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
    required this.showHints,
    required this.enableAnimation,
    required this.boardTheme,
    required this.pieceStyle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color squareBg = isLight ? boardTheme.lightSquare : boardTheme.darkSquare;

    if (isKingInCheck) {
      squareBg = boardTheme.inCheckSquare;
    } else if (isSelected) {
      squareBg = boardTheme.selectedSquare;
    } else if (isLastMove) {
      squareBg = boardTheme.lastMoveSquare.withValues(alpha: 0.88);
    }

    final file = square[0];
    final rank = square[1];
    final labelColor = isLight ? boardTheme.darkSquare : boardTheme.lightSquare;

    final pieceDescription = piece != null
        ? '${piece!.color == PlayerColor.white ? "หมากขาว" : "หมากดำ"} ${piece!.type.name}'
        : 'ช่องว่าง';
    final stateDescription = [
      if (isSelected) 'เลือกอยู่',
      if (isLegalDestination) 'เดินได้',
      if (isKingInCheck) 'ถูกรุก',
    ].join(', ');
    final fullSemanticLabel =
        '$square $pieceDescription${stateDescription.isNotEmpty ? ' $stateDescription' : ''}';

    return Semantics(
      label: fullSemanticLabel,
      button: true,
      enabled: true,
      child: GestureDetector(
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
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: labelColor.withValues(alpha: 0.85),
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
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: labelColor.withValues(alpha: 0.85),
                    ),
                  ),
                ),

              // Chess piece with smooth animation transition
              if (piece != null)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: enableAnimation
                        ? AnimatedSwitcher(
                            duration: const Duration(milliseconds: 180),
                            transitionBuilder: (child, animation) {
                              return ScaleTransition(
                                scale: animation,
                                child: FadeTransition(
                                  opacity: animation,
                                  child: child,
                                ),
                              );
                            },
                            child: KeyedSubtree(
                              key: ValueKey('${piece!.color}_${piece!.type}'),
                              child: ChessPieceWidget(
                                piece: piece!,
                                style: pieceStyle,
                              ),
                            ),
                          )
                        : ChessPieceWidget(piece: piece!, style: pieceStyle),
                  ),
                ),

              // Legal move indicator
              if (showHints && isLegalDestination)
                Center(
                  child: piece == null
                      ? Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.24),
                            shape: BoxShape.circle,
                          ),
                        )
                      : Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.28),
                              width: 4.5,
                            ),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
