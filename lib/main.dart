import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'core/strings.dart';
import 'core/theme.dart';
import 'providers/clock_controller.dart';
import 'providers/game_controller.dart';
import 'providers/settings_provider.dart';
import 'screens/main_hub_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  if (!kIsWeb && (Platform.isWindows || Platform.isLinux)) {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  }
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsProvider()),
        ChangeNotifierProvider(create: (_) => ClockController()),
        ChangeNotifierProxyProvider<ClockController, GameController>(
          create: (ctx) =>
              GameController(clockController: ctx.read<ClockController>()),
          update: (_, clock, game) {
            if (game != null) {
              game.attachClock(clock);
              return game;
            }
            return GameController(clockController: clock);
          },
        ),
      ],
      child: MaterialApp(
        title: AppStrings.appTitle,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const MainHubScreen(),
      ),
    );
  }
}
