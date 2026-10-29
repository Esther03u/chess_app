import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/strings.dart';
import '../core/theme.dart';
import '../domain/game_logic.dart';
import '../providers/game_controller.dart';
import 'game_screen.dart';
import 'history_screen.dart';
import 'puzzle_screen.dart';
import 'settings_screen.dart';

/// Main navigation shell and dashboard for the Chess application.
/// Provides a clear, intuitive 4-tab interface with quick match start and mode configurations.
class MainHubScreen extends StatefulWidget {
  final int initialIndex;

  const MainHubScreen({super.key, this.initialIndex = 0});

  @override
  State<MainHubScreen> createState() => MainHubScreenState();
}

class MainHubScreenState extends State<MainHubScreen> {
  late int _currentIndex;

  // Quick setup state for "Play vs Bot"
  int _selectedBotLevel = 2; // Medium by default
  PlayerColor _selectedColor = PlayerColor.white;
  bool _isRandomColor = false;
  TimeControl _selectedTimeControl = TimeControl.unlimited;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void switchTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();

    final screens = [
      _buildHomeDashboard(context, controller),
      const GameScreen(isEmbeddedInHub: true),
      const PuzzleScreen(isEmbeddedInHub: true),
      HistoryScreen(dbService: controller.dbService, isEmbeddedInHub: true),
    ];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(index: _currentIndex, children: screens),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: AppTheme.border, width: 1.0)),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          backgroundColor: AppTheme.surface,
          indicatorColor: AppTheme.primaryGreen.withValues(alpha: 0.25),
          onDestinationSelected: (idx) {
            setState(() {
              _currentIndex = idx;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home, color: AppTheme.primaryGreen),
              label: AppStrings.navHome,
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_4x4_outlined),
              selectedIcon: Icon(Icons.grid_4x4, color: AppTheme.primaryGreen),
              label: AppStrings.navGame,
            ),
            NavigationDestination(
              icon: Icon(Icons.psychology_outlined),
              selectedIcon: Icon(
                Icons.psychology,
                color: AppTheme.primaryGreen,
              ),
              label: AppStrings.navPuzzle,
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: AppTheme.primaryGreen),
              label: AppStrings.navHistory,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeDashboard(BuildContext context, GameController controller) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top App Bar / Brand Header
            _buildBrandHeader(),
            const SizedBox(height: 20),

            // Active Game Banner (if in-progress)
            if (controller.isInProgress) ...[
              _buildActiveGameBanner(controller),
              const SizedBox(height: 18),
            ],

            // Card 1: Play vs Bot (Quick Config)
            _buildVsBotCard(controller),
            const SizedBox(height: 16),

            // Card 2: Pass & Play (2 Players)
            _buildPassPlayCard(controller),
            const SizedBox(height: 16),

            // Card 3: Daily Puzzle Banner
            _buildDailyPuzzleCard(),
            const SizedBox(height: 16),

            // Card 4: Game History & Analysis
            _buildHistoryCard(),
            const SizedBox(height: 16),

            // Card 5: Customization & Themes
            _buildCustomizationCard(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBrandHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryGreen, AppTheme.primaryGreenDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.shield, color: Colors.white, size: 28),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  AppStrings.appTitle,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  AppStrings.appSlogan,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.palette_outlined,
              color: AppTheme.accentAmber,
              size: 26,
            ),
            tooltip: 'ตกแต่งบอร์ดและตัวหมาก',
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGameBanner(GameController controller) {
    return InkWell(
      onTap: () => switchTab(1),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.accentAmber.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppTheme.accentAmber.withValues(alpha: 0.5),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.play_circle_filled,
              color: AppTheme.accentAmber,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'มีเกมที่กำลังเล่นอยู่',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentAmber,
                      fontSize: 14,
                    ),
                  ),
                  Text(
                    'จำนวนตาเดิน: ${controller.history.length} ตา • แตะเพื่อเล่นต่อ',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.accentAmber,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVsBotCard(GameController controller) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.smart_toy_outlined,
                    color: AppTheme.primaryGreen,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.quickVsBot,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'ท้าประลองกับระบบ AI 3 ระดับ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Difficulty Selector Pills
            const Text(
              AppStrings.botDifficulty,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildDifficultyPill(1, AppStrings.easyLevel, Colors.green),
                const SizedBox(width: 8),
                _buildDifficultyPill(2, AppStrings.mediumLevel, Colors.amber),
                const SizedBox(width: 8),
                _buildDifficultyPill(3, AppStrings.hardLevel, Colors.redAccent),
              ],
            ),
            const SizedBox(height: 14),

            // Side Selector (White / Random / Black)
            const Text(
              AppStrings.chooseSide,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _buildSideChoice(
                  label: AppStrings.white,
                  icon: Icons.circle,
                  iconColor: Colors.white,
                  isSelected:
                      !_isRandomColor && _selectedColor == PlayerColor.white,
                  onTap: () {
                    setState(() {
                      _isRandomColor = false;
                      _selectedColor = PlayerColor.white;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildSideChoice(
                  label: AppStrings.randomSide,
                  icon: Icons.casino_outlined,
                  iconColor: AppTheme.accentAmber,
                  isSelected: _isRandomColor,
                  onTap: () {
                    setState(() {
                      _isRandomColor = true;
                    });
                  },
                ),
                const SizedBox(width: 8),
                _buildSideChoice(
                  label: AppStrings.black,
                  icon: Icons.circle,
                  iconColor: AppTheme.blackPieceFill,
                  isSelected:
                      !_isRandomColor && _selectedColor == PlayerColor.black,
                  onTap: () {
                    setState(() {
                      _isRandomColor = false;
                      _selectedColor = PlayerColor.black;
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Time Control selector
            const Text(
              AppStrings.timeControl,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildTimeChip(TimeControl.unlimited, '♾️ ไม่จำกัด'),
                _buildTimeChip(TimeControl.blitz3p2, '⚡ 3+2'),
                _buildTimeChip(TimeControl.blitz5p0, '⏱️ 5 นาที'),
                _buildTimeChip(TimeControl.rapid10p0, '⌛ 10 นาที'),
              ],
            ),
            const SizedBox(height: 18),

            // Start Match Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton.icon(
                onPressed: () {
                  final chosenColor = _isRandomColor
                      ? (DateTime.now().millisecond % 2 == 0
                            ? PlayerColor.white
                            : PlayerColor.black)
                      : _selectedColor;

                  controller.startVsBot(
                    level: _selectedBotLevel,
                    playerColor: chosenColor,
                    timeControl: _selectedTimeControl,
                  );
                  switchTab(1);
                },
                icon: const Icon(Icons.play_arrow),
                label: const Text(
                  AppStrings.startGame,
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDifficultyPill(int level, String label, Color color) {
    final isSelected = _selectedBotLevel == level;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedBotLevel = level;
          });
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withValues(alpha: 0.22)
                : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? color : AppTheme.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Text(
                label.split(' ')[0],
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? color : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideChoice({
    required String label,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen.withValues(alpha: 0.2)
                : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected ? AppTheme.primaryGreen : AppTheme.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: iconColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected
                      ? AppTheme.primaryGreen
                      : AppTheme.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimeChip(TimeControl option, String label) {
    final isSelected = _selectedTimeControl == option;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedTimeControl = option;
          });
        }
      },
      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.25),
      backgroundColor: AppTheme.surfaceVariant,
      labelStyle: TextStyle(
        fontSize: 12,
        color: isSelected ? AppTheme.primaryGreen : AppTheme.textSecondary,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      side: BorderSide(
        color: isSelected ? AppTheme.primaryGreen : AppTheme.border,
      ),
    );
  }

  Widget _buildPassPlayCard(GameController controller) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          controller.startHumanVsHuman(timeControl: _selectedTimeControl);
          switchTab(1);
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blueAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.people_alt_outlined,
                  color: Colors.blueAccent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.humanVsHuman,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'เล่น 2 คนผลัดกันเดินบนเครื่องเดียวกัน',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDailyPuzzleCard() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => switchTab(2),
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.all(16.0),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              colors: [
                AppTheme.surfaceCard,
                AppTheme.primaryGreen.withValues(alpha: 0.08),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.psychology,
                  color: AppTheme.accentAmber,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.quickDailyPuzzle,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'โจทย์ลับสมองดึงสดจาก Lichess API',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () => switchTab(2),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentAmberDark,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                ),
                child: const Text(
                  'แก้โจทย์',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => switchTab(3),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.purpleAccent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.insights_outlined,
                  color: Colors.purpleAccent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppStrings.gameHistory,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'ดูย้อนหลัง Replay พร้อมกราฟวิเคราะห์ Advantage',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCustomizationCard(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context)
              .push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.accentAmber.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.palette_outlined,
                  color: AppTheme.accentAmber,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'ตกแต่งกระดานและตัวหมาก',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'เลือกธีมสีบอร์ด (เขียว/ไม้/หินชนวน) สไตล์ตัวหมาก และแอนิเมชัน',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.textMuted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
