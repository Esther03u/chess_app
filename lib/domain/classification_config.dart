/// Centralized configuration constants for chess post-game analysis and move classification.
/// Meets requirements of §3.9 in AGENTS.md.
class ClassificationConfig {
  /// Sigmoid multiplier used in Lichess/Chess.com standard win% formula:
  /// winPct(cp) = 50 + 50 * (2 / (1 + exp(-sigmoidMultiplier * cp)) - 1)
  static const double sigmoidMultiplier = 0.00368208;

  /// Accuracy curve parameters:
  /// moveAccuracy(loss) = (accuracyScale * exp(-accuracyDecay * loss) - accuracyOffset).clamp(0, 100)
  static const double accuracyScale = 103.1668;
  static const double accuracyDecay = 0.04354;
  static const double accuracyOffset = 3.1669;

  /// Win percentage loss thresholds for move classifications:
  /// - loss < bestThreshold (or isEngineTop) => Best
  /// - loss < goodThreshold => Good
  /// - loss < inaccuracyThreshold => Inaccuracy
  /// - loss < mistakeThreshold => Mistake
  /// - else => Blunder
  static const double bestThreshold = 2.0;
  static const double goodThreshold = 10.0;
  static const double inaccuracyThreshold = 20.0;
  static const double mistakeThreshold = 30.0;

  /// Centipawn score assigned to terminal checkmate position for side to move.
  static const int checkmateCentipawns = 10000;

  /// Score assigned to draw/stalemate.
  static const int drawCentipawns = 0;
}
