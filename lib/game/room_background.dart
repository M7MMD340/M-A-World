import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Hand-painted cozy room backdrop: warm wall with a sunlit window and a
/// plant, a wood floor, and a patterned rug. Pure vector drawing, no
/// external art assets.
class RoomBackground extends PositionComponent {
  RoomBackground({required Vector2 gameSize})
      : super(size: gameSize, position: Vector2.zero(), anchor: Anchor.topLeft);

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final floorTop = h * 0.5;

    // Wall.
    final wallRect = Rect.fromLTWH(0, 0, w, floorTop + 12);
    canvas.drawRect(
      wallRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFBF1E4), Color(0xFFF3E2CE)],
        ).createShader(wallRect),
    );

    // Window with warm light.
    final windowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: Offset(w * 0.5, h * 0.16), width: w * 0.32, height: h * 0.20),
      const Radius.circular(18),
    );
    canvas.drawRRect(windowRect, Paint()..color = const Color(0xFFFFF7E8));
    canvas.drawRRect(
      windowRect,
      Paint()
        ..color = const Color(0xFFE7C7A3)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 6,
    );
    canvas.save();
    canvas.clipRRect(windowRect);
    canvas.drawCircle(
      Offset(w * 0.5, h * 0.10),
      w * 0.22,
      Paint()
        ..color = const Color(0xFFFFE9A8).withValues(alpha: 0.85)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 18),
    );
    canvas.restore();
    canvas.drawLine(
      Offset(w * 0.5, windowRect.top),
      Offset(w * 0.5, windowRect.bottom),
      Paint()
        ..color = const Color(0xFFE7C7A3)
        ..strokeWidth = 4,
    );

    // Plant in the corner.
    _drawPlant(canvas, Offset(w * 0.92, floorTop - 6));
    _drawPlant(canvas, Offset(w * 0.08, floorTop - 6));

    // Floor.
    final floorRect = Rect.fromLTWH(0, floorTop, w, h - floorTop);
    canvas.drawRect(
      floorRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3B583), Color(0xFFD9A56E)],
        ).createShader(floorRect),
    );
    // Plank lines.
    final plankPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 2;
    for (double y = floorTop + 24; y < h; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(w, y), plankPaint);
    }

    // Rug.
    final rugRect = Rect.fromCenter(
      center: Offset(w / 2, h * 0.76),
      width: w * 0.62,
      height: h * 0.34,
    );
    final rugRRect = RRect.fromRectAndRadius(rugRect, const Radius.circular(28));
    canvas.drawRRect(rugRRect, Paint()..color = const Color(0xFFE98BA0).withValues(alpha: 0.9));
    canvas.drawRRect(
      RRect.fromRectAndRadius(rugRect.deflate(14), const Radius.circular(20)),
      Paint()
        ..color = const Color(0xFFFBF1E4).withValues(alpha: 0.9)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
  }

  void _drawPlant(Canvas canvas, Offset base) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: base, width: 30, height: 22),
        const Radius.circular(8),
      ),
      Paint()..color = const Color(0xFFC97B5F),
    );
    final leafPaint = Paint()..color = const Color(0xFF7FAE7A);
    for (final angle in [-0.6, -0.15, 0.3, 0.7]) {
      final tip = base + Offset.fromDirection(-1.571 + angle, 34);
      final path = Path()
        ..moveTo(base.dx, base.dy - 10)
        ..quadraticBezierTo(
          base.dx + (tip.dx - base.dx) * 0.6,
          base.dy - 10 + (tip.dy - base.dy) * 0.4,
          tip.dx,
          tip.dy,
        )
        ..quadraticBezierTo(
          base.dx + (tip.dx - base.dx) * 0.4,
          base.dy - 10 + (tip.dy - base.dy) * 0.6,
          base.dx,
          base.dy - 10,
        );
      canvas.drawPath(path, leafPaint);
    }
  }
}
