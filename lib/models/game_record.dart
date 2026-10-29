/// Data model for persisted chess games as specified in §3.5.
class GameRecord {
  final int? id;
  final String pgn;
  final String? white;
  final String? black;
  final String? result; // '1-0' | '0-1' | '1/2-1/2' | '*'
  final String? timeControl;
  final int playedAt; // epoch ms
  final String? analysisJson;

  const GameRecord({
    this.id,
    required this.pgn,
    this.white,
    this.black,
    this.result,
    this.timeControl,
    required this.playedAt,
    this.analysisJson,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'pgn': pgn,
      'white': white,
      'black': black,
      'result': result,
      'time_control': timeControl,
      'played_at': playedAt,
      'analysis_json': analysisJson,
    };
  }

  factory GameRecord.fromMap(Map<String, dynamic> map) {
    return GameRecord(
      id: map['id'] as int?,
      pgn: map['pgn'] as String? ?? '',
      white: map['white'] as String?,
      black: map['black'] as String?,
      result: map['result'] as String?,
      timeControl: map['time_control'] as String?,
      playedAt: map['played_at'] as int? ?? 0,
      analysisJson: map['analysis_json'] as String?,
    );
  }

  GameRecord copyWith({
    int? id,
    String? pgn,
    String? white,
    String? black,
    String? result,
    String? timeControl,
    int? playedAt,
    String? analysisJson,
  }) {
    return GameRecord(
      id: id ?? this.id,
      pgn: pgn ?? this.pgn,
      white: white ?? this.white,
      black: black ?? this.black,
      result: result ?? this.result,
      timeControl: timeControl ?? this.timeControl,
      playedAt: playedAt ?? this.playedAt,
      analysisJson: analysisJson ?? this.analysisJson,
    );
  }

  DateTime get dateTime => DateTime.fromMillisecondsSinceEpoch(playedAt);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GameRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          pgn == other.pgn &&
          white == other.white &&
          black == other.black &&
          result == other.result &&
          timeControl == other.timeControl &&
          playedAt == other.playedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      pgn.hashCode ^
      white.hashCode ^
      black.hashCode ^
      result.hashCode ^
      timeControl.hashCode ^
      playedAt.hashCode;
}
