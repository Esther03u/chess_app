import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../domain/game_logic.dart';
import '../models/game_record.dart';
import '../services/db_service.dart';
import 'analysis_screen.dart';

/// Screen displaying the history of completed games loaded from SQLite (FR4).
class HistoryScreen extends StatefulWidget {
  final DbService? dbService;
  final bool isEmbeddedInHub;

  const HistoryScreen({
    super.key,
    this.dbService,
    this.isEmbeddedInHub = false,
  });

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late final DbService _dbService;
  List<GameRecord> _games = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _dbService = widget.dbService ?? DbService();
    _loadGames();
  }

  Future<void> _loadGames() async {
    setState(() => _isLoading = true);
    try {
      final games = await _dbService.listGames();
      if (mounted) {
        setState(() {
          _games = games;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _deleteGame(int id) async {
    await _dbService.deleteGame(id);
    _loadGames();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF262421),
      appBar: AppBar(
        automaticallyImplyLeading: !widget.isEmbeddedInHub,
        title: const Text(
          AppStrings.gameHistory,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรช',
            onPressed: _loadGames,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF769656)),
            )
          : _games.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history_toggle_off,
                    size: 64,
                    color: Colors.white24,
                  ),
                  SizedBox(height: 16),
                  Text(
                    AppStrings.noGamesYet,
                    style: TextStyle(color: Colors.white54, fontSize: 16),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(
                horizontal: 12.0,
                vertical: 8.0,
              ),
              itemCount: _games.length,
              itemBuilder: (context, index) {
                final game = _games[index];
                return _buildGameCard(game);
              },
            ),
    );
  }

  Widget _buildGameCard(GameRecord game) {
    final dateTimeStr = _formatDateTime(game.dateTime);
    final resultStr = game.result ?? '*';

    Color resultBg;
    if (resultStr == '1-0') {
      resultBg = Colors.white;
    } else if (resultStr == '0-1') {
      resultBg = Colors.grey.shade900;
    } else {
      resultBg = Colors.amber.shade800;
    }

    return Card(
      color: const Color(0xFF312E2B),
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      child: InkWell(
        borderRadius: BorderRadius.circular(8.0),
        onTap: () => _openReplay(game),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              // Result pill
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: resultBg,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.white24),
                ),
                child: Center(
                  child: Text(
                    resultStr,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: resultStr == '1-0' ? Colors.black : Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Player details and date
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${game.white ?? AppStrings.white} vs ${game.black ?? AppStrings.black}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          dateTimeStr,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                        if (game.timeControl != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFF262421),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              game.timeControl!,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),

              // Delete button
              IconButton(
                icon: const Icon(
                  Icons.delete_outline,
                  size: 20,
                  color: Colors.white38,
                ),
                tooltip: AppStrings.delete,
                onPressed: () => _confirmDelete(game.id),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openReplay(GameRecord record) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => GameReplayScreen(record: record)));
  }

  Future<void> _confirmDelete(int? id) async {
    if (id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF312E2B),
        title: const Text(
          AppStrings.delete,
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          AppStrings.confirmDelete,
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            child: const Text(
              AppStrings.cancel,
              style: TextStyle(color: Colors.white54),
            ),
            onPressed: () => Navigator.of(ctx).pop(false),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text(
              AppStrings.confirm,
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _deleteGame(id);
    }
  }

  String _formatDateTime(DateTime dt) {
    final year = dt.year;
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

/// Interactive game replay screen allowing move-by-move navigation through saved PGN (FR4).
class GameReplayScreen extends StatefulWidget {
  final GameRecord record;

  const GameReplayScreen({super.key, required this.record});

  @override
  State<GameReplayScreen> createState() => _GameReplayScreenState();
}

class _GameReplayScreenState extends State<GameReplayScreen> {
  late final GameLogic _fullGame;
  late final List<String> _sanMoves;
  int _currentPly = 0;
  late GameLogic _displayGame;

  @override
  void initState() {
    super.initState();
    _fullGame = GameLogic();
    _fullGame.loadPgn(widget.record.pgn);
    _sanMoves = _fullGame.history;
    _currentPly = _sanMoves.length;
    _displayGame = GameLogic();
    _rebuildToCurrentPly();
  }

  void _rebuildToCurrentPly() {
    _displayGame = GameLogic();
    for (int i = 0; i < _currentPly; i++) {
      final san = _sanMoves[i];
      // Replay move using SAN
      _displayGame.tryMoveSan(san);
    }
    setState(() {});
  }

  void _goToStart() {
    _currentPly = 0;
    _rebuildToCurrentPly();
  }

  void _stepBackward() {
    if (_currentPly > 0) {
      _currentPly--;
      _rebuildToCurrentPly();
    }
  }

  void _stepForward() {
    if (_currentPly < _sanMoves.length) {
      _currentPly++;
      _rebuildToCurrentPly();
    }
  }

  void _goToEnd() {
    _currentPly = _sanMoves.length;
    _rebuildToCurrentPly();
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;

    return Scaffold(
      backgroundColor: const Color(0xFF262421),
      appBar: AppBar(
        title: Text(
          '${record.white ?? AppStrings.white} vs ${record.black ?? AppStrings.black}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.insights),
            tooltip: AppStrings.gameAnalysis,
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => AnalysisScreen(record: widget.record),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Status bar
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 10.0,
              ),
              margin: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFF312E2B),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ตาเดิน: $_currentPly / ${_sanMoves.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade800,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      record.result ?? '*',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Chess Board (non-interactive replay view)
            Expanded(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(6.0),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: List.generate(8, (rankIndex) {
                          final rank = 8 - rankIndex;
                          return Expanded(
                            child: Row(
                              children: List.generate(8, (fileIndex) {
                                final fileChar = String.fromCharCode(
                                  'a'.codeUnitAt(0) + fileIndex,
                                );
                                final square = '$fileChar$rank';
                                final isLightSquare =
                                    (fileIndex + rankIndex) % 2 == 0;
                                final piece = _displayGame.getPiece(square);

                                return Expanded(
                                  child: Container(
                                    color: isLightSquare
                                        ? const Color(0xFFEEEED2)
                                        : const Color(0xFF769656),
                                    child: Center(
                                      child: piece != null
                                          ? Text(
                                              _pieceSymbol(piece),
                                              style: TextStyle(
                                                fontSize: 32,
                                                color:
                                                    piece.color ==
                                                        PlayerColor.white
                                                    ? Colors.white
                                                    : Colors.black,
                                                shadows: const [
                                                  Shadow(
                                                    color: Colors.black45,
                                                    blurRadius: 2,
                                                    offset: Offset(0, 1),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : null,
                                    ),
                                  ),
                                );
                              }),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Replay controls (⏮ ◀ ▶ ⏭)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.first_page, size: 28),
                    color: Colors.white,
                    tooltip: 'กลับไปตาแรก',
                    onPressed: _currentPly > 0 ? _goToStart : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_left, size: 28),
                    color: Colors.white,
                    tooltip: 'ย้อนหลัง 1 ตา',
                    onPressed: _currentPly > 0 ? _stepBackward : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, size: 28),
                    color: Colors.white,
                    tooltip: 'เดินหน้า 1 ตา',
                    onPressed: _currentPly < _sanMoves.length
                        ? _stepForward
                        : null,
                  ),
                  IconButton(
                    icon: const Icon(Icons.last_page, size: 28),
                    color: Colors.white,
                    tooltip: 'ไปตาสุดท้าย',
                    onPressed: _currentPly < _sanMoves.length ? _goToEnd : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _pieceSymbol(PieceInfo piece) {
    switch (piece.type) {
      case PieceType.pawn:
        return piece.color == PlayerColor.white ? '\u2659' : '\u265F';
      case PieceType.knight:
        return piece.color == PlayerColor.white ? '\u2658' : '\u265E';
      case PieceType.bishop:
        return piece.color == PlayerColor.white ? '\u2657' : '\u265D';
      case PieceType.rook:
        return piece.color == PlayerColor.white ? '\u2656' : '\u265C';
      case PieceType.queen:
        return piece.color == PlayerColor.white ? '\u2655' : '\u265B';
      case PieceType.king:
        return piece.color == PlayerColor.white ? '\u2654' : '\u265A';
    }
  }
}
