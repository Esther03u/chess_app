import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/strings.dart';
import '../domain/game_logic.dart';
import '../providers/game_controller.dart';
import '../widgets/board_view.dart';

/// Screen where two human players can play chess against each other on one device.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF262421),
      appBar: AppBar(
        title: const Text(
          AppStrings.humanVsHuman,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: AppStrings.restart,
            onPressed: () => _confirmRestart(context),
          ),
        ],
      ),
      body: SafeArea(
        child: Consumer<GameController>(
          builder: (context, controller, child) {
            return Column(
              children: [
                // Top status bar
                _buildStatusBar(context, controller),

                // Chess board in center (responsive square, fits available height and width)
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: BoardView(
                        onPromotionRequested: () =>
                            _showPromotionDialog(context, controller.turn),
                      ),
                    ),
                  ),
                ),

                // Move history
                _buildMoveHistory(controller),

                // Action buttons (Undo, Resign)
                _buildActionButtons(context, controller),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, GameController controller) {
    final isWhiteTurn = controller.turn == PlayerColor.white;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      margin: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF312E2B),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: controller.isInCheck ? Colors.redAccent : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isWhiteTurn ? Colors.white : Colors.black,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey, width: 1),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                controller.statusMessage,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: controller.isInCheck ? Colors.redAccent : Colors.white,
                ),
              ),
            ],
          ),
          if (controller.isGameOver)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade800,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                controller.game.result ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMoveHistory(GameController controller) {
    final history = controller.history;

    return Container(
      height: 48,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: history.isEmpty
          ? const Center(
              child: Text(
                'ยังไม่มีตาเดิน',
                style: TextStyle(color: Colors.white54, fontSize: 13),
              ),
            )
          : ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: (history.length / 2).ceil(),
              itemBuilder: (context, index) {
                final moveNumber = index + 1;
                final whiteMove = history[index * 2];
                final blackMove = (index * 2 + 1 < history.length)
                    ? history[index * 2 + 1]
                    : '';

                return Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6.0,
                    vertical: 12.0,
                  ),
                  child: Row(
                    children: [
                      Text(
                        '$moveNumber. ',
                        style: const TextStyle(
                          color: Colors.white54,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        whiteMove,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                      if (blackMove.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          blackMove,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildActionButtons(BuildContext context, GameController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              icon: const Icon(Icons.undo, size: 18),
              label: const Text(AppStrings.undo),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white24),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: controller.history.isNotEmpty && !controller.isGameOver
                  ? () => controller.undo()
                  : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: const Text(AppStrings.resign),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF452424),
                foregroundColor: Colors.red.shade200,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: !controller.isGameOver
                  ? () => _confirmResign(context, controller)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRestart(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF312E2B),
        title: const Text(
          'เริ่มเกมใหม่?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'กระดานปัจจุบันจะถูกรีเซ็ต',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(color: Colors.white54),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF769656),
            ),
            child: const Text(
              AppStrings.confirm,
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      context.read<GameController>().reset();
    }
  }

  Future<void> _confirmResign(
    BuildContext context,
    GameController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF312E2B),
        title: const Text(
          AppStrings.resign,
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          AppStrings.confirmResign,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(color: Colors.white54),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text(
              AppStrings.confirm,
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      // Current player resigns, meaning the opponent wins
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFF312E2B),
          title: const Text('จบเกม', style: TextStyle(color: Colors.white)),
          content: Text(
            controller.turn == PlayerColor.white
                ? AppStrings.blackWon
                : AppStrings.whiteWon,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF769656),
              ),
              child: const Text(
                AppStrings.newGame,
                style: TextStyle(color: Colors.white),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                controller.reset();
              },
            ),
          ],
        ),
      );
    }
  }

  Future<String?> _showPromotionDialog(
    BuildContext context,
    PlayerColor color,
  ) async {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF312E2B),
        title: const Text(
          AppStrings.choosePromotion,
          style: TextStyle(fontSize: 16, color: Colors.white),
        ),
        content: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _promotionOption(
              ctx,
              'q',
              color == PlayerColor.white ? '\u2655' : '\u265B',
              AppStrings.queen,
            ),
            _promotionOption(
              ctx,
              'r',
              color == PlayerColor.white ? '\u2656' : '\u265C',
              AppStrings.rook,
            ),
            _promotionOption(
              ctx,
              'b',
              color == PlayerColor.white ? '\u2657' : '\u265D',
              AppStrings.bishop,
            ),
            _promotionOption(
              ctx,
              'n',
              color == PlayerColor.white ? '\u2658' : '\u265E',
              AppStrings.knight,
            ),
          ],
        ),
      ),
    );
  }

  Widget _promotionOption(
    BuildContext context,
    String code,
    String symbol,
    String tooltip,
  ) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: () => Navigator.of(context).pop(code),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF3F3B36),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            symbol,
            style: const TextStyle(fontSize: 32, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
