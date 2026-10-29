import 'package:flutter/material.dart';

/// Preset board color themes.
class BoardThemePreset {
  final String id;
  final String name;
  final Color lightSquare;
  final Color darkSquare;
  final Color selectedSquare;
  final Color lastMoveSquare;
  final Color inCheckSquare;

  const BoardThemePreset({
    required this.id,
    required this.name,
    required this.lightSquare,
    required this.darkSquare,
    required this.selectedSquare,
    required this.lastMoveSquare,
    this.inCheckSquare = const Color(0xFFEB6161),
  });

  static const tournamentGreen = BoardThemePreset(
    id: 'tournament_green',
    name: 'เขียวทัวร์นาเมนต์ (Tournament Green)',
    lightSquare: Color(0xFFEEEED2),
    darkSquare: Color(0xFF769656),
    selectedSquare: Color(0xFFBBCB43),
    lastMoveSquare: Color(0xFFAAB838),
  );

  static const classicWood = BoardThemePreset(
    id: 'classic_wood',
    name: 'ลายไม้คลาสสิก (Classic Wood)',
    lightSquare: Color(0xFFE3C9A8),
    darkSquare: Color(0xFF9E6B47),
    selectedSquare: Color(0xFFD4A76A),
    lastMoveSquare: Color(0xFFC79854),
  );

  static const darkSlate = BoardThemePreset(
    id: 'dark_slate',
    name: 'หินชนวนมืด (Dark Slate)',
    lightSquare: Color(0xFF9E9E9E),
    darkSquare: Color(0xFF484848),
    selectedSquare: Color(0xFF6F7C82),
    lastMoveSquare: Color(0xFF5A666C),
  );

  static const oceanicBlue = BoardThemePreset(
    id: 'oceanic_blue',
    name: 'น้ำเงินมหาสมุทร (Oceanic Blue)',
    lightSquare: Color(0xFFDCE5ED),
    darkSquare: Color(0xFF50789E),
    selectedSquare: Color(0xFF78A6CC),
    lastMoveSquare: Color(0xFF6492B8),
  );

  static const royalAmethyst = BoardThemePreset(
    id: 'royal_amethyst',
    name: 'ม่วงรอยัล (Royal Amethyst)',
    lightSquare: Color(0xFFE9E0ED),
    darkSquare: Color(0xFF835A8C),
    selectedSquare: Color(0xFFA573B0),
    lastMoveSquare: Color(0xFF9461A0),
  );

  static const List<BoardThemePreset> allPresets = [
    tournamentGreen,
    classicWood,
    darkSlate,
    oceanicBlue,
    royalAmethyst,
  ];

  static BoardThemePreset fromId(String? id) {
    return allPresets.firstWhere(
      (preset) => preset.id == id,
      orElse: () => tournamentGreen,
    );
  }
}

/// Piece rendering style presets.
enum PieceStylePreset {
  staunton(
    id: 'staunton',
    name: 'สากลชัดเจน (Staunton Standard)',
    description: 'รูปทรงมาตรฐานสากล คมชัด แยกตัวหมากง่ายที่สุด',
  ),
  shaded(
    id: 'shaded',
    name: 'มิติเงาสวยหรู (Tournament Shaded)',
    description: 'เวกเตอร์เงา มิติแสงกราเดียนต์ และเส้นขอบคมชัด',
  ),
  minimalist(
    id: 'minimalist',
    name: 'มินิมอลโมเดิร์น (Modern Flat)',
    description: 'กราฟิกแบนเรียบ ทันสมัย สบายตา',
  ),
  retroUnicode(
    id: 'unicode',
    name: 'คลาสสิกดั้งเดิม (Retro Unicode)',
    description: 'สัญลักษณ์ตัวหนังสือหมากรุกดั้งเดิม',
  );

  final String id;
  final String name;
  final String description;

  const PieceStylePreset({
    required this.id,
    required this.name,
    required this.description,
  });

  static PieceStylePreset fromId(String? id) {
    return PieceStylePreset.values.firstWhere(
      (style) => style.id == id,
      orElse: () => PieceStylePreset.staunton,
    );
  }
}
