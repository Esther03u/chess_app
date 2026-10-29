import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../domain/game_logic.dart';
import '../models/customization_options.dart';
import '../models/game_record.dart';
import '../providers/game_controller.dart';
import '../providers/settings_provider.dart';
import '../widgets/board_view.dart';
import '../widgets/player_profile_bar.dart';
import 'analysis_screen.dart';
import 'history_screen.dart';
import 'puzzle_screen.dart';
import 'settings_screen.dart';

/// Screen supporting two-player pass & play or playing against the bot (3 difficulty levels)
/// with digital chess clocks, increment, and flag detection (FR3).
class GameScreen extends StatelessWidget {
  final bool isEmbeddedInHub;

  const GameScreen({super.key, this.isEmbeddedInHub = false});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameController>(
      builder: (context, controller, child) {
        final modeTitle = controller.gameMode == GameMode.humanVsHuman
            ? AppStrings.humanVsHuman
            : '${AppStrings.playVsBot} (${_botLevelLabel(controller.botLevel)})';

        final isFlipped =
            controller.gameMode == GameMode.vsBot &&
            controller.playerColor == PlayerColor.black;

        final topColor = isFlipped ? PlayerColor.white : PlayerColor.black;
        final bottomColor = isFlipped ? PlayerColor.black : PlayerColor.white;

        final topName = controller.gameMode == GameMode.vsBot
            ? (isFlipped
                  ? 'คุณ (หมากขาว)'
                  : 'บอท (${_botLevelLabel(controller.botLevel)})')
            : (isFlipped ? AppStrings.white : AppStrings.black);

        final bottomName = controller.gameMode == GameMode.vsBot
            ? (isFlipped
                  ? 'บอท (${_botLevelLabel(controller.botLevel)})'
                  : 'คุณ (หมากขาว)')
            : (isFlipped ? AppStrings.black : AppStrings.white);

        SettingsProvider? settings;
        try {
          settings = context.watch<SettingsProvider>();
        } catch (_) {}
        final pieceStyle = settings?.pieceStyle ?? PieceStylePreset.staunton;

        // Player details
        final isVsBot = controller.gameMode == GameMode.vsBot;
        final topIsBot = isVsBot && !isFlipped;
        final bottomIsBot = isVsBot && isFlipped;

        final topCaptured = topColor == PlayerColor.white
            ? controller.capturedByWhite
            : controller.capturedByBlack;
        final bottomCaptured = bottomColor == PlayerColor.white
            ? controller.capturedByWhite
            : controller.capturedByBlack;

        final topAdvantage = topColor == PlayerColor.white
            ? (controller.materialAdvantage > 0
                  ? controller.materialAdvantage
                  : 0)
            : (controller.materialAdvantage < 0
                  ? -controller.materialAdvantage
                  : 0);
        final bottomAdvantage = bottomColor == PlayerColor.white
            ? (controller.materialAdvantage > 0
                  ? controller.materialAdvantage
                  : 0)
            : (controller.materialAdvantage < 0
                  ? -controller.materialAdvantage
                  : 0);

        final botQuote = _getBotQuote(controller.botLevel);

        return Scaffold(
          backgroundColor: AppTheme.background,
          appBar: AppBar(
            automaticallyImplyLeading: !isEmbeddedInHub,
            title: Text(
              modeTitle,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            backgroundColor: AppTheme.surface,
            foregroundColor: AppTheme.textPrimary,
            elevation: 0,
            actions: [
              IconButton(
                icon: const Icon(Icons.psychology_outlined),
                tooltip: AppStrings.dailyPuzzle,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const PuzzleScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.history),
                tooltip: AppStrings.gameHistory,
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          HistoryScreen(dbService: controller.dbService),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.timer_outlined),
                tooltip: AppStrings.timeControl,
                onPressed: () => _showGameModeDialog(context, controller),
              ),
              IconButton(
                icon: const Icon(Icons.palette_outlined),
                tooltip: 'ตั้งค่าธีมและตัวหมาก',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: AppStrings.restart,
                onPressed: () => _confirmRestart(context),
              ),
            ],
          ),
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isWideScreen = constraints.maxWidth >= 760;

                if (isWideScreen) {
                  return _buildDesktopLayout(
                    context,
                    controller,
                    topName: topName,
                    bottomName: bottomName,
                    topColor: topColor,
                    bottomColor: bottomColor,
                    topIsBot: topIsBot,
                    bottomIsBot: bottomIsBot,
                    topCaptured: topCaptured,
                    bottomCaptured: bottomCaptured,
                    topAdvantage: topAdvantage,
                    bottomAdvantage: bottomAdvantage,
                    isFlipped: isFlipped,
                    pieceStyle: pieceStyle,
                    botQuote: botQuote,
                  );
                }

                return _buildMobileLayout(
                  context,
                  controller,
                  topName: topName,
                  bottomName: bottomName,
                  topColor: topColor,
                  bottomColor: bottomColor,
                  topIsBot: topIsBot,
                  bottomIsBot: bottomIsBot,
                  topCaptured: topCaptured,
                  bottomCaptured: bottomCaptured,
                  topAdvantage: topAdvantage,
                  bottomAdvantage: bottomAdvantage,
                  isFlipped: isFlipped,
                  pieceStyle: pieceStyle,
                  botQuote: botQuote,
                );
              },
            ),
          ),
        );
      },
    );
  }

  static String _botLevelLabel(BotLevel level) {
    switch (level) {
      case BotLevel.easy:
        return 'ง่าย';
      case BotLevel.medium:
        return 'ปานกลาง';
      case BotLevel.hard:
        return 'ยาก';
    }
  }

  static String _getBotQuote(BotLevel level) {
    switch (level) {
      case BotLevel.easy:
        return 'ยินดีที่ได้เล่นด้วยกันนะ! มาสนุกกับเกมนี้กันเถอะ';
      case BotLevel.medium:
        return 'รูปเกมกำลังน่าสนใจ ระวังการบุกที่มุมบอร์ดให้ดีล่ะ!';
      case BotLevel.hard:
        return 'ฉันคำนวณการเดินล่วงหน้าไว้แล้ว ทุกก้าวมีความหมาย!';
    }
  }

  /// Mobile layout: Vertical stack optimized for handheld play with player profile bars
  Widget _buildMobileLayout(
    BuildContext context,
    GameController controller, {
    required String topName,
    required String bottomName,
    required PlayerColor topColor,
    required PlayerColor bottomColor,
    required bool topIsBot,
    required bool bottomIsBot,
    required List<PieceType> topCaptured,
    required List<PieceType> bottomCaptured,
    required int topAdvantage,
    required int bottomAdvantage,
    required bool isFlipped,
    required PieceStylePreset pieceStyle,
    required String botQuote,
  }) {
    return Column(
      children: [
        // 1. Status bar with check / timeout alerts
        _buildStatusBar(context, controller),

        // 2. Top Player Profile Bar (Opponent / Bot)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: PlayerProfileBar(
            color: topColor,
            name: topName,
            subtitle: topIsBot
                ? 'บอท (${_botLevelLabel(controller.botLevel)})'
                : null,
            isBot: topIsBot,
            botLevel: topIsBot ? controller.botLevel : null,
            capturedPieces: topCaptured,
            materialAdvantage: topAdvantage,
            isTurn: controller.turn == topColor && !controller.isGameOver,
            pieceStyle: pieceStyle,
          ),
        ),

        // 3. Chess Board in Center
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: BoardView(
                isFlipped: isFlipped,
                onPromotionRequested: () =>
                    _showPromotionDialog(context, controller.turn),
              ),
            ),
          ),
        ),

        // 4. Bottom Player Profile Bar (User)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
          child: PlayerProfileBar(
            color: bottomColor,
            name: bottomName,
            subtitle: bottomIsBot
                ? 'บอท (${_botLevelLabel(controller.botLevel)})'
                : 'ผู้เล่น',
            isBot: bottomIsBot,
            botLevel: bottomIsBot ? controller.botLevel : null,
            capturedPieces: bottomCaptured,
            materialAdvantage: bottomAdvantage,
            isTurn: controller.turn == bottomColor && !controller.isGameOver,
            pieceStyle: pieceStyle,
          ),
        ),

        // 5. Move history strip
        _buildMoveHistory(controller),

        // 6. Action buttons (Undo, Resign, TimeControl)
        _buildActionButtons(context, controller),
      ],
    );
  }

  /// Desktop layout: Left side board with player frames, Right side Chess.com sidebar
  Widget _buildDesktopLayout(
    BuildContext context,
    GameController controller, {
    required String topName,
    required String bottomName,
    required PlayerColor topColor,
    required PlayerColor bottomColor,
    required bool topIsBot,
    required bool bottomIsBot,
    required List<PieceType> topCaptured,
    required List<PieceType> bottomCaptured,
    required int topAdvantage,
    required int bottomAdvantage,
    required bool isFlipped,
    required PieceStylePreset pieceStyle,
    required String botQuote,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Left Arena: Top Player Bar + Square Board + Bottom Player Bar
          Expanded(
            flex: 6,
            child: Column(
              children: [
                // Top Player Profile Bar
                PlayerProfileBar(
                  color: topColor,
                  name: topName,
                  subtitle: topIsBot
                      ? 'บอท (${_botLevelLabel(controller.botLevel)})'
                      : null,
                  isBot: topIsBot,
                  botLevel: topIsBot ? controller.botLevel : null,
                  capturedPieces: topCaptured,
                  materialAdvantage: topAdvantage,
                  isTurn: controller.turn == topColor && !controller.isGameOver,
                  pieceStyle: pieceStyle,
                ),
                const SizedBox(height: 8),

                // Center Square Chess Board
                Expanded(
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: 1.0,
                      child: BoardView(
                        isFlipped: isFlipped,
                        onPromotionRequested: () =>
                            _showPromotionDialog(context, controller.turn),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Bottom Player Profile Bar
                PlayerProfileBar(
                  color: bottomColor,
                  name: bottomName,
                  subtitle: bottomIsBot
                      ? 'บอท (${_botLevelLabel(controller.botLevel)})'
                      : 'ผู้เล่น',
                  isBot: bottomIsBot,
                  botLevel: bottomIsBot ? controller.botLevel : null,
                  capturedPieces: bottomCaptured,
                  materialAdvantage: bottomAdvantage,
                  isTurn:
                      controller.turn == bottomColor && !controller.isGameOver,
                  pieceStyle: pieceStyle,
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),

          // Right Sidebar: Chess.com style panel (Bot speech bubble + Moves table + Actions)
          Expanded(
            flex: 4,
            child: Container(
              decoration: BoxDecoration(
                color: AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.border),
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
                  // Bot Persona Speech Bubble (Chess.com play/computer style)
                  if (controller.gameMode == GameMode.vsBot)
                    Container(
                      padding: const EdgeInsets.all(14.0),
                      decoration: const BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(12),
                          topRight: Radius.circular(12),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: const Color(0xFF383531),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppTheme.primaryGreen),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.smart_toy,
                                color: AppTheme.primaryGreen,
                                size: 26,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      topIsBot ? topName : bottomName,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1.5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryGreenDark,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        controller.botLevel == BotLevel.easy
                                            ? '400'
                                            : (controller.botLevel ==
                                                      BotLevel.medium
                                                  ? '1200'
                                                  : '1800'),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: AppTheme.border),
                                  ),
                                  child: Text(
                                    botQuote,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Game Status Bar
                  _buildStatusBar(context, controller),

                  // Move History Table (Scrollable full height)
                  Expanded(
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 6.0,
                      ),
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(8.0),
                        border: Border.all(color: AppTheme.border),
                      ),
                      child: controller.history.isEmpty
                          ? const Center(
                              child: Text(
                                'ยังไม่มีตาเดิน (เริ่มเดินหมากได้เลย)',
                                style: TextStyle(
                                  color: Colors.white54,
                                  fontSize: 13,
                                ),
                              ),
                            )
                          : ListView.builder(
                              itemCount: (controller.history.length / 2).ceil(),
                              itemBuilder: (context, index) {
                                final moveNumber = index + 1;
                                final whiteMove = controller.history[index * 2];
                                final blackMove =
                                    (index * 2 + 1 < controller.history.length)
                                    ? controller.history[index * 2 + 1]
                                    : '';
                                final isLatest =
                                    index ==
                                    (controller.history.length / 2).ceil() - 1;

                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8.0,
                                    vertical: 6.0,
                                  ),
                                  color: isLatest
                                      ? AppTheme.primaryGreen.withValues(
                                          alpha: 0.15,
                                        )
                                      : (index % 2 == 0
                                            ? Colors.transparent
                                            : Colors.white.withValues(
                                                alpha: 0.02,
                                              )),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 32,
                                        child: Text(
                                          '$moveNumber.',
                                          style: const TextStyle(
                                            color: Colors.white38,
                                            fontSize: 13,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          whiteMove,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          blackMove,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 13,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ),

                  // Action Toolbar (Undo, Resign, Restart, Analysis)
                  _buildActionButtons(context, controller),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBar(BuildContext context, GameController controller) {
    final isWhiteTurn = controller.turn == PlayerColor.white;
    final isAlert = controller.isInCheck || controller.isTimedOut;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      margin: const EdgeInsets.fromLTRB(12.0, 10.0, 12.0, 4.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: isAlert ? AppTheme.errorRed : AppTheme.border,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                if (controller.isBotThinking) ...[
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber),
                    ),
                  ),
                  const SizedBox(width: 10),
                ] else ...[
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
                ],
                Expanded(
                  child: Text(
                    controller.statusMessage,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: controller.isBotThinking
                          ? Colors.amber
                          : isAlert
                          ? Colors.redAccent
                          : Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (controller.isGameOver)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.amber.shade800,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                controller.result ?? '',
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
      height: 44,
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      decoration: BoxDecoration(
        color: AppTheme.surfaceVariant,
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: AppTheme.border),
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
                    vertical: 10.0,
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
    if (controller.isGameOver) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.insights, size: 18),
                label: const Text(AppStrings.gameAnalysis),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmberDark,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () {
                  final record = GameRecord(
                    pgn: controller.toPgn(),
                    white: controller.gameMode == GameMode.vsBot
                        ? (controller.playerColor == PlayerColor.white
                              ? 'คุณ'
                              : 'บอท')
                        : AppStrings.white,
                    black: controller.gameMode == GameMode.vsBot
                        ? (controller.playerColor == PlayerColor.black
                              ? 'คุณ'
                              : 'บอท')
                        : AppStrings.black,
                    result: controller.result ?? '*',
                    timeControl: controller.clock?.timeControl.label,
                    playedAt: DateTime.now().millisecondsSinceEpoch,
                  );
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => AnalysisScreen(record: record),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text(AppStrings.restart),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: () => _confirmRestart(context),
              ),
            ),
          ],
        ),
      );
    }

    final canUndo =
        controller.history.isNotEmpty &&
        !controller.isGameOver &&
        !controller.isBotThinking;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
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
              onPressed: canUndo ? () => controller.undo() : null,
            ),
          ),
          const SizedBox(width: 10),
          IconButton.filledTonal(
            tooltip: AppStrings.timeControl,
            icon: const Icon(Icons.tune, size: 20),
            onPressed: () => _showGameModeDialog(context, controller),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.flag_outlined, size: 18),
              label: const Text(AppStrings.resign),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed.withValues(alpha: 0.25),
                foregroundColor: Colors.red.shade200,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: !controller.isGameOver && !controller.isBotThinking
                  ? () => _confirmResign(context, controller)
                  : null,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showGameModeDialog(
    BuildContext context,
    GameController controller,
  ) async {
    GameMode selectedMode = controller.gameMode;
    BotLevel selectedLevel = controller.botLevel;
    PlayerColor selectedColor = controller.playerColor;
    TimeControl selectedTime =
        controller.clock?.timeControl ?? TimeControl.rapid10p0;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: AppTheme.surfaceCard,
            title: const Text(
              'ตั้งค่าเกมและเวลา (Game Settings)',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'โหมดเกม',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<GameMode>(
                      segments: const [
                        ButtonSegment(
                          value: GameMode.humanVsHuman,
                          label: Text('เล่น 2 คน'),
                        ),
                        ButtonSegment(
                          value: GameMode.vsBot,
                          label: Text('เล่นกับบอท'),
                        ),
                      ],
                      selected: {selectedMode},
                      onSelectionChanged: (newSelection) {
                        setState(() => selectedMode = newSelection.first);
                      },
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppTheme.primaryGreen,
                        selectedForegroundColor: Colors.white,
                        foregroundColor: Colors.white70,
                      ),
                    ),
                  ),
                  if (selectedMode == GameMode.vsBot) ...[
                    const Divider(color: Colors.white24, height: 24),
                    const Text(
                      AppStrings.botLevel,
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<BotLevel>(
                      segments: const [
                        ButtonSegment(
                          value: BotLevel.easy,
                          label: Text('ง่าย'),
                        ),
                        ButtonSegment(
                          value: BotLevel.medium,
                          label: Text('ปานกลาง'),
                        ),
                        ButtonSegment(value: BotLevel.hard, label: Text('ยาก')),
                      ],
                      selected: {selectedLevel},
                      onSelectionChanged: (newSelection) {
                        setState(() => selectedLevel = newSelection.first);
                      },
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppTheme.primaryGreen,
                        selectedForegroundColor: Colors.white,
                        foregroundColor: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'เลือกฝั่งผู้เล่น',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<PlayerColor>(
                      segments: const [
                        ButtonSegment(
                          value: PlayerColor.white,
                          label: Text(AppStrings.white),
                        ),
                        ButtonSegment(
                          value: PlayerColor.black,
                          label: Text(AppStrings.black),
                        ),
                      ],
                      selected: {selectedColor},
                      onSelectionChanged: (newSelection) {
                        setState(() => selectedColor = newSelection.first);
                      },
                      style: SegmentedButton.styleFrom(
                        selectedBackgroundColor: AppTheme.primaryGreen,
                        selectedForegroundColor: Colors.white,
                        foregroundColor: Colors.white70,
                      ),
                    ),
                  ],
                  const Divider(color: Colors.white24, height: 24),
                  const Text(
                    AppStrings.timeControl,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<TimeControl>(
                    initialValue: selectedTime,
                    dropdownColor: AppTheme.surfaceCard,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppTheme.surfaceVariant,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8.0),
                        borderSide: const BorderSide(color: Colors.white24),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 10.0,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: TimeControl.unlimited,
                        child: Text(AppStrings.unlimited),
                      ),
                      DropdownMenuItem(
                        value: TimeControl.blitz3p2,
                        child: Text(AppStrings.blitz3p2),
                      ),
                      DropdownMenuItem(
                        value: TimeControl.blitz5p0,
                        child: Text(AppStrings.blitz5p0),
                      ),
                      DropdownMenuItem(
                        value: TimeControl.rapid10p0,
                        child: Text(AppStrings.rapid10p0),
                      ),
                      DropdownMenuItem(
                        value: TimeControl.rapid15p10,
                        child: Text(AppStrings.rapid15p10),
                      ),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => selectedTime = val);
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: const Text(
                  AppStrings.cancel,
                  style: TextStyle(color: Colors.white54),
                ),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                ),
                child: const Text(
                  AppStrings.confirm,
                  style: TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  controller.setGameMode(
                    selectedMode,
                    playerColor: selectedColor,
                    botLevel: selectedLevel,
                    timeControl: selectedTime,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmRestart(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppTheme.surfaceCard,
        title: const Text(
          'เริ่มเกมใหม่?',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'กระดานและนาฬิกาปัจจุบันจะถูกรีเซ็ต',
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
              backgroundColor: AppTheme.primaryGreen,
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
        backgroundColor: AppTheme.surfaceCard,
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
      await controller.resign(controller.turn);
      if (!context.mounted) return;
      final isBot = controller.gameMode == GameMode.vsBot;
      final winnerMsg = isBot
          ? AppStrings.botWon
          : (controller.turn == PlayerColor.white
                ? AppStrings.blackWon
                : AppStrings.whiteWon);

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppTheme.surfaceCard,
          title: const Text('จบเกม', style: TextStyle(color: Colors.white)),
          content: Text(
            winnerMsg,
            style: const TextStyle(color: Colors.white, fontSize: 16),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
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
        backgroundColor: AppTheme.surfaceCard,
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
            color: AppTheme.surfaceVariant,
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
