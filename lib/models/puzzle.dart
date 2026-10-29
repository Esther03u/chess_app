/// Model representing a daily chess puzzle from Lichess API.
class DailyPuzzle {
  final String id;
  final int rating;
  final int plays;
  final List<String> solution;
  final List<String> themes;
  final String fen;
  final String lastMove;
  final int initialPly;
  final String gameId;
  final String gamePgn;
  final String? whitePlayerName;
  final int? whitePlayerRating;
  final String? blackPlayerName;
  final int? blackPlayerRating;

  const DailyPuzzle({
    required this.id,
    required this.rating,
    required this.plays,
    required this.solution,
    required this.themes,
    required this.fen,
    required this.lastMove,
    required this.initialPly,
    required this.gameId,
    required this.gamePgn,
    this.whitePlayerName,
    this.whitePlayerRating,
    this.blackPlayerName,
    this.blackPlayerRating,
  });

  /// Null-safe factory constructor to safely parse JSON from Lichess API.
  factory DailyPuzzle.fromJson(Map<String, dynamic> json) {
    final puzzleMap = json['puzzle'] as Map<String, dynamic>? ?? {};
    final gameMap = json['game'] as Map<String, dynamic>? ?? {};

    final playersList = (gameMap['players'] as List<dynamic>?) ?? [];
    String? whiteName;
    int? whiteRating;
    String? blackName;
    int? blackRating;

    for (final p in playersList) {
      if (p is Map<String, dynamic>) {
        final color = p['color']?.toString().toLowerCase();
        if (color == 'white') {
          whiteName = p['name']?.toString();
          whiteRating = p['rating'] is int
              ? p['rating'] as int
              : int.tryParse(p['rating']?.toString() ?? '');
        } else if (color == 'black') {
          blackName = p['name']?.toString();
          blackRating = p['rating'] is int
              ? p['rating'] as int
              : int.tryParse(p['rating']?.toString() ?? '');
        }
      }
    }

    final rawSolution = puzzleMap['solution'] as List<dynamic>? ?? [];
    final solution = rawSolution.map((s) => s.toString()).toList();

    final rawThemes = puzzleMap['themes'] as List<dynamic>? ?? [];
    final themes = rawThemes.map((t) => t.toString()).toList();

    return DailyPuzzle(
      id: puzzleMap['id']?.toString() ?? '',
      rating: puzzleMap['rating'] is int ? puzzleMap['rating'] as int : 0,
      plays: puzzleMap['plays'] is int ? puzzleMap['plays'] as int : 0,
      solution: solution,
      themes: themes,
      fen: puzzleMap['fen']?.toString() ?? '',
      lastMove: puzzleMap['lastMove']?.toString() ?? '',
      initialPly: puzzleMap['initialPly'] is int
          ? puzzleMap['initialPly'] as int
          : 0,
      gameId: gameMap['id']?.toString() ?? '',
      gamePgn: gameMap['pgn']?.toString() ?? '',
      whitePlayerName: whiteName,
      whitePlayerRating: whiteRating,
      blackPlayerName: blackName,
      blackPlayerRating: blackRating,
    );
  }

  Map<String, dynamic> toJson() => {
    'puzzle': {
      'id': id,
      'rating': rating,
      'plays': plays,
      'solution': solution,
      'themes': themes,
      'fen': fen,
      'lastMove': lastMove,
      'initialPly': initialPly,
    },
    'game': {
      'id': gameId,
      'pgn': gamePgn,
      'players': [
        if (whitePlayerName != null)
          {
            'name': whitePlayerName,
            'color': 'white',
            'rating': whitePlayerRating,
          },
        if (blackPlayerName != null)
          {
            'name': blackPlayerName,
            'color': 'black',
            'rating': blackPlayerRating,
          },
      ],
    },
  };
}
