import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/strings.dart';
import '../domain/classification.dart';
import '../domain/game_logic.dart';
import '../models/analysis_result.dart';
import '../models/game_record.dart';
import '../services/analysis_service.dart';
import '../services/db_service.dart';
import '../widgets/board_view.dart';
import '../widgets/eval_graph.dart';

/// Screen presenting full post-game analysis (FR6 / Should).
/// Includes eval advantage curve, per-move classification markers,
/// player accuracy scores, and interactive ply navigation.
class AnalysisScreen extends StatefulWidget {
  final GameRecord record;
  final AnalysisService? analysisService;
  final DbService? dbService;

  const AnalysisScreen({
    super.key,
    required this.record,
    this.analysisService,
    this.dbService,
  });

  @override
  State<AnalysisScreen> createState() => _AnalysisScreenState();
}

class _AnalysisScreenState extends State<AnalysisScreen> {
  late final AnalysisService _analysisService;

  bool _isLoading = true;
  double _progress = 0.0;
  GameAnalysis? _analysis;
  int _selectedPly = 0;
  late GameLogic _displayGame;

  @override
  void initState() {
    super.initState();
    _analysisService =
        widget.analysisService ?? AnalysisService(dbService: widget.dbService);
    _displayGame = GameLogic();
    _initAnalysis();
  }

  Future<void> _initAnalysis() async {
    // 1. If cached analysis JSON exists in record, load it immediately
    if (widget.record.analysisJson != null &&
        widget.record.analysisJson!.isNotEmpty) {
      try {
        final json =
            jsonDecode(widget.record.analysisJson!) as Map<String, dynamic>;
        final cached = GameAnalysis.fromJson(json);
        if (cached.moves.isNotEmpty) {
          _applyAnalysis(cached);
          return;
        }
      } catch (_) {
        // Fallback to recalculating
      }
    }

    // 2. Otherwise run analysis engine
    setState(() {
      _isLoading = true;
      _progress = 0.0;
    });

    final result = await _analysisService.analyzeGame(
      pgn: widget.record.pgn,
      gameId: widget.record.id,
      onProgress: (p) {
        if (mounted) {
          setState(() {
            _progress = p;
          });
        }
      },
    );

    if (mounted) {
      _applyAnalysis(result);
    }
  }

  void _applyAnalysis(GameAnalysis analysis) {
    setState(() {
      _analysis = analysis;
      _isLoading = false;
      _selectedPly = analysis.moves.isNotEmpty ? analysis.moves.length - 1 : 0;
    });
    _updateBoardToSelectedPly();
  }

  void _updateBoardToSelectedPly() {
    if (_analysis == null || _analysis!.moves.isEmpty) return;
    final move = _analysis!.moves[_selectedPly];
    _displayGame.loadFen(move.fen);
    setState(() {});
  }

  void _onSelectPly(int ply) {
    if (_analysis == null || _analysis!.moves.isEmpty) return;
    setState(() {
      _selectedPly = ply.clamp(0, _analysis!.moves.length - 1);
    });
    _updateBoardToSelectedPly();
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;

    return Scaffold(
      backgroundColor: const Color(0xFF262421),
      appBar: AppBar(
        title: const Text(
          AppStrings.gameAnalysis,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: _isLoading
            ? _buildLoadingView()
            : _analysis == null || _analysis!.moves.isEmpty
            ? const Center(
                child: Text(
                  'ไม่มีข้อมูลตาเดินสำหรับวิเคราะห์',
                  style: TextStyle(color: Colors.white70),
                ),
              )
            : _buildAnalysisContent(record),
      ),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFF769656)),
            const SizedBox(height: 20),
            Text(
              AppStrings.analyzingGame,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${(_progress * 100).toInt()}%',
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: _progress,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF769656),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalysisContent(GameRecord record) {
    final analysis = _analysis!;
    final currentMove = analysis.moves[_selectedPly];

    return SingleChildScrollView(
      child: Column(
        children: [
          // 1. Accuracy Summary Header
          _buildAccuracyHeader(record, analysis),

          // 2. Interactive Eval Graph
          EvalGraph(
            moves: analysis.moves,
            selectedPly: _selectedPly,
            onPlySelected: _onSelectPly,
          ),

          // 3. Move Classification Detail Banner
          _buildMoveDetailBanner(currentMove),

          // 4. Chess Board Preview
          _buildBoardPreview(currentMove),

          // 5. Ply Navigation Controls
          _buildNavigationControls(analysis),

          // 6. Classification Breakdown Table
          _buildSummaryBreakdown(analysis),
        ],
      ),
    );
  }

  Widget _buildAccuracyHeader(GameRecord record, GameAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      margin: const EdgeInsets.fromLTRB(12.0, 8.0, 12.0, 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF312E2B),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // White Player Accuracy
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        record.white ?? AppStrings.white,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${analysis.whiteAccuracy.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF81C784),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),

          // Result Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.amber.shade800,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              record.result ?? '*',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
                fontSize: 13,
              ),
            ),
          ),

          // Black Player Accuracy
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Text(
                        record.black ?? AppStrings.black,
                        textAlign: TextAlign.end,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${analysis.blackAccuracy.toStringAsFixed(1)}%',
                  style: const TextStyle(
                    color: Color(0xFF81C784),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMoveDetailBanner(AnalyzedMove move) {
    Color classColor;
    switch (move.classification) {
      case MoveClassification.best:
        classColor = const Color(0xFF629924);
        break;
      case MoveClassification.good:
        classColor = const Color(0xFF8BC34A);
        break;
      case MoveClassification.inaccuracy:
        classColor = const Color(0xFFFFB300);
        break;
      case MoveClassification.mistake:
        classColor = const Color(0xFFFF9800);
        break;
      case MoveClassification.blunder:
        classColor = const Color(0xFFE53935);
        break;
    }

    final prefix = move.isWhite
        ? '${move.moveNumber}.'
        : '${move.moveNumber}...';
    final evalStr = move.evalWhiteCp >= 0
        ? '+${(move.evalWhiteCp / 100.0).toStringAsFixed(2)}'
        : (move.evalWhiteCp / 100.0).toStringAsFixed(2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      margin: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 4.0),
      decoration: BoxDecoration(
        color: const Color(0xFF312E2B),
        borderRadius: BorderRadius.circular(6.0),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '$prefix ${move.san}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: classColor,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '${move.classification.labelThai} ${move.classification.symbol}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Eval: $evalStr',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          if (move.bestMove != null &&
              move.classification != MoveClassification.best) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Text(
                  AppStrings.bestMoveSuggestion,
                  style: TextStyle(color: Colors.white54, fontSize: 12),
                ),
                Text(
                  move.bestMove!,
                  style: const TextStyle(
                    color: Colors.amberAccent,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBoardPreview(AnalyzedMove move) {
    final fromSq = move.uci.length >= 2 ? move.uci.substring(0, 2) : '';
    final toSq = move.uci.length >= 4 ? move.uci.substring(2, 4) : '';

    return Container(
      width: 280,
      height: 280,
      margin: const EdgeInsets.symmetric(vertical: 6.0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
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
                final isLightSquare = (fileIndex + rankIndex) % 2 == 0;
                final piece = _displayGame.getPiece(square);

                Color squareBg = isLightSquare
                    ? BoardView.lightSquareColor
                    : BoardView.darkSquareColor;

                if (square == fromSq || square == toSq) {
                  squareBg = BoardView.lastMoveColor.withValues(alpha: 0.85);
                }

                return Expanded(
                  child: Container(
                    color: squareBg,
                    child: Center(
                      child: piece != null
                          ? ChessPieceWidget(piece: piece)
                          : null,
                    ),
                  ),
                );
              }),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildNavigationControls(GameAnalysis analysis) {
    final total = analysis.moves.length;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.first_page, color: Colors.white),
            onPressed: _selectedPly > 0 ? () => _onSelectPly(0) : null,
          ),
          IconButton(
            icon: const Icon(Icons.chevron_left, color: Colors.white),
            onPressed: _selectedPly > 0
                ? () => _onSelectPly(_selectedPly - 1)
                : null,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(
              '${_selectedPly + 1} / $total',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, color: Colors.white),
            onPressed: _selectedPly < total - 1
                ? () => _onSelectPly(_selectedPly + 1)
                : null,
          ),
          IconButton(
            icon: const Icon(Icons.last_page, color: Colors.white),
            onPressed: _selectedPly < total - 1
                ? () => _onSelectPly(total - 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBreakdown(GameAnalysis analysis) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
      margin: const EdgeInsets.fromLTRB(12.0, 4.0, 12.0, 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFF312E2B),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'สถิติตาเดิน (Move Breakdown)',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.0),
              2: FlexColumnWidth(1.0),
            },
            children: [
              const TableRow(
                children: [
                  Text('', style: TextStyle(color: Colors.white38)),
                  Text(
                    AppStrings.white,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    AppStrings.black,
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
              for (final c in MoveClassification.values)
                TableRow(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        '${c.symbol} ${c.labelThai}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    Text(
                      '${analysis.whiteSummary[c] ?? 0}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                    Text(
                      '${analysis.blackSummary[c] ?? 0}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }
}
