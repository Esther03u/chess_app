import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../domain/game_logic.dart';

/// Renders tournament-grade vector chess pieces with smooth curves,
/// gradient shading, and high-contrast outlines for maximum clarity and elegance.
class ChessPieceWidget extends StatelessWidget {
  final PieceInfo piece;
  final double? size;

  const ChessPieceWidget({super.key, required this.piece, this.size});

  @override
  Widget build(BuildContext context) {
    final isWhite = piece.color == PlayerColor.white;

    return LayoutBuilder(
      builder: (context, constraints) {
        final dimension =
            size ??
            (constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth * 0.88
                : 44.0);

        return SizedBox(
          width: dimension,
          height: dimension,
          child: CustomPaint(
            painter: _VectorPiecePainter(type: piece.type, isWhite: isWhite),
          ),
        );
      },
    );
  }
}

class _VectorPiecePainter extends CustomPainter {
  final PieceType type;
  final bool isWhite;

  _VectorPiecePainter({required this.type, required this.isWhite});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Base colors
    final fillTop = isWhite ? AppTheme.whitePieceFill : AppTheme.blackPieceFill;
    final fillBottom = isWhite
        ? AppTheme.whitePieceGradient
        : AppTheme.blackPieceGradient;
    final strokeColor = isWhite
        ? AppTheme.whitePieceBorder
        : AppTheme.blackPieceBorder;

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillTop, fillBottom],
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.038).clamp(1.2, 3.0)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final highlightPaint = Paint()
      ..color = (isWhite ? Colors.white : Colors.white24).withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.02).clamp(0.8, 1.8)
      ..strokeCap = StrokeCap.round;

    // Draw shadow underneath piece for depth
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.28)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.04);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(w * 0.5, h * 0.92),
        width: w * 0.72,
        height: h * 0.12,
      ),
      shadowPaint,
    );

    switch (type) {
      case PieceType.pawn:
        _drawPawn(
          canvas,
          w,
          h,
          fillPaint,
          strokePaint,
          highlightPaint,
          strokeColor,
        );
        break;
      case PieceType.knight:
        _drawKnight(
          canvas,
          w,
          h,
          fillPaint,
          strokePaint,
          highlightPaint,
          strokeColor,
        );
        break;
      case PieceType.bishop:
        _drawBishop(
          canvas,
          w,
          h,
          fillPaint,
          strokePaint,
          highlightPaint,
          strokeColor,
        );
        break;
      case PieceType.rook:
        _drawRook(
          canvas,
          w,
          h,
          fillPaint,
          strokePaint,
          highlightPaint,
          strokeColor,
        );
        break;
      case PieceType.queen:
        _drawQueen(
          canvas,
          w,
          h,
          fillPaint,
          strokePaint,
          highlightPaint,
          strokeColor,
        );
        break;
      case PieceType.king:
        _drawKing(
          canvas,
          w,
          h,
          fillPaint,
          strokePaint,
          highlightPaint,
          strokeColor,
        );
        break;
    }
  }

  void _drawPawn(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint hl,
    Color strokeColor,
  ) {
    // Pedestal base
    final basePath = Path()
      ..moveTo(w * 0.22, h * 0.88)
      ..quadraticBezierTo(w * 0.5, h * 0.84, w * 0.78, h * 0.88)
      ..lineTo(w * 0.75, h * 0.78)
      ..quadraticBezierTo(w * 0.5, h * 0.75, w * 0.25, h * 0.78)
      ..close();
    canvas.drawPath(basePath, fill);
    canvas.drawPath(basePath, stroke);

    // Body & collar
    final bodyPath = Path()
      ..moveTo(w * 0.32, h * 0.77)
      ..cubicTo(w * 0.38, h * 0.62, w * 0.38, h * 0.52, w * 0.34, h * 0.44)
      ..quadraticBezierTo(w * 0.5, h * 0.42, w * 0.66, h * 0.44)
      ..cubicTo(w * 0.62, h * 0.52, w * 0.62, h * 0.62, w * 0.68, h * 0.77)
      ..close();
    canvas.drawPath(bodyPath, fill);
    canvas.drawPath(bodyPath, stroke);

    // Head sphere
    final headRadius = w * 0.17;
    final headCenter = Offset(w * 0.5, h * 0.28);
    canvas.drawCircle(headCenter, headRadius, fill);
    canvas.drawCircle(headCenter, headRadius, stroke);

    // Specular highlight
    canvas.drawArc(
      Rect.fromCircle(
        center: headCenter - Offset(headRadius * 0.25, headRadius * 0.25),
        radius: headRadius * 0.6,
      ),
      3.14,
      1.5,
      false,
      hl,
    );
  }

  void _drawRook(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint hl,
    Color strokeColor,
  ) {
    // Base
    final basePath = Path()
      ..moveTo(w * 0.18, h * 0.88)
      ..lineTo(w * 0.82, h * 0.88)
      ..lineTo(w * 0.76, h * 0.78)
      ..lineTo(w * 0.24, h * 0.78)
      ..close();
    canvas.drawPath(basePath, fill);
    canvas.drawPath(basePath, stroke);

    // Tower Body
    final towerPath = Path()
      ..moveTo(w * 0.28, h * 0.78)
      ..lineTo(w * 0.32, h * 0.40)
      ..lineTo(w * 0.68, h * 0.40)
      ..lineTo(w * 0.72, h * 0.78)
      ..close();
    canvas.drawPath(towerPath, fill);
    canvas.drawPath(towerPath, stroke);

    // Crenellations (Battlements: 3 teeth)
    final topPath = Path()
      ..moveTo(w * 0.24, h * 0.40)
      ..lineTo(w * 0.24, h * 0.22)
      ..lineTo(w * 0.36, h * 0.22)
      ..lineTo(w * 0.36, h * 0.29)
      ..lineTo(w * 0.44, h * 0.29)
      ..lineTo(w * 0.44, h * 0.22)
      ..lineTo(w * 0.56, h * 0.22)
      ..lineTo(w * 0.56, h * 0.29)
      ..lineTo(w * 0.64, h * 0.29)
      ..lineTo(w * 0.64, h * 0.22)
      ..lineTo(w * 0.76, h * 0.22)
      ..lineTo(w * 0.76, h * 0.40)
      ..close();
    canvas.drawPath(topPath, fill);
    canvas.drawPath(topPath, stroke);

    // Subtle horizontal divider line
    canvas.drawLine(
      Offset(w * 0.26, h * 0.38),
      Offset(w * 0.74, h * 0.38),
      stroke,
    );
  }

  void _drawKnight(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint hl,
    Color strokeColor,
  ) {
    // Base
    final basePath = Path()
      ..moveTo(w * 0.18, h * 0.88)
      ..lineTo(w * 0.82, h * 0.88)
      ..lineTo(w * 0.76, h * 0.78)
      ..lineTo(w * 0.24, h * 0.78)
      ..close();
    canvas.drawPath(basePath, fill);
    canvas.drawPath(basePath, stroke);

    // Horse head silhouette
    final horse = Path()
      ..moveTo(w * 0.28, h * 0.78)
      ..cubicTo(w * 0.24, h * 0.65, w * 0.25, h * 0.55, w * 0.34, h * 0.46)
      ..lineTo(w * 0.28, h * 0.44) // muzzle tip
      ..cubicTo(w * 0.26, h * 0.38, w * 0.32, h * 0.34, w * 0.40, h * 0.32)
      ..lineTo(w * 0.46, h * 0.16) // ear point
      ..cubicTo(
        w * 0.55,
        h * 0.20,
        w * 0.60,
        h * 0.24,
        w * 0.66,
        h * 0.30,
      ) // mane
      ..cubicTo(
        w * 0.76,
        h * 0.42,
        w * 0.78,
        h * 0.60,
        w * 0.72,
        h * 0.78,
      ) // back of neck
      ..close();

    canvas.drawPath(horse, fill);
    canvas.drawPath(horse, stroke);

    // Eye dot
    final eyePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.42, h * 0.34), w * 0.038, eyePaint);

    // Nostril / muzzle line
    canvas.drawLine(
      Offset(w * 0.30, h * 0.40),
      Offset(w * 0.36, h * 0.43),
      stroke,
    );

    // Mane texture line
    canvas.drawLine(
      Offset(w * 0.58, h * 0.32),
      Offset(w * 0.54, h * 0.46),
      stroke,
    );
  }

  void _drawBishop(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint hl,
    Color strokeColor,
  ) {
    // Base
    final basePath = Path()
      ..moveTo(w * 0.18, h * 0.88)
      ..lineTo(w * 0.82, h * 0.88)
      ..lineTo(w * 0.76, h * 0.78)
      ..lineTo(w * 0.24, h * 0.78)
      ..close();
    canvas.drawPath(basePath, fill);
    canvas.drawPath(basePath, stroke);

    // Mitre body
    final mitre = Path()
      ..moveTo(w * 0.30, h * 0.78)
      ..cubicTo(w * 0.24, h * 0.60, w * 0.26, h * 0.42, w * 0.46, h * 0.24)
      ..cubicTo(w * 0.50, h * 0.20, w * 0.54, h * 0.24, w * 0.74, h * 0.42)
      ..cubicTo(w * 0.76, h * 0.60, w * 0.70, h * 0.78, w * 0.30, h * 0.78)
      ..close();
    canvas.drawPath(mitre, fill);
    canvas.drawPath(mitre, stroke);

    // Top finial ball
    final topBall = Offset(w * 0.50, h * 0.17);
    canvas.drawCircle(topBall, w * 0.055, fill);
    canvas.drawCircle(topBall, w * 0.055, stroke);

    // Mitre Cut Slit (iconic bishop feature)
    final slitPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.04).clamp(1.5, 3.0)
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
      Offset(w * 0.42, h * 0.38),
      Offset(w * 0.56, h * 0.48),
      slitPaint,
    );
  }

  void _drawQueen(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint hl,
    Color strokeColor,
  ) {
    // Base
    final basePath = Path()
      ..moveTo(w * 0.16, h * 0.88)
      ..lineTo(w * 0.84, h * 0.88)
      ..lineTo(w * 0.76, h * 0.78)
      ..lineTo(w * 0.24, h * 0.78)
      ..close();
    canvas.drawPath(basePath, fill);
    canvas.drawPath(basePath, stroke);

    // Coronet body with 5 peaks
    final coronet = Path()
      ..moveTo(w * 0.26, h * 0.78)
      ..lineTo(w * 0.18, h * 0.38) // Left outer peak
      ..lineTo(w * 0.32, h * 0.48) // Valley
      ..lineTo(w * 0.36, h * 0.30) // Mid-left peak
      ..lineTo(w * 0.44, h * 0.46) // Valley
      ..lineTo(w * 0.50, h * 0.24) // Center tallest peak
      ..lineTo(w * 0.56, h * 0.46) // Valley
      ..lineTo(w * 0.64, h * 0.30) // Mid-right peak
      ..lineTo(w * 0.68, h * 0.48) // Valley
      ..lineTo(w * 0.82, h * 0.38) // Right outer peak
      ..lineTo(w * 0.74, h * 0.78)
      ..close();
    canvas.drawPath(coronet, fill);
    canvas.drawPath(coronet, stroke);

    // Jewels on top of the 5 coronet points
    final orbs = [
      Offset(w * 0.18, h * 0.36),
      Offset(w * 0.36, h * 0.28),
      Offset(w * 0.50, h * 0.22),
      Offset(w * 0.64, h * 0.28),
      Offset(w * 0.82, h * 0.36),
    ];
    for (final orb in orbs) {
      canvas.drawCircle(orb, w * 0.038, fill);
      canvas.drawCircle(orb, w * 0.038, stroke);
    }
  }

  void _drawKing(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint hl,
    Color strokeColor,
  ) {
    // Base
    final basePath = Path()
      ..moveTo(w * 0.16, h * 0.88)
      ..lineTo(w * 0.84, h * 0.88)
      ..lineTo(w * 0.76, h * 0.78)
      ..lineTo(w * 0.24, h * 0.78)
      ..close();
    canvas.drawPath(basePath, fill);
    canvas.drawPath(basePath, stroke);

    // Royal Crown Body
    final crown = Path()
      ..moveTo(w * 0.26, h * 0.78)
      ..cubicTo(w * 0.20, h * 0.60, w * 0.20, h * 0.44, w * 0.34, h * 0.34)
      ..lineTo(w * 0.40, h * 0.40)
      ..lineTo(w * 0.50, h * 0.32)
      ..lineTo(w * 0.60, h * 0.40)
      ..lineTo(w * 0.66, h * 0.34)
      ..cubicTo(w * 0.80, h * 0.44, w * 0.80, h * 0.60, w * 0.74, h * 0.78)
      ..close();
    canvas.drawPath(crown, fill);
    canvas.drawPath(crown, stroke);

    // Royal Cross finial on top of King
    final crossPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.05).clamp(2.0, 3.8)
      ..strokeCap = StrokeCap.square;

    // Vertical bar
    canvas.drawLine(
      Offset(w * 0.50, h * 0.14),
      Offset(w * 0.50, h * 0.32),
      crossPaint,
    );
    // Horizontal cross bar
    canvas.drawLine(
      Offset(w * 0.41, h * 0.20),
      Offset(w * 0.59, h * 0.20),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _VectorPiecePainter oldDelegate) {
    return oldDelegate.type != type || oldDelegate.isWhite != isWhite;
  }
}
