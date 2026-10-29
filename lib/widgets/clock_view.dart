import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../domain/game_logic.dart';
import '../providers/clock_controller.dart';

/// Digital chess clock widget displaying remaining time, active state,
/// and low-time warnings.
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
          backgroundColor = const Color(0xFF4A1E1E);
          textColor = Colors.redAccent.shade100;
          border = Border.all(color: Colors.redAccent, width: 2);
        } else if (isActive) {
          backgroundColor = isLowTime
              ? const Color(0xFF4A2A1A)
              : const Color(0xFF3F4E34);
          textColor = isLowTime ? Colors.amberAccent : Colors.white;
          border = Border.all(
            color: isLowTime ? Colors.amberAccent : const Color(0xFF81B64C),
            width: 2,
          );
        } else {
          backgroundColor = const Color(0xFF262421);
          textColor = Colors.white70;
          border = Border.all(color: Colors.white12, width: 1);
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8.0),
            border: border,
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color:
                          (isLowTime ? Colors.amber : const Color(0xFF81B64C))
                              .withValues(alpha: 0.25),
                      blurRadius: 8,
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
              const SizedBox(width: 8),
              Text(
                playerName,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                clock.formatTime(color),
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'monospace',
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
