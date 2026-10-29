import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../domain/game_logic.dart';
import '../providers/clock_controller.dart';

/// Digital chess clock widget displaying remaining time, active state,
/// and low-time warnings. Refactored with semantic theme tokens and accessibility.
class ClockView extends StatelessWidget {
  final PlayerColor color;
  final String playerName;

  const ClockView({super.key, required this.color, required this.playerName});

  @override
  Widget build(BuildContext context) {
    return Consumer<ClockController>(
      builder: (context, clock, child) {
        if (clock.isUnlimited) {
          return const SizedBox.shrink();
        }

        final isActive = clock.activeSide == color && clock.isRunning;
        final isFlagged = clock.isFlagged && clock.flaggedSide == color;
        final remaining = clock.remainingTime(color);
        final isLowTime =
            remaining.inSeconds < 30 && !isFlagged && remaining > Duration.zero;

        Color backgroundColor;
        Color textColor;
        Border? border;

        if (isFlagged) {
          backgroundColor = AppTheme.errorRed.withValues(alpha: 0.25);
          textColor = Colors.redAccent.shade100;
          border = Border.all(color: AppTheme.errorRed, width: 2);
        } else if (isActive) {
          backgroundColor = isLowTime
              ? AppTheme.accentAmber.withValues(alpha: 0.25)
              : AppTheme.primaryGreen.withValues(alpha: 0.22);
          textColor = isLowTime ? AppTheme.accentAmber : Colors.white;
          border = Border.all(
            color: isLowTime ? AppTheme.accentAmber : AppTheme.primaryGreen,
            width: 2,
          );
        } else {
          backgroundColor = AppTheme.surfaceVariant;
          textColor = AppTheme.textSecondary;
          border = Border.all(color: AppTheme.border, width: 1);
        }

        final formattedTime = clock.formatTime(color);
        final sideLabel = color == PlayerColor.white ? 'หมากขาว' : 'หมากดำ';

        return Semantics(
          label:
              'นาฬิกา $sideLabel: $formattedTime${isActive ? ", กำลังเดิน" : ""}',
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14.0,
              vertical: 8.0,
            ),
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(8.0),
              border: border,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color:
                            (isLowTime
                                    ? AppTheme.accentAmber
                                    : AppTheme.primaryGreen)
                                .withValues(alpha: 0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: color == PlayerColor.white
                        ? Colors.white
                        : Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white54, width: 1),
                  ),
                ),
                if (playerName.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Text(
                    playerName,
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
                const SizedBox(width: 12),
                Text(
                  formattedTime,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
