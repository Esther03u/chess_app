import 'package:flutter/material.dart';

import '../domain/classification.dart';
import '../models/analysis_result.dart';

/// Interactive evaluation graph rendering the match advantage curve across plies.
/// Shows advantage level (White above center, Black below center) and marks blunders/mistakes.
class EvalGraph extends StatelessWidget {
  final List<AnalyzedMove> moves;
  final int selectedPly;
  final ValueChanged<int> onPlySelected;

  const EvalGraph({
    super.key,
    required this.moves,
    required this.selectedPly,
    required this.onPlySelected,
  });

  @override
  Widget build(BuildContext context) {
    if (moves.isEmpty) {
      return const SizedBox(height: 100);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        const height = 90.0;

        return GestureDetector(
          onTapDown: (details) => _handleTouch(details.localPosition.dx, width),
          onHorizontalDragUpdate: (details) =>
              _handleTouch(details.localPosition.dx, width),
          child: Container(
            height: height,
            margin: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(6.0),
              border: Border.all(color: Colors.white12),
            ),
            child: CustomPaint(
              size: Size(width, height),
              painter: _EvalGraphPainter(
                moves: moves,
                selectedPly: selectedPly,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTouch(double touchX, double totalWidth) {
    if (moves.isEmpty) return;
    final clampedX = touchX.clamp(0.0, totalWidth);
    final ratio = clampedX / totalWidth;
    final targetPly = (ratio * (moves.length - 1)).round().clamp(
      0,
      moves.length - 1,
    );
    onPlySelected(targetPly);
  }
}

class _EvalGraphPainter extends CustomPainter {
  final List<AnalyzedMove> moves;
  final int selectedPly;

  _EvalGraphPainter({required this.moves, required this.selectedPly});

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height / 2.0;

    // 1. Draw center zero-advantage line (50% win chance)
    final centerLinePaint = Paint()
      ..color = Colors.white24
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawLine(
      Offset(0, centerY),
      Offset(size.width, centerY),
      centerLinePaint,
    );

    if (moves.isEmpty) return;

    final n = moves.length;
    final dx = n > 1 ? size.width / (n - 1) : size.width;

    // 2. Build advantage points using win probability (0.0 to 1.0, where 1.0 = top / White)
    final points = <Offset>[];
    for (int i = 0; i < n; i++) {
      final move = moves[i];
      final winProb = MoveClassifier.winPct(move.evalWhiteCp) / 100.0;
      // Invert Y: winProb 1.0 -> y = 4 (top), winProb 0.0 -> y = height - 4 (bottom)
      final y = size.height - (winProb * (size.height - 8.0) + 4.0);
      final x = (n > 1) ? (i * dx) : size.width / 2.0;
      points.add(Offset(x, y));
    }

    // 3. Draw shaded fill under White's curve and over Black's curve
    final path = Path()..moveTo(0, centerY);
    for (final pt in points) {
      path.lineTo(pt.dx, pt.dy);
    }
    path.lineTo(size.width, centerY);
    path.close();

    final fillPaint = Paint()
      ..color = const Color(0xFF769656).withValues(alpha: 0.35)
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fillPaint);

    // 4. Draw curve line
    final linePaint = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final strokePath = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 1; i < points.length; i++) {
      strokePath.lineTo(points[i].dx, points[i].dy);
    }
    canvas.drawPath(strokePath, linePaint);

    // 5. Draw blunder and mistake indicators
    final mistakePaint = Paint()..color = Colors.orangeAccent;
    final blunderPaint = Paint()..color = const Color(0xFFE53935);

    for (int i = 0; i < n; i++) {
      final move = moves[i];
      if (move.classification == MoveClassification.blunder) {
        canvas.drawCircle(points[i], 3.5, blunderPaint);
      } else if (move.classification == MoveClassification.mistake) {
        canvas.drawCircle(points[i], 3.0, mistakePaint);
      }
    }

    // 6. Draw vertical cursor at selectedPly
    if (selectedPly >= 0 && selectedPly < points.length) {
      final cursorX = points[selectedPly].dx;
      final cursorPaint = Paint()
        ..color = Colors.amberAccent
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(cursorX, 0),
        Offset(cursorX, size.height),
        cursorPaint,
      );

      // Selected node circle
      final selectedPointPaint = Paint()
        ..color = Colors.amberAccent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(points[selectedPly], 4.5, selectedPointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EvalGraphPainter oldDelegate) {
    return oldDelegate.selectedPly != selectedPly ||
        oldDelegate.moves.length != moves.length;
  }
}
