import 'dart:async';

import 'package:flutter/foundation.dart';

import '../core/strings.dart';
import '../domain/game_logic.dart';

/// Predefined or custom time control.
class TimeControl {
  final String label;
  final int initialMinutes;
  final int incrementSeconds;

  const TimeControl({
    required this.label,
    required this.initialMinutes,
    this.incrementSeconds = 0,
  });

  static const unlimited = TimeControl(
    label: AppStrings.unlimited,
    initialMinutes: 0,
    incrementSeconds: 0,
  );

  static const blitz3p2 = TimeControl(
    label: AppStrings.blitz3p2,
    initialMinutes: 3,
    incrementSeconds: 2,
  );

  static const blitz5p0 = TimeControl(
    label: AppStrings.blitz5p0,
    initialMinutes: 5,
    incrementSeconds: 0,
  );

  static const rapid10p0 = TimeControl(
    label: AppStrings.rapid10p0,
    initialMinutes: 10,
    incrementSeconds: 0,
  );

  static const rapid15p10 = TimeControl(
    label: AppStrings.rapid15p10,
    initialMinutes: 15,
    incrementSeconds: 10,
  );

  bool get isUnlimited => initialMinutes <= 0;
  Duration get initialDuration => Duration(minutes: initialMinutes);
  Duration get incrementDuration => Duration(seconds: incrementSeconds);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeControl &&
          runtimeType == other.runtimeType &&
          initialMinutes == other.initialMinutes &&
          incrementSeconds == other.incrementSeconds;

  @override
  int get hashCode => initialMinutes.hashCode ^ incrementSeconds.hashCode;
}

/// Abstract ticker to allow injection of fake ticker in tests.
abstract class ClockTicker {
  void start(void Function(Duration elapsed) onTick);
  void stop();
  bool get isActive;
}

/// Real-time system ticker with drift-free DateTime delta tracking.
class SystemClockTicker implements ClockTicker {
  Timer? _timer;
  DateTime? _lastTickTime;
  void Function(Duration elapsed)? _callback;

  @override
  bool get isActive => _timer != null && _timer!.isActive;

  @override
  void start(void Function(Duration elapsed) onTick) {
    stop();
    _callback = onTick;
    _lastTickTime = DateTime.now();
    _timer = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final now = DateTime.now();
      if (_lastTickTime != null && _callback != null) {
        final elapsed = now.difference(_lastTickTime!);
        _lastTickTime = now;
        _callback!(elapsed);
      }
    });
  }

  @override
  void stop() {
    _timer?.cancel();
    _timer = null;
    _lastTickTime = null;
    _callback = null;
  }
}

/// Fake ticker for deterministic unit tests.
class FakeClockTicker implements ClockTicker {
  void Function(Duration elapsed)? _callback;
  bool _active = false;

  @override
  bool get isActive => _active;

  @override
  void start(void Function(Duration elapsed) onTick) {
    _callback = onTick;
    _active = true;
  }

  @override
  void stop() {
    _active = false;
    _callback = null;
  }

  /// Manually advance simulated time by [delta].
  void advance(Duration delta) {
    if (_active && _callback != null) {
      _callback!(delta);
    }
  }
}

/// Controller managing White and Black chess clocks, increments, and flag detection (FR3).
class ClockController extends ChangeNotifier {
  final ClockTicker _ticker;
  TimeControl _timeControl;

  Duration _whiteTime;
  Duration _blackTime;
  PlayerColor? _activeSide;
  bool _isRunning = false;
  bool _isFlagged = false;
  PlayerColor? _flaggedSide;

  void Function(PlayerColor timedOutColor)? onTimeout;

  ClockController({
    TimeControl timeControl = TimeControl.rapid10p0,
    ClockTicker? ticker,
    this.onTimeout,
  }) : _timeControl = timeControl,
       _ticker = ticker ?? SystemClockTicker(),
       _whiteTime = timeControl.initialDuration,
       _blackTime = timeControl.initialDuration;

  TimeControl get timeControl => _timeControl;
  Duration get whiteTime => _whiteTime;
  Duration get blackTime => _blackTime;
  PlayerColor? get activeSide => _activeSide;
  bool get isRunning => _isRunning;
  bool get isFlagged => _isFlagged;
  PlayerColor? get flaggedSide => _flaggedSide;
  bool get isUnlimited => _timeControl.isUnlimited;

  Duration remainingTime(PlayerColor color) =>
      color == PlayerColor.white ? _whiteTime : _blackTime;

  /// Starts the clock for [side].
  void start(PlayerColor side) {
    if (_timeControl.isUnlimited || _isFlagged) return;

    _activeSide = side;
    _isRunning = true;
    _ticker.start(_handleTick);
    notifyListeners();
  }

  /// Handles turn change: adds increment to previous player, switches to [nextSide].
  void switchTurn(PlayerColor nextSide) {
    if (_timeControl.isUnlimited || _isFlagged) return;

    if (_isRunning && _activeSide != null) {
      // Add increment to the player who just finished their move (FR3)
      final inc = _timeControl.incrementDuration;
      if (_activeSide == PlayerColor.white) {
        _whiteTime += inc;
      } else {
        _blackTime += inc;
      }
    }

    _activeSide = nextSide;
    _isRunning = true;

    if (!_ticker.isActive) {
      _ticker.start(_handleTick);
    }
    notifyListeners();
  }

  /// Pauses the clock (e.g. when game ends or is paused).
  void pause() {
    if (!_isRunning) return;
    _isRunning = false;
    _ticker.stop();
    notifyListeners();
  }

  /// Resumes the clock if an active side exists.
  void resume() {
    if (_timeControl.isUnlimited ||
        _isFlagged ||
        _isRunning ||
        _activeSide == null) {
      return;
    }
    _isRunning = true;
    _ticker.start(_handleTick);
    notifyListeners();
  }

  /// Resets clock with optional new [timeControl].
  void reset({TimeControl? timeControl}) {
    _ticker.stop();
    if (timeControl != null) {
      _timeControl = timeControl;
    }
    _whiteTime = _timeControl.initialDuration;
    _blackTime = _timeControl.initialDuration;
    _activeSide = null;
    _isRunning = false;
    _isFlagged = false;
    _flaggedSide = null;
    notifyListeners();
  }

  void _handleTick(Duration elapsed) {
    if (!_isRunning ||
        _isFlagged ||
        _timeControl.isUnlimited ||
        _activeSide == null) {
      return;
    }

    if (_activeSide == PlayerColor.white) {
      final newTime = _whiteTime - elapsed;
      if (newTime <= Duration.zero) {
        _whiteTime = Duration.zero;
        _triggerFlag(PlayerColor.white);
      } else {
        _whiteTime = newTime;
        notifyListeners();
      }
    } else {
      final newTime = _blackTime - elapsed;
      if (newTime <= Duration.zero) {
        _blackTime = Duration.zero;
        _triggerFlag(PlayerColor.black);
      } else {
        _blackTime = newTime;
        notifyListeners();
      }
    }
  }

  void _triggerFlag(PlayerColor timedOutSide) {
    _isFlagged = true;
    _flaggedSide = timedOutSide;
    _isRunning = false;
    _ticker.stop();
    notifyListeners();

    onTimeout?.call(timedOutSide);
  }

  /// Formats remaining time for display (e.g. "05:24" or "0:04.2" under 10s).
  String formatTime(PlayerColor color) {
    if (_timeControl.isUnlimited) return '∞';

    final duration = remainingTime(color);
    if (duration <= Duration.zero) return '00:00';

    final totalSeconds = duration.inSeconds;
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;

    if (minutes == 0 && totalSeconds < 10) {
      final tenths = (duration.inMilliseconds % 1000) ~/ 100;
      return '$minutes:${seconds.toString().padLeft(2, '0')}.$tenths';
    }

    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _ticker.stop();
    super.dispose();
  }
}
