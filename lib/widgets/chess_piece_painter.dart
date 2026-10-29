import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../domain/game_logic.dart';
import '../models/customization_options.dart';

/// Renders chess pieces with high legibility, supporting multiple style presets
/// (Staunton Standard, Tournament Shaded, Modern Minimalist, Retro Unicode).
class ChessPieceWidget extends StatelessWidget {
  final PieceInfo piece;
  final double? size;
  final PieceStylePreset style;

  const ChessPieceWidget({
    super.key,
    required this.piece,
    this.size,
    this.style = PieceStylePreset.staunton,
  });

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

        if (style == PieceStylePreset.retroUnicode) {
          return SizedBox(
            width: dimension,
            height: dimension,
            child: Center(
              child: Text(
                _unicodeSymbol(piece),
                style: TextStyle(
                  fontSize: dimension * 0.72,
                  color: isWhite ? Colors.white : Colors.black,
                  shadows: [
                    Shadow(
                      color: isWhite ? Colors.black54 : Colors.white38,
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SizedBox(
          width: dimension,
          height: dimension,
          child: CustomPaint(
            painter: _VectorPiecePainter(
              type: piece.type,
              isWhite: isWhite,
              style: style,
            ),
          ),
        );
      },
    );
  }

  static String _unicodeSymbol(PieceInfo piece) {
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

class _VectorPiecePainter extends CustomPainter {
  final PieceType type;
  final bool isWhite;
  final PieceStylePreset style;

  _VectorPiecePainter({
    required this.type,
    required this.isWhite,
    required this.style,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final isShaded = style == PieceStylePreset.shaded;
    final isMinimalist = style == PieceStylePreset.minimalist;

    // Base colors
    final fillTop = isWhite
        ? (isMinimalist ? const Color(0xFFFFFFFF) : AppTheme.whitePieceFill)
        : (isMinimalist ? const Color(0xFF22201D) : AppTheme.blackPieceFill);
    final fillBottom = isWhite
        ? (isShaded ? AppTheme.whitePieceGradient : const Color(0xFFF4F3EE))
        : (isShaded ? AppTheme.blackPieceGradient : const Color(0xFF2E2B27));
    final strokeColor = isWhite
        ? (isMinimalist ? const Color(0xFF1E1E1E) : AppTheme.whitePieceBorder)
        : (isMinimalist ? const Color(0xFFFFFFFF) : AppTheme.blackPieceBorder);

    final fillPaint = Paint()..style = PaintingStyle.fill;

    if (isShaded) {
      fillPaint.shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [fillTop, fillBottom],
      ).createShader(Rect.fromLTWH(0, 0, w, h));
    } else {
      fillPaint.color = fillTop;
    }

    final strokePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * (isMinimalist ? 0.05 : 0.04)).clamp(1.5, 3.2)
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final detailPaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.03).clamp(1.0, 2.2)
      ..strokeCap = StrokeCap.round;

    // Ambient drop shadow for depth
    if (isShaded) {
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
    }

    switch (type) {
      case PieceType.pawn:
        _drawPawn(canvas, w, h, fillPaint, strokePaint, detailPaint);
        break;
      case PieceType.knight:
        _drawKnight(
          canvas,
          w,
          h,
          fillPaint,
          strokePaint,
          detailPaint,
          strokeColor,
        );
        break;
      case PieceType.bishop:
        _drawBishop(canvas, w, h, fillPaint, strokePaint, detailPaint);
        break;
      case PieceType.rook:
        _drawRook(canvas, w, h, fillPaint, strokePaint, detailPaint);
        break;
      case PieceType.queen:
        _drawQueen(canvas, w, h, fillPaint, strokePaint, detailPaint);
        break;
      case PieceType.king:
        _drawKing(canvas, w, h, fillPaint, strokePaint, detailPaint);
        break;
    }
  }

  // --- 1. PAWN ---
  void _drawPawn(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint detail,
  ) {
    // Pedestal base
    final basePath = Path()
      ..moveTo(w * 0.20, h * 0.88)
      ..lineTo(w * 0.80, h * 0.88)
      ..lineTo(w * 0.75, h * 0.80)
      ..lineTo(w * 0.25, h * 0.80)
      ..close();
    canvas.drawPath(basePath, fill);
    canvas.drawPath(basePath, stroke);

    // Collar ring
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.44, w * 0.36, h * 0.07),
        Radius.circular(w * 0.03),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.32, h * 0.44, w * 0.36, h * 0.07),
        Radius.circular(w * 0.03),
      ),
      stroke,
    );

    // Body taper
    final body = Path()
      ..moveTo(w * 0.30, h * 0.80)
      ..quadraticBezierTo(w * 0.37, h * 0.60, w * 0.36, h * 0.50)
      ..lineTo(w * 0.64, h * 0.50)
      ..quadraticBezierTo(w * 0.63, h * 0.60, w * 0.70, h * 0.80)
      ..close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);

    // Head sphere
    final headCenter = Offset(w * 0.50, h * 0.30);
    final headRadius = w * 0.17;
    canvas.drawCircle(headCenter, headRadius, fill);
    canvas.drawCircle(headCenter, headRadius, stroke);
  }

  // --- 2. KNIGHT ---
  void _drawKnight(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint detail,
    Color strokeColor,
  ) {
    // Pedestal base
    final basePath = Path()
      ..moveTo(w * 0.18, h * 0.88)
      ..lineTo(w * 0.82, h * 0.88)
      ..lineTo(w * 0.76, h * 0.80)
      ..lineTo(w * 0.24, h * 0.80)
      ..close();
    canvas.drawPath(basePath, fill);
    canvas.drawPath(basePath, stroke);

    // Iconic Staunton Horse Profile
    final horse = Path()
      ..moveTo(w * 0.28, h * 0.80) // bottom chest
      ..quadraticBezierTo(w * 0.25, h * 0.68, w * 0.30, h * 0.58) // throat
      ..lineTo(w * 0.22, h * 0.54) // mouth corner
      ..quadraticBezierTo(w * 0.18, h * 0.44, w * 0.26, h * 0.40) // muzzle
      ..lineTo(w * 0.42, h * 0.34) // bridge of snout
      ..lineTo(w * 0.46, h * 0.16) // ear tip
      ..lineTo(w * 0.53, h * 0.24) // ear back
      ..quadraticBezierTo(w * 0.65, h * 0.27, w * 0.70, h * 0.38) // mane arch
      ..quadraticBezierTo(w * 0.75, h * 0.55, w * 0.72, h * 0.80) // spine
      ..close();

    canvas.drawPath(horse, fill);
    canvas.drawPath(horse, stroke);

    // Knight Eye
    final eyePaint = Paint()
      ..color = strokeColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(w * 0.38, h * 0.40), w * 0.038, eyePaint);

    // Mouth / jaw slit
    canvas.drawLine(
      Offset(w * 0.23, h * 0.48),
      Offset(w * 0.32, h * 0.50),
      detail,
    );

    // Mane notches for distinct Staunton texture
    canvas.drawLine(
      Offset(w * 0.58, h * 0.31),
      Offset(w * 0.52, h * 0.40),
      detail,
    );
    canvas.drawLine(
      Offset(w * 0.67, h * 0.44),
      Offset(w * 0.58, h * 0.54),
      detail,
    );
  }

  // --- 3. BISHOP ---
  void _drawBishop(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint detail,
  ) {
    // Pedestal base
    final basePath = Path()
      ..moveTo(w * 0.18, h * 0.88)
      ..lineTo(w * 0.82, h * 0.88)
      ..lineTo(w * 0.76, h * 0.80)
      ..lineTo(w * 0.24, h * 0.80)
      ..close();
    canvas.drawPath(basePath, fill);
    canvas.drawPath(basePath, stroke);

    // Collar ring
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.72, w * 0.40, h * 0.08),
        Radius.circular(w * 0.03),
      ),
      fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w * 0.30, h * 0.72, w * 0.40, h * 0.08),
        Radius.circular(w * 0.03),
      ),
      stroke,
    );

    // Mitre body (distinctive pointed oval)
    final mitre = Path()
      ..moveTo(w * 0.32, h * 0.72)
      ..cubicTo(w * 0.22, h * 0.55, w * 0.24, h * 0.36, w * 0.50, h * 0.22)
      ..cubicTo(w * 0.76, h * 0.36, w * 0.78, h * 0.55, w * 0.68, h * 0.72)
      ..close();
    canvas.drawPath(mitre, fill);
    canvas.drawPath(mitre, stroke);

    // Finial ball on top of mitre
    canvas.drawCircle(Offset(w * 0.50, h * 0.17), w * 0.055, fill);
    canvas.drawCircle(Offset(w * 0.50, h * 0.17), w * 0.055, stroke);

    // Deep Mitre Cut (defining characteristic of chess bishop)
    canvas.drawLine(
      Offset(w * 0.42, h * 0.34),
      Offset(w * 0.58, h * 0.48),
      detail,
    );
    // Cross detail on bishop belly
    canvas.drawLine(
      Offset(w * 0.43, h * 0.58),
      Offset(w * 0.57, h * 0.58),
      detail,
    );
  }

  // --- 4. ROOK ---
  void _drawRook(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint detail,
  ) {
    // Pedestal base
    final basePath = Path()
      ..moveTo(w * 0.18, h * 0.88)
      ..lineTo(w * 0.82, h * 0.88)
      ..lineTo(w * 0.76, h * 0.80)
      ..lineTo(w * 0.24, h * 0.80)
      ..close();
    canvas.drawPath(basePath, fill);
    canvas.drawPath(basePath, stroke);

    // Solid castle walls
    final tower = Path()
      ..moveTo(w * 0.26, h * 0.80)
      ..lineTo(w * 0.31, h * 0.42)
      ..lineTo(w * 0.69, h * 0.42)
      ..lineTo(w * 0.74, h * 0.80)
      ..close();
    canvas.drawPath(tower, fill);
    canvas.drawPath(tower, stroke);

    // Crenellations (3 prominent battlements)
    final crenels = Path()
      ..moveTo(w * 0.23, h * 0.42)
      ..lineTo(w * 0.23, h * 0.22)
      ..lineTo(w * 0.35, h * 0.22)
      ..lineTo(w * 0.35, h * 0.30)
      ..lineTo(w * 0.43, h * 0.30)
      ..lineTo(w * 0.43, h * 0.22)
      ..lineTo(w * 0.57, h * 0.22)
      ..lineTo(w * 0.57, h * 0.30)
      ..lineTo(w * 0.65, h * 0.30)
      ..lineTo(w * 0.65, h * 0.22)
      ..lineTo(w * 0.77, h * 0.22)
      ..lineTo(w * 0.77, h * 0.42)
      ..close();
    canvas.drawPath(crenels, fill);
    canvas.drawPath(crenels, stroke);

    // Decorative fortress slit
    canvas.drawLine(
      Offset(w * 0.25, h * 0.42),
      Offset(w * 0.75, h * 0.42),
      detail,
    );
  }

  // --- 5. QUEEN ---
  void _drawQueen(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint detail,
  ) {
    // Pedestal base
    final basePath = Path()
      ..moveTo(w * 0.16, h * 0.88)
      ..lineTo(w * 0.84, h * 0.88)
      ..lineTo(w * 0.76, h * 0.80)
      ..lineTo(w * 0.24, h * 0.80)
      ..close();
    canvas.drawPath(basePath, fill);
    canvas.drawPath(basePath, stroke);

    // Flared Queen Corset / Body
    final body = Path()
      ..moveTo(w * 0.26, h * 0.80)
      ..quadraticBezierTo(w * 0.35, h * 0.60, w * 0.30, h * 0.50)
      ..lineTo(w * 0.70, h * 0.50)
      ..quadraticBezierTo(w * 0.65, h * 0.60, w * 0.74, h * 0.80)
      ..close();
    canvas.drawPath(body, fill);
    canvas.drawPath(body, stroke);

    // Coronet with 5 peaks
    final coronet = Path()
      ..moveTo(w * 0.26, h * 0.50)
      ..lineTo(w * 0.18, h * 0.36) // Left outer peak
      ..lineTo(w * 0.32, h * 0.44) // Valley
      ..lineTo(w * 0.38, h * 0.28) // Mid-left peak
      ..lineTo(w * 0.45, h * 0.42) // Valley
      ..lineTo(w * 0.50, h * 0.22) // Center peak
      ..lineTo(w * 0.55, h * 0.42) // Valley
      ..lineTo(w * 0.62, h * 0.28) // Mid-right peak
      ..lineTo(w * 0.68, h * 0.44) // Valley
      ..lineTo(w * 0.82, h * 0.36) // Right outer peak
      ..lineTo(w * 0.74, h * 0.50)
      ..close();
    canvas.drawPath(coronet, fill);
    canvas.drawPath(coronet, stroke);

    // 5 Jewels / Pearls on Coronet tips
    final pearls = [
      Offset(w * 0.18, h * 0.34),
      Offset(w * 0.38, h * 0.26),
      Offset(w * 0.50, h * 0.20),
      Offset(w * 0.62, h * 0.26),
      Offset(w * 0.82, h * 0.34),
    ];
    for (final pearl in pearls) {
      canvas.drawCircle(pearl, w * 0.038, fill);
      canvas.drawCircle(pearl, w * 0.038, stroke);
    }
  }

  // --- 6. KING ---
  void _drawKing(
    Canvas canvas,
    double w,
    double h,
    Paint fill,
    Paint stroke,
    Paint detail,
  ) {
    // Pedestal base
    final basePath = Path()
      ..moveTo(w * 0.16, h * 0.88)
      ..lineTo(w * 0.84, h * 0.88)
      ..lineTo(w * 0.76, h * 0.80)
      ..lineTo(w * 0.24, h * 0.80)
      ..close();
    canvas.drawPath(basePath, fill);
    canvas.drawPath(basePath, stroke);

    // King Robe / Body
    final robe = Path()
      ..moveTo(w * 0.26, h * 0.80)
      ..quadraticBezierTo(w * 0.34, h * 0.60, w * 0.30, h * 0.46)
      ..lineTo(w * 0.70, h * 0.46)
      ..quadraticBezierTo(w * 0.66, h * 0.60, w * 0.74, h * 0.80)
      ..close();
    canvas.drawPath(robe, fill);
    canvas.drawPath(robe, stroke);

    // Imperial Crown Top
    final crown = Path()
      ..moveTo(w * 0.26, h * 0.46)
      ..cubicTo(w * 0.20, h * 0.36, w * 0.24, h * 0.26, w * 0.36, h * 0.24)
      ..lineTo(w * 0.43, h * 0.30)
      ..lineTo(w * 0.50, h * 0.24)
      ..lineTo(w * 0.57, h * 0.30)
      ..lineTo(w * 0.64, h * 0.24)
      ..cubicTo(w * 0.76, h * 0.26, w * 0.80, h * 0.36, w * 0.74, h * 0.46)
      ..close();
    canvas.drawPath(crown, fill);
    canvas.drawPath(crown, stroke);

    // The Royal Cross (Prominent, unmistakable symbol of the King)
    final crossPaint = Paint()
      ..color = stroke.color
      ..style = PaintingStyle.stroke
      ..strokeWidth = (w * 0.055).clamp(2.2, 3.8)
      ..strokeCap = StrokeCap.square;

    // Vertical shaft
    canvas.drawLine(
      Offset(w * 0.50, h * 0.10),
      Offset(w * 0.50, h * 0.24),
      crossPaint,
    );
    // Horizontal crossbar
    canvas.drawLine(
      Offset(w * 0.40, h * 0.15),
      Offset(w * 0.60, h * 0.15),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _VectorPiecePainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.isWhite != isWhite ||
        oldDelegate.style != style;
  }
}
