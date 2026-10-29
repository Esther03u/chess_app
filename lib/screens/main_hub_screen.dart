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
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              gradient: AppTheme.greenGradient,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                  blurRadius: 14,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(Icons.shield_rounded, color: Colors.white, size: 30),
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
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.textPrimary,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(
                  'MASTER THE BOARD • PLAY & LEARN',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                    color: AppTheme.primaryGreenLight.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppTheme.surfaceCard,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.border),
            ),
            child: IconButton(
              icon: const Icon(
                Icons.palette_outlined,
                color: AppTheme.accentAmber,
                size: 24,
              ),
              tooltip: 'ตกแต่งบอร์ดและตัวหมาก',
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveGameBanner(GameController controller) {
    return InkWell(
      onTap: () => switchTab(1),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.accentAmber.withValues(alpha: 0.16),
              AppTheme.surfaceCard,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppTheme.accentAmber.withValues(alpha: 0.6),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: AppTheme.accentAmber.withValues(alpha: 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.accentAmber.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.play_arrow_rounded,
                color: AppTheme.accentAmber,
                size: 28,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'เกมกำลังดำเนินอยู่ (Active Match)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.accentAmber,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'เล่นไปแล้ว ${controller.history.length} ตา • แตะเพื่อกลับเข้าสู่กระดานทันที',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.accentAmber,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVsBotCard(GameController controller) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card Title Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: AppTheme.greenGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.smart_toy_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppStrings.quickVsBot,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'เลือกระดับความท้าทายจาก Minimax Engine อัจฉริยะ',
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
            const SizedBox(height: 20),

            // Bot Character Persona Selector (Cards with avatars and ratings)
            const Text(
              'เลือกระดับคู่ต่อสู้ AI',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildBotPersonaCard(
                  level: 1,
                  name: 'Elani',
                  rating: '400',
                  difficulty: 'ง่าย',
                  accentColor: const Color(0xFF68D391),
                  icon: Icons.face_retouching_natural,
                ),
                const SizedBox(width: 10),
                _buildBotPersonaCard(
                  level: 2,
                  name: 'Marcus',
                  rating: '1200',
                  difficulty: 'ปานกลาง',
                  accentColor: AppTheme.accentAmber,
                  icon: Icons.person_pin,
                ),
                const SizedBox(width: 10),
                _buildBotPersonaCard(
                  level: 3,
                  name: 'Magnus Bot',
                  rating: '1800',
                  difficulty: 'ยาก',
                  accentColor: const Color(0xFFFC8181),
                  icon: Icons.military_tech_rounded,
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Side Selector (White / Random / Black)
            const Text(
              'เลือกสีหมากของคุณ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _buildSideChoice(
                  label: 'หมากขาว',
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
                const SizedBox(width: 10),
                _buildSideChoice(
                  label: 'สุ่มสี',
                  icon: Icons.casino_outlined,
                  iconColor: AppTheme.accentAmber,
                  isSelected: _isRandomColor,
                  onTap: () {
                    setState(() {
                      _isRandomColor = true;
                    });
                  },
                ),
                const SizedBox(width: 10),
                _buildSideChoice(
                  label: 'หมากดำ',
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
            const SizedBox(height: 18),

            // Time Control selector
            const Text(
              'รูปแบบเวลา (Clock Control)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTimeChip(TimeControl.unlimited, '♾️ ไม่จำกัด'),
                _buildTimeChip(TimeControl.blitz3p2, '⚡ 3+2 (Blitz)'),
                _buildTimeChip(TimeControl.blitz5p0, '⏱️ 5 นาที'),
                _buildTimeChip(TimeControl.rapid10p0, '⌛ 10 นาที (Rapid)'),
              ],
            ),
            const SizedBox(height: 22),

            // Start Match Button with Gradient Glow
            Container(
              width: double.infinity,
              height: 50,
              decoration: BoxDecoration(
                gradient: AppTheme.greenGradient,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
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
                icon: const Icon(Icons.play_arrow_rounded, size: 24),
                label: const Text(
                  'เริ่มแข่งขัน (Start Game)',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotPersonaCard({
    required int level,
    required String name,
    required String rating,
    required String difficulty,
    required Color accentColor,
    required IconData icon,
  }) {
    final isSelected = _selectedBotLevel == level;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedBotLevel = level;
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected
                ? accentColor.withValues(alpha: 0.16)
                : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? accentColor : AppTheme.border,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isSelected
                      ? accentColor.withValues(alpha: 0.25)
                      : const Color(0xFF383531),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? accentColor : Colors.white70,
                  size: 22,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isSelected ? Colors.white : AppTheme.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected ? accentColor : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  rating,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: isSelected ? Colors.black : AppTheme.textSecondary,
                  ),
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
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            controller.startHumanVsHuman(timeControl: _selectedTimeControl);
            switchTab(1);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentBlue.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentBlue.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.people_alt_rounded,
                    color: AppTheme.accentBlue,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
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
                      SizedBox(height: 3),
                      Text(
                        'เล่นกับเพื่อนแบบ 2 คนบนเครื่องเดียวกัน พร้อมระบบนาฬิกาแข่ง',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDailyPuzzleCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentAmber.withValues(alpha: 0.14),
            AppTheme.surfaceCard,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.accentAmber.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => switchTab(2),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: AppTheme.amberGradient,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.accentAmber.withValues(alpha: 0.35),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.psychology_rounded,
                    color: Colors.black,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
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
                      SizedBox(height: 3),
                      Text(
                        'โจทย์ลับสมองดึงสดจาก Lichess API ตรวจคำตอบอัตโนมัติ',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    gradient: AppTheme.amberGradient,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'แก้โจทย์',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => switchTab(3),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.accentPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.accentPurple.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.insights_rounded,
                    color: AppTheme.accentPurple,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ประวัติและวิเคราะห์เกม (History & Replay)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        'บันทึก SQLite อัตโนมัติ Replay ตาเดิน พร้อมกราฟประเมินแต้ม',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCustomizationCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen()));
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(18.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  child: const Icon(
                    Icons.palette_rounded,
                    color: AppTheme.primaryGreen,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ตกแต่งกระดานและตัวหมาก (Customization)',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      SizedBox(height: 3),
                      Text(
                        '5 ธีมสีกระดาน (เขียว/ไม้/หินชนวน) • 4 สไตล์ตัวหมาก • แอนิเมชัน',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 16,
                  color: AppTheme.textMuted,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
