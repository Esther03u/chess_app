import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:chess_app/models/customization_options.dart';
import 'package:chess_app/providers/settings_provider.dart';
import 'package:chess_app/services/db_service.dart';

void main() {
  sqfliteFfiInit();

  group('SettingsProvider & Customization Options', () {
    late Database database;
    late DbService dbService;

    setUp(() async {
      final dbFactory = databaseFactoryFfi;
      database = await dbFactory.openDatabase(inMemoryDatabasePath);
      await database.execute('''
        CREATE TABLE ${DbService.tableName} (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          pgn TEXT NOT NULL,
          white TEXT,
          black TEXT,
          result TEXT,
          time_control TEXT,
          played_at INTEGER,
          analysis_json TEXT
        )
      ''');
      await database.execute('''
        CREATE TABLE IF NOT EXISTS ${DbService.settingsTableName} (
          key TEXT PRIMARY KEY,
          value TEXT NOT NULL
        )
      ''');
      dbService = DbService(database);
    });

    tearDown(() async {
      await dbService.close();
    });

    test('Initializes with default values', () async {
      final settings = SettingsProvider(dbService: dbService, autoInit: false);
      await settings.init();

      expect(settings.boardTheme, equals(BoardThemePreset.tournamentGreen));
      expect(settings.pieceStyle, equals(PieceStylePreset.staunton));
      expect(settings.enableMoveAnimation, isTrue);
      expect(settings.showLegalMoveHints, isTrue);
      expect(settings.showCoordinates, isTrue);
      expect(settings.isLoaded, isTrue);
    });

    test('Can change and persist board theme', () async {
      final settings = SettingsProvider(dbService: dbService, autoInit: false);
      await settings.init();

      await settings.setBoardTheme(BoardThemePreset.classicWood);
      expect(settings.boardTheme, equals(BoardThemePreset.classicWood));

      final stored = await dbService.getSetting('pref_board_theme');
      expect(stored, equals('classic_wood'));
    });

    test('Can change and persist piece style', () async {
      final settings = SettingsProvider(dbService: dbService, autoInit: false);
      await settings.init();

      await settings.setPieceStyle(PieceStylePreset.shaded);
      expect(settings.pieceStyle, equals(PieceStylePreset.shaded));

      final stored = await dbService.getSetting('pref_piece_style');
      expect(stored, equals('shaded'));
    });

    test('Can toggle move animation, legal hints, and coordinates', () async {
      final settings = SettingsProvider(dbService: dbService, autoInit: false);
      await settings.init();

      await settings.setEnableMoveAnimation(false);
      await settings.setShowLegalMoveHints(false);
      await settings.setShowCoordinates(false);

      expect(settings.enableMoveAnimation, isFalse);
      expect(settings.showLegalMoveHints, isFalse);
      expect(settings.showCoordinates, isFalse);

      final anim = await dbService.getSetting('pref_move_animation');
      final hints = await dbService.getSetting('pref_legal_hints');
      final coords = await dbService.getSetting('pref_coordinates');

      expect(anim, equals('false'));
      expect(hints, equals('false'));
      expect(coords, equals('false'));
    });

    test('ResetToDefaults restores all defaults', () async {
      final settings = SettingsProvider(dbService: dbService, autoInit: false);
      await settings.init();

      await settings.setBoardTheme(BoardThemePreset.royalAmethyst);
      await settings.setPieceStyle(PieceStylePreset.minimalist);
      await settings.setEnableMoveAnimation(false);

      await settings.resetToDefaults();

      expect(settings.boardTheme, equals(BoardThemePreset.tournamentGreen));
      expect(settings.pieceStyle, equals(PieceStylePreset.staunton));
      expect(settings.enableMoveAnimation, isTrue);
    });

    test(
      'BoardThemePreset and PieceStylePreset fromId fallback gracefully',
      () {
        expect(
          BoardThemePreset.fromId('unknown_theme'),
          equals(BoardThemePreset.tournamentGreen),
        );
        expect(
          PieceStylePreset.fromId('unknown_style'),
          equals(PieceStylePreset.staunton),
        );
      },
    );
  });
}
