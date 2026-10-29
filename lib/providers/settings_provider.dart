import 'package:flutter/material.dart';

import '../models/customization_options.dart';
import '../services/db_service.dart';

/// Manages user settings for board themes, piece styles, move animations,
/// and board coordinates, persisted via SQLite DbService.
class SettingsProvider extends ChangeNotifier {
  static const String _keyBoardTheme = 'pref_board_theme';
  static const String _keyPieceStyle = 'pref_piece_style';
  static const String _keyMoveAnimation = 'pref_move_animation';
  static const String _keyLegalMoveHints = 'pref_legal_hints';
  static const String _keyCoordinates = 'pref_coordinates';

  final DbService _dbService;

  BoardThemePreset _boardTheme = BoardThemePreset.tournamentGreen;
  PieceStylePreset _pieceStyle = PieceStylePreset.staunton;
  bool _enableMoveAnimation = true;
  bool _showLegalMoveHints = true;
  bool _showCoordinates = true;
  bool _isLoaded = false;
  Future<void>? _initFuture;

  BoardThemePreset get boardTheme => _boardTheme;
  PieceStylePreset get pieceStyle => _pieceStyle;
  bool get enableMoveAnimation => _enableMoveAnimation;
  bool get showLegalMoveHints => _showLegalMoveHints;
  bool get showCoordinates => _showCoordinates;
  bool get isLoaded => _isLoaded;

  SettingsProvider({DbService? dbService, bool autoInit = true})
    : _dbService = dbService ?? DbService() {
    if (autoInit) {
      init();
    }
  }

  Future<void> init() async {
    if (_initFuture != null) return _initFuture;
    _initFuture = _loadFromDb();
    return _initFuture;
  }

  Future<void> _loadFromDb() async {
    try {
      final themeId = await _dbService.getSetting(_keyBoardTheme);
      final styleId = await _dbService.getSetting(_keyPieceStyle);
      final animVal = await _dbService.getSetting(_keyMoveAnimation);
      final hintsVal = await _dbService.getSetting(_keyLegalMoveHints);
      final coordsVal = await _dbService.getSetting(_keyCoordinates);

      if (themeId != null) {
        _boardTheme = BoardThemePreset.fromId(themeId);
      }
      if (styleId != null) {
        _pieceStyle = PieceStylePreset.fromId(styleId);
      }
      if (animVal != null) {
        _enableMoveAnimation = animVal == 'true';
      }
      if (hintsVal != null) {
        _showLegalMoveHints = hintsVal == 'true';
      }
      if (coordsVal != null) {
        _showCoordinates = coordsVal == 'true';
      }
    } catch (_) {
      // In tests or environments without storage, keep defaults.
    } finally {
      _isLoaded = true;
      notifyListeners();
    }
  }

  Future<void> setBoardTheme(BoardThemePreset theme) async {
    if (_boardTheme == theme) return;
    _boardTheme = theme;
    notifyListeners();
    try {
      await _dbService.setSetting(_keyBoardTheme, theme.id);
    } catch (_) {}
  }

  Future<void> setPieceStyle(PieceStylePreset style) async {
    if (_pieceStyle == style) return;
    _pieceStyle = style;
    notifyListeners();
    try {
      await _dbService.setSetting(_keyPieceStyle, style.id);
    } catch (_) {}
  }

  Future<void> setEnableMoveAnimation(bool value) async {
    if (_enableMoveAnimation == value) return;
    _enableMoveAnimation = value;
    notifyListeners();
    try {
      await _dbService.setSetting(_keyMoveAnimation, value.toString());
    } catch (_) {}
  }

  Future<void> setShowLegalMoveHints(bool value) async {
    if (_showLegalMoveHints == value) return;
    _showLegalMoveHints = value;
    notifyListeners();
    try {
      await _dbService.setSetting(_keyLegalMoveHints, value.toString());
    } catch (_) {}
  }

  Future<void> setShowCoordinates(bool value) async {
    if (_showCoordinates == value) return;
    _showCoordinates = value;
    notifyListeners();
    try {
      await _dbService.setSetting(_keyCoordinates, value.toString());
    } catch (_) {}
  }

  Future<void> resetToDefaults() async {
    _boardTheme = BoardThemePreset.tournamentGreen;
    _pieceStyle = PieceStylePreset.staunton;
    _enableMoveAnimation = true;
    _showLegalMoveHints = true;
    _showCoordinates = true;
    notifyListeners();
    try {
      await _dbService.removeSetting(_keyBoardTheme);
      await _dbService.removeSetting(_keyPieceStyle);
      await _dbService.removeSetting(_keyMoveAnimation);
      await _dbService.removeSetting(_keyLegalMoveHints);
      await _dbService.removeSetting(_keyCoordinates);
    } catch (_) {}
  }
}
