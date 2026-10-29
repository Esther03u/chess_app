import 'dart:math';

import 'classification_config.dart';

/// Classifications for chess moves based on win percentage loss.
enum MoveClassification {
  best,
  good,
  inaccuracy,
  mistake,
  blunder;

  String get labelThai {
    switch (this) {
      case MoveClassification.best:
        return 'ตาเดินดีที่สุด';
      case MoveClassification.good:
        return 'ตาเดินที่ดี';
      case MoveClassification.inaccuracy:
        return 'คลาดเคลื่อน (Inaccuracy)';
      case MoveClassification.mistake:
        return 'ข้อผิดพลาด (Mistake)';
      case MoveClassification.blunder:
        return 'ผิดพลาดมหันต์ (Blunder)';
    }
  }

  String get symbol {
    switch (this) {
      case MoveClassification.best:
        return '★';
      case MoveClassification.good:
        return '✓';
      case MoveClassification.inaccuracy:
        return '?!';
      case MoveClassification.mistake:
        return '?';
      case MoveClassification.blunder:
        return '??';
    }
  }
}

/// Pure Dart mathematical functions for move classification and accuracy calculation.
/// Implements §3.9 of AGENTS.md.
class MoveClassifier {
  /// Converts centipawn score to winning percentage (0% to 100%) from the side-to-move perspective.
  /// winPct(cp) = 50 + 50 * (2 / (1 + exp(-0.00368208 * cp)) - 1)
  static double winPct(int cp) {
    final expVal = exp(-ClassificationConfig.sigmoidMultiplier * cp);
    return 50.0 + 50.0 * (2.0 / (1.0 + expVal) - 1.0);
  }

  /// Calculates win percentage loss between evaluation before and after move.
  /// winLoss(cpBefore, cpAfter) = max(0, winPct(cpBefore) - winPct(cpAfter))
  static double winLoss(int cpBefore, int cpAfter) {
    final beforePct = winPct(cpBefore);
    final afterPct = winPct(cpAfter);
    return max(0.0, beforePct - afterPct);
  }

  /// Classifies a move based on win% loss and whether it matches engine best move.
  static MoveClassification classify(double loss, {required bool isEngineTop}) {
    if (isEngineTop || loss < ClassificationConfig.bestThreshold) {
      return MoveClassification.best;
    }
    if (loss < ClassificationConfig.goodThreshold) {
      return MoveClassification.good;
    }
    if (loss < ClassificationConfig.inaccuracyThreshold) {
      return MoveClassification.inaccuracy;
    }
    if (loss < ClassificationConfig.mistakeThreshold) {
      return MoveClassification.mistake;
    }
    return MoveClassification.blunder;
  }

  /// Calculates accuracy score (0% to 100%) for a single move given win% loss.
  /// moveAccuracy(loss) = (103.1668 * exp(-0.04354 * loss) - 3.1669).clamp(0, 100)
  static double moveAccuracy(double loss) {
    final raw =
        ClassificationConfig.accuracyScale *
            exp(-ClassificationConfig.accuracyDecay * loss) -
        ClassificationConfig.accuracyOffset;
    return raw.clamp(0.0, 100.0).toDouble();
  }

  /// Converts engine mate score to centipawns:
  /// score mate N with N > 0 => cp = 10000 - N
  /// score mate N with N < 0 => cp = -10000 - N
  static int mateToCentipawns(int mateInMoves) {
    if (mateInMoves > 0) {
      return ClassificationConfig.checkmateCentipawns - mateInMoves;
    } else if (mateInMoves < 0) {
      return -ClassificationConfig.checkmateCentipawns - mateInMoves;
    }
    return 0;
  }

  /// Computes arithmetic mean of accuracy list.
  static double averageAccuracy(List<double> accuracies) {
    if (accuracies.isEmpty) return 100.0;
    final total = accuracies.reduce((a, b) => a + b);
    return total / accuracies.length;
  }
}
