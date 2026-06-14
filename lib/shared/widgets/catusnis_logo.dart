// lib/shared/widgets/catusnis_logo.dart

import 'package:flutter/material.dart';
import 'dart:math' as math;

class CatusnisLogo extends StatelessWidget {
  final double size;
  const CatusnisLogo({super.key, this.size = 48});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _LogoPainter()),
    );
  }
}

// ── Widget texte CATUSNIS coloré ──────────────────────────────────────────────
class CatusnisText extends StatelessWidget {
  final double fontSize;
  const CatusnisText({super.key, this.fontSize = 32});

  @override
  Widget build(BuildContext context) {
    const letters = [
      ('C', Color(0xFFFF6F00)),
      ('A', Color(0xFFFF6F00)),
      ('T', Color(0xFF2E7D32)),
      ('U', Color(0xFFFF6F00)),
      ('S', Color(0xFF2E7D32)),
      ('N', Color(0xFF2E7D32)),
      ('I', Color(0xFFFF6F00)),
      ('S', Color(0xFF2E7D32)),
    ];

    // ✅ FIX : FittedBox scale le Row quand l'espace est contraint
    // Évite l'overflow de 46px dans l'AppBar (contrainte 102px)
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: letters
            .map((l) => Text(
                  l.$1,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: l.$2,
                    letterSpacing: 2,
                    fontFamily: 'monospace',
                  ),
                ))
            .toList(),
      ),
    );
  }
}

// ── Peintre hexagone logo ─────────────────────────────────────────────────────
class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Fond hexagone bleu foncé
    final bgPaint = Paint()..color = const Color(0xFF0D3380);
    final hexPath = _hexPath(w / 2, h / 2, w / 2 - 1);
    canvas.drawPath(hexPath, bgPaint);

    // Bordure
    canvas.drawPath(
      hexPath,
      Paint()
        ..color = const Color(0xFF1976D2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.03,
    );

    final white = Paint()..color = Colors.white;
    final orange = Paint()..color = const Color(0xFFFF6F00);
    final green = Paint()..color = const Color(0xFF2E7D32);
    final red = Paint()..color = const Color(0xFFE53935);

    // ── Croix médicale ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.3, h * 0.25, w * 0.4, h * 0.12),
          Radius.circular(w * 0.03)),
      white,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.44, h * 0.16, w * 0.12, h * 0.3),
          Radius.circular(w * 0.03)),
      white,
    );

    // ── Cœur rouge dans la croix ──
    final heartPath = Path();
    final cx = w * 0.5;
    final cy = h * 0.31;
    final hs = w * 0.07;
    heartPath.moveTo(cx, cy + hs * 0.9);
    heartPath.cubicTo(cx - hs * 2, cy - hs * 0.5, cx - hs * 2, cy - hs * 1.5,
        cx, cy - hs * 0.4);
    heartPath.cubicTo(cx + hs * 2, cy - hs * 1.5, cx + hs * 2, cy - hs * 0.5,
        cx, cy + hs * 0.9);
    canvas.drawPath(heartPath, red);

    // ── WiFi orange (haut gauche) ──
    final wifiCx = w * 0.22;
    final wifiCy = h * 0.28;
    for (int i = 3; i >= 1; i--) {
      // ✅ FIX : withOpacity → withValues
      final alpha = i == 3
          ? 1.0
          : i == 2
              ? 0.7
              : 0.4;
      canvas.drawArc(
        Rect.fromCenter(
          center: Offset(wifiCx, wifiCy + h * 0.06),
          width: w * 0.1 * i,
          height: w * 0.1 * i,
        ),
        math.pi * 1.2,
        math.pi * 0.6,
        false,
        Paint()
          ..color = Color(0xFFFF6F00).withValues(alpha: alpha)
          ..style = PaintingStyle.stroke
          ..strokeWidth = w * 0.035
          ..strokeCap = StrokeCap.round,
      );
    }
    canvas.drawCircle(Offset(wifiCx, wifiCy + h * 0.07), w * 0.04, orange);

    // ── Engrenage vert (haut droit) ──
    final gx = w * 0.78;
    final gy = h * 0.26;
    final gr = w * 0.08;
    canvas.drawCircle(Offset(gx, gy), gr, green);
    canvas.drawCircle(
        Offset(gx, gy), gr * 0.5, Paint()..color = const Color(0xFF1565C0));
    for (int i = 0; i < 8; i++) {
      final angle = (i * math.pi * 2) / 8;
      final tx = gx + math.cos(angle) * (gr + w * 0.04);
      final ty = gy + math.sin(angle) * (gr + w * 0.04);
      canvas.drawCircle(Offset(tx, ty), w * 0.03, green);
    }

    // ── Stéthoscope (bas gauche) ──
    final sPath = Path();
    sPath.moveTo(w * 0.2, h * 0.6);
    sPath.quadraticBezierTo(w * 0.14, h * 0.7, w * 0.14, h * 0.78);
    sPath.quadraticBezierTo(w * 0.14, h * 0.86, w * 0.22, h * 0.86);
    sPath.quadraticBezierTo(w * 0.3, h * 0.86, w * 0.3, h * 0.78);
    canvas.drawPath(
      sPath,
      Paint()
        ..color = const Color(0xFF37474F)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.045
        ..strokeCap = StrokeCap.round,
    );
    canvas.drawCircle(Offset(w * 0.3, h * 0.78), w * 0.055,
        Paint()..color = const Color(0xFF37474F));
    canvas.drawCircle(Offset(w * 0.3, h * 0.78), w * 0.03, white);

    // ── Tablette (bas droit) ──
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.65, h * 0.58, w * 0.16, w * 0.24),
          Radius.circular(w * 0.025)),
      Paint()..color = const Color(0xFF263238),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(w * 0.67, h * 0.60, w * 0.12, w * 0.17),
          Radius.circular(w * 0.015)),
      Paint()..color = const Color(0xFF42A5F5),
    );
    canvas.drawCircle(Offset(w * 0.73, h * 0.79), w * 0.015, white);

    // ── Réseau 3 points connectés (bas centre) ──
    canvas.drawCircle(Offset(w * 0.38, h * 0.9), w * 0.04, green);
    canvas.drawCircle(Offset(w * 0.5, h * 0.84), w * 0.045, orange);
    canvas.drawCircle(Offset(w * 0.62, h * 0.9), w * 0.04, green);
    final linePaint = Paint()
      ..color = const Color(0xFF4CAF50)
      ..strokeWidth = w * 0.02
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(
        Offset(w * 0.42, h * 0.89), Offset(w * 0.47, h * 0.86), linePaint);
    canvas.drawLine(Offset(w * 0.53, h * 0.86), Offset(w * 0.58, h * 0.89),
        linePaint..color = const Color(0xFFFF6F00));
    canvas.drawCircle(Offset(w * 0.5, h * 0.84), w * 0.02, white);
  }

  Path _hexPath(double cx, double cy, double r) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * math.pi * 2) / 6 - math.pi / 6;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      // ✅ FIX curly_braces_in_flow_control_structures
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(_LogoPainter old) => false;
}
