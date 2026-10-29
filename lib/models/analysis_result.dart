import '../domain/classification.dart';

/// Represents the post-game analysis data for a single played move.
class AnalyzedMove {
  final int ply;
  final int moveNumber;
  final bool isWhite;
  final String san;
  final String uci;
  final String fen;

  /// Evaluation in centipawns normalized to White's perspective (positive = White advantage).
  final int evalWhiteCp;

  /// Evaluation from the mover's perspective before the move was played.
  final int evalBefore;

  /// Evaluation from the mover's perspective after the move was played.
  final int evalAfter;

  /// Percentage loss in win probability (>= 0).
  final double winLoss;

  /// Accuracy percentage of this move (0.0 to 100.0).
  final double accuracy;

  /// Move classification (Best, Good, Inaccuracy, Mistake, Blunder).
  final MoveClassification classification;

  /// Best move suggested by the engine at this position (UCI format).
  final String? bestMove;

  const AnalyzedMove({
    required this.ply,
    required this.moveNumber,
    required this.isWhite,
    required this.san,
    required this.uci,
    required this.fen,
    required this.evalWhiteCp,
    required this.evalBefore,
    required this.evalAfter,
    required this.winLoss,
    required this.accuracy,
    required this.classification,
    this.bestMove,
  });

  Map<String, dynamic> toJson() => {
    'ply': ply,
    'moveNumber': moveNumber,
    'isWhite': isWhite,
    'san': san,
    'uci': uci,
    'fen': fen,
    'evalWhiteCp': evalWhiteCp,
    'evalBefore': evalBefore,
    'evalAfter': evalAfter,
    'winLoss': winLoss,
    'accuracy': accuracy,
    'classification': classification.name,
    'bestMove': bestMove,
  };

  factory AnalyzedMove.fromJson(Map<String, dynamic> json) {
    return AnalyzedMove(
      ply: json['ply'] as int? ?? 0,
      moveNumber: json['moveNumber'] as int? ?? 1,
      isWhite: json['isWhite'] as bool? ?? true,
      san: json['san']?.toString() ?? '',
      uci: json['uci']?.toString() ?? '',
      fen: json['fen']?.toString() ?? '',
      evalWhiteCp: json['evalWhiteCp'] as int? ?? 0,
      evalBefore: json['evalBefore'] as int? ?? 0,
      evalAfter: json['evalAfter'] as int? ?? 0,
      winLoss: (json['winLoss'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 100.0,
      classification: MoveClassification.values.firstWhere(
        (c) => c.name == json['classification'],
        orElse: () => MoveClassification.good,
      ),
      bestMove: json['bestMove']?.toString(),
    );
  }
}

/// Represents the complete post-game analysis for a game.
class GameAnalysis {
  final List<AnalyzedMove> moves;
  final double whiteAccuracy;
  final double blackAccuracy;
  final Map<MoveClassification, int> whiteSummary;
  final Map<MoveClassification, int> blackSummary;

  const GameAnalysis({
    required this.moves,
    required this.whiteAccuracy,
    required this.blackAccuracy,
    required this.whiteSummary,
    required this.blackSummary,
  });

  Map<String, dynamic> toJson() => {
    'moves': moves.map((m) => m.toJson()).toList(),
    'whiteAccuracy': whiteAccuracy,
    'blackAccuracy': blackAccuracy,
    'whiteSummary': whiteSummary.map((k, v) => MapEntry(k.name, v)),
    'blackSummary': blackSummary.map((k, v) => MapEntry(k.name, v)),
  };

  factory GameAnalysis.fromJson(Map<String, dynamic> json) {
    final rawMoves = json['moves'] as List<dynamic>? ?? [];
    final moves = rawMoves
        .whereType<Map<String, dynamic>>()
        .map((m) => AnalyzedMove.fromJson(m))
        .toList();

    Map<MoveClassification, int> parseSummary(dynamic raw) {
      final res = <MoveClassification, int>{
        for (final c in MoveClassification.values) c: 0,
      };
      if (raw is Map<String, dynamic>) {
        for (final c in MoveClassification.values) {
          if (raw.containsKey(c.name) && raw[c.name] is int) {
            res[c] = raw[c.name] as int;
          }
        }
      }
      return res;
    }

    return GameAnalysis(
      moves: moves,
      whiteAccuracy: (json['whiteAccuracy'] as num?)?.toDouble() ?? 0.0,
      blackAccuracy: (json['blackAccuracy'] as num?)?.toDouble() ?? 0.0,
      whiteSummary: parseSummary(json['whiteSummary']),
      blackSummary: parseSummary(json['blackSummary']),
    );
  }
}
