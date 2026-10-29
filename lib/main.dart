import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/strings.dart';
import 'providers/clock_controller.dart';
import 'providers/game_controller.dart';
import 'screens/game_screen.dart';

void main() {
  runApp(const ChessApp());
}

class ChessApp extends StatelessWidget {
  const ChessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
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
        theme: ThemeData(
          brightness: Brightness.dark,
          primaryColor: const Color(0xFF769656),
          scaffoldBackgroundColor: const Color(0xFF262421),
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF769656),
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        home: const GameScreen(),
      ),
    );
  }
}
