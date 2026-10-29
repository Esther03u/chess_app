import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../domain/game_logic.dart';
import '../models/customization_options.dart';
import '../providers/game_controller.dart';
import 'chess_piece_painter.dart';
import 'clock_view.dart';

/// Player bar positioned above or below the board (Chess.com layout).
/// Displays avatar, name, rating tag, captured pieces with material advantage badge (+1, +3),
/// and the player's digital chess clock.
class PlayerProfileBar extends StatelessWidget {
  final PlayerColor color;
  final String name;
  final String? subtitle;
  final bool isBot;
  final BotLevel? botLevel;
  final List<PieceType> capturedPieces;
  final int materialAdvantage;
  final bool isTurn;
  final PieceStylePreset pieceStyle;

  const PlayerProfileBar({
    super.key,
    required this.color,
    required this.name,
    this.subtitle,
    this.isBot = false,
    this.botLevel,
    required this.capturedPieces,
    required this.materialAdvantage,
    required this.isTurn,
    this.pieceStyle = PieceStylePreset.staunton,
  });

  @override
  Widget build(BuildContext context) {
    final opponentColor = color == PlayerColor.white
        ? PlayerColor.black
        : PlayerColor.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: isTurn
            ? AppTheme.primaryGreen.withValues(alpha: 0.12)
            : AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(10.0),
        border: Border.all(
          color: isTurn
              ? AppTheme.primaryGreen.withValues(alpha: 0.6)
              : AppTheme.border,
          width: isTurn ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // 1. Avatar with bot badge or user icon
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isBot
                  ? const Color(0xFF383531)
                  : AppTheme.primaryGreenDark,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isTurn ? AppTheme.primaryGreen : AppTheme.border,
                width: 1.5,
              ),
            ),
            child: Center(
              child: Icon(
                isBot ? Icons.smart_toy_outlined : Icons.person,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: 10),

          // 2. Name + Captured Pieces strip + Material advantage badge
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          color: isTurn ? Colors.white : AppTheme.textPrimary,
                          fontSize: 14,
                          fontWeight: isTurn
                              ? FontWeight.bold
                              : FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1.5,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceVariant,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: AppTheme.border),
                        ),
                        child: Text(
                          subtitle!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),

                // Captured pieces mini row + advantage counter (+1, +3)
                Row(
                  children: [
                    if (capturedPieces.isNotEmpty)
                      Flexible(
                        child: Wrap(
                          spacing: 2,
                          children: capturedPieces.take(8).map((type) {
                            return SizedBox(
                              width: 14,
                              height: 14,
                              child: ChessPieceWidget(
                                piece: PieceInfo(
                                  type: type,
                                  color: opponentColor,
                                ),
                                style: pieceStyle,
                                size: 14,
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    if (materialAdvantage > 0) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '+$materialAdvantage',
                          style: const TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // 3. Digital Clock View
          ClockView(color: color, playerName: ''),
        ],
      ),
    );
  }
}
