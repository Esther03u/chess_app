import 'dart:async';

import 'package:flutter/foundation.dart';

import '../domain/simple_bot.dart';

export '../domain/simple_bot.dart' show EngineEval, BotLevel;

/// Abstract interface for chess engines and bots as specified in §3.4.
abstract class EngineService {
  Future<void> init();
  Future<void> setLevel(int skill0to20);
  Future<String> bestMove(String fen, {int movetimeMs = 500});
  Future<EngineEval> evaluate(String fen, {int movetimeMs = 250});
  Future<void> dispose();
}

/// Pure Dart implementation of EngineService using SimpleBot (Minimax with Alpha-Beta).
/// Guaranteed to work on all platforms and devices without native C++ compilation or FFI dependencies.
class SimpleBotEngineService implements EngineService {
  final SimpleBot _bot;

  SimpleBotEngineService({BotLevel level = BotLevel.medium})
    : _bot = SimpleBot(level: level);

  @override
  Future<void> init() async {
    // Pure Dart bot is immediately ready
  }

  @override
  Future<void> setLevel(int skill0to20) async {
    if (skill0to20 <= 6) {
      _bot.setLevel(BotLevel.easy);
    } else if (skill0to20 <= 14) {
      _bot.setLevel(BotLevel.medium);
    } else {
      _bot.setLevel(BotLevel.hard);
    }
  }

  /// Sets level directly using BotLevel enum.
  void setBotLevel(BotLevel level) {
    _bot.setLevel(level);
  }

  BotLevel get currentLevel => _bot.level;

  @override
  Future<String> bestMove(String fen, {int movetimeMs = 500}) async {
    // Run search asynchronously to keep UI responsive (NFR1)
    return await compute(
      _computeBestMove,
      _ComputeParams(fen: fen, level: _bot.level, movetimeMs: movetimeMs),
    );
  }

  @override
  Future<EngineEval> evaluate(String fen, {int movetimeMs = 250}) async {
    return await _bot.evaluate(fen, movetimeMs: movetimeMs);
  }

  @override
  Future<void> dispose() async {
    // No native resources to release
  }

  static Future<String> _computeBestMove(_ComputeParams params) async {
    final workerBot = SimpleBot(level: params.level);
    return await workerBot.bestMove(params.fen, movetimeMs: params.movetimeMs);
  }
}

class _ComputeParams {
  final String fen;
  final BotLevel level;
  final int movetimeMs;

  const _ComputeParams({
    required this.fen,
    required this.level,
    required this.movetimeMs,
  });
}
