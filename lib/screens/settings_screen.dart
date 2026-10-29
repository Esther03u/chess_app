import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../domain/game_logic.dart';
import '../models/customization_options.dart';
import '../providers/settings_provider.dart';
import '../widgets/chess_piece_painter.dart';

/// Screen for customizing board themes, piece styles, move animations,
/// and board coordinates with an interactive live preview.
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('ตั้งค่าการตกแต่ง'),
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.restore, color: AppTheme.textSecondary),
            tooltip: 'คืนค่าเริ่มต้น',
            onPressed: () async {
              await settings.resetToDefaults();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('คืนค่าเริ่มต้นเรียบร้อยแล้ว'),
                    duration: Duration(seconds: 2),
                    backgroundColor: AppTheme.surfaceCard,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 20.0),
        children: [
          // 1. Live Interactive Board Preview Card
          _buildLivePreviewCard(context, settings),

          const SizedBox(height: 24),

          // 2. Board Themes Section Header
          _buildSectionHeader(
            icon: Icons.palette_outlined,
            title: 'ธีมสีกระดานหมากรุก (Board Theme)',
          ),
          const SizedBox(height: 12),
          _buildBoardThemesSelector(context, settings),

          const SizedBox(height: 28),

          // 3. Piece Styles Section Header
          _buildSectionHeader(
            icon: Icons.auto_awesome_mosaic_outlined,
            title: 'สไตล์ตัวหมาก (Piece Style)',
          ),
          const SizedBox(height: 12),
          _buildPieceStylesSelector(context, settings),

          const SizedBox(height: 28),

          // 4. Game Controls & Display Toggles
          _buildSectionHeader(icon: Icons.tune, title: 'การแสดงผลและแอนิเมชัน'),
          const SizedBox(height: 12),
          _buildTogglesCard(context, settings),

          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({required IconData icon, required String title}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryGreen),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
      ],
    );
  }

  // --- 1. LIVE PREVIEW CARD ---
  Widget _buildLivePreviewCard(
    BuildContext context,
    SettingsProvider settings,
  ) {
    final theme = settings.boardTheme;
    final style = settings.pieceStyle;

    // 4x4 Mini preview board with diverse pieces
    final previewPieces = [
      // Row 1 (Black pieces)
      [
        PieceInfo(type: PieceType.rook, color: PlayerColor.black),
        PieceInfo(type: PieceType.knight, color: PlayerColor.black),
        PieceInfo(type: PieceType.bishop, color: PlayerColor.black),
        PieceInfo(type: PieceType.king, color: PlayerColor.black),
      ],
      // Row 2 (Black pawns & empty)
      [
        PieceInfo(type: PieceType.pawn, color: PlayerColor.black),
        null,
        null,
        PieceInfo(type: PieceType.pawn, color: PlayerColor.black),
      ],
      // Row 3 (White pawns & empty)
      [
        PieceInfo(type: PieceType.pawn, color: PlayerColor.white),
        null,
        PieceInfo(type: PieceType.queen, color: PlayerColor.white),
        null,
      ],
      // Row 4 (White pieces)
      [
        PieceInfo(type: PieceType.rook, color: PlayerColor.white),
        PieceInfo(type: PieceType.knight, color: PlayerColor.white),
        null,
        PieceInfo(type: PieceType.king, color: PlayerColor.white),
      ],
    ];

    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'ตัวอย่างการแสดงผลสด (Live Preview)',
                style: TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  style.name.split(' ').first,
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Center(
            child: SizedBox(
              width: 220,
              height: 220,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border, width: 2),
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: List.generate(4, (r) {
                    return Expanded(
                      child: Row(
                        children: List.generate(4, (c) {
                          final isLight = (r + c) % 2 == 0;
                          final piece = previewPieces[r][c];

                          return Expanded(
                            child: Container(
                              color: isLight
                                  ? theme.lightSquare
                                  : theme.darkSquare,
                              child: piece != null
                                  ? Center(
                                      child: Padding(
                                        padding: const EdgeInsets.all(3.0),
                                        child: ChessPieceWidget(
                                          piece: piece,
                                          style: style,
                                        ),
                                      ),
                                    )
                                  : null,
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
        ],
      ),
    );
  }

  // --- 2. BOARD THEMES SELECTOR ---
  Widget _buildBoardThemesSelector(
    BuildContext context,
    SettingsProvider settings,
  ) {
    return Column(
      children: BoardThemePreset.allPresets.map((preset) {
        final isSelected = settings.boardTheme.id == preset.id;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: InkWell(
            onTap: () => settings.setBoardTheme(preset),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                    : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.border,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  // Swatch badge: 2x2 mini grid showing light & dark square
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.black26),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Column(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(color: preset.lightSquare),
                              ),
                              Expanded(
                                child: Container(color: preset.darkSquare),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: Container(color: preset.darkSquare),
                              ),
                              Expanded(
                                child: Container(color: preset.lightSquare),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      preset.name,
                      style: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.textPrimary,
                        fontSize: 14,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryGreen,
                      size: 22,
                    )
                  else
                    const Icon(
                      Icons.radio_button_unchecked,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- 3. PIECE STYLES SELECTOR ---
  Widget _buildPieceStylesSelector(
    BuildContext context,
    SettingsProvider settings,
  ) {
    return Column(
      children: PieceStylePreset.values.map((style) {
        final isSelected = settings.pieceStyle == style;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10.0),
          child: InkWell(
            onTap: () => settings.setPieceStyle(style),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.primaryGreen.withValues(alpha: 0.12)
                    : AppTheme.surfaceCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? AppTheme.primaryGreen : AppTheme.border,
                  width: isSelected ? 1.8 : 1.0,
                ),
              ),
              child: Row(
                children: [
                  // Sample preview pieces: White Knight and Black King
                  Container(
                    width: 72,
                    height: 42,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Expanded(
                          child: ChessPieceWidget(
                            piece: PieceInfo(
                              type: PieceType.knight,
                              color: PlayerColor.white,
                            ),
                            style: style,
                          ),
                        ),
                        Expanded(
                          child: ChessPieceWidget(
                            piece: PieceInfo(
                              type: PieceType.king,
                              color: PlayerColor.black,
                            ),
                            style: style,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          style.name,
                          style: TextStyle(
                            color: isSelected
                                ? Colors.white
                                : AppTheme.textPrimary,
                            fontSize: 14,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          style.description,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    const Icon(
                      Icons.check_circle,
                      color: AppTheme.primaryGreen,
                      size: 22,
                    )
                  else
                    const Icon(
                      Icons.radio_button_unchecked,
                      color: AppTheme.textMuted,
                      size: 20,
                    ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // --- 4. TOGGLES CARD ---
  Widget _buildTogglesCard(BuildContext context, SettingsProvider settings) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text(
              'แอนิเมชันตอนเดินหมาก (Move Animation)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text(
              'แสดงเอฟเฟกต์การสลับตำแหน่งหมากอย่างนุ่มนวล',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
            value: settings.enableMoveAnimation,
            activeThumbColor: AppTheme.primaryGreen,
            onChanged: (val) => settings.setEnableMoveAnimation(val),
          ),
          const Divider(height: 1, color: AppTheme.border),
          SwitchListTile(
            title: const Text(
              'จุดแนะนำตาเดินถูกกฎ (Legal Move Hints)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text(
              'แสดงจุดโปร่งแสงบนช่องที่สามารถเดินหมากไปได้',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
            value: settings.showLegalMoveHints,
            activeThumbColor: AppTheme.primaryGreen,
            onChanged: (val) => settings.setShowLegalMoveHints(val),
          ),
          const Divider(height: 1, color: AppTheme.border),
          SwitchListTile(
            title: const Text(
              'พิกัดขอบกระดาน (Board Coordinates)',
              style: TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            subtitle: const Text(
              'แสดงตัวอักษร a-h และตัวเลข 1-8 ที่ริมขอบกระดาน',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 11),
            ),
            value: settings.showCoordinates,
            activeThumbColor: AppTheme.primaryGreen,
            onChanged: (val) => settings.setShowCoordinates(val),
          ),
        ],
      ),
    );
  }
}
