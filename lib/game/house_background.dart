import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Hand-painted backdrop for the whole walkable house: a vertical strip of
/// five rooms (bedroom, living room, kitchen, garden, pool), each drawn with
/// distinct props so a room reads at a glance. Pure vector drawing, no
/// external art assets.
class HouseBackground extends PositionComponent {
  HouseBackground({required Vector2 worldSize})
      : super(size: worldSize, position: Vector2.zero(), anchor: Anchor.topLeft);

  static const double roomH = 350;

  @override
  void render(Canvas canvas) {
    final w = size.x;

    _paintIndoorRoom(canvas, w, 0 * roomH, roomH, 'غرفة النوم', hasWindow: false);
    _drawBed(canvas, w, 0 * roomH);

    _paintIndoorRoom(canvas, w, 1 * roomH, roomH, 'غرفة المعيشة', hasWindow: true);

    _paintIndoorRoom(canvas, w, 2 * roomH, roomH, 'المطبخ', hasWindow: false);
    _drawKitchenCounter(canvas, w, 2 * roomH);

    _paintGarden(canvas, w, 3 * roomH);

    _paintPool(canvas, w, 4 * roomH);
  }

  void _label(Canvas canvas, double w, double top, String text, Color color) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: TextDirection.rtl,
    )..layout();
    tp.paint(canvas, Offset(w / 2 - tp.width / 2, top + 14));
  }

  void _paintIndoorRoom(
    Canvas canvas,
    double w,
    double top,
    double h,
    String label, {
    required bool hasWindow,
  }) {
    final floorTop = top + h * 0.5;

    final wallRect = Rect.fromLTWH(0, top, w, floorTop - top);
    canvas.drawRect(
      wallRect,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: const [Color(0xFFFBF1E4), Color(0xFFF3E2CE)],
        ).createShader(wallRect),
    );

    if (hasWindow) {
      final windowRect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(w * 0.5, top + h * 0.16), width: w * 0.32, height: h * 0.20),
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
        Offset(w * 0.5, top + h * 0.10),
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
      _drawPlant(canvas, Offset(w * 0.92, floorTop - 6));
      _drawPlant(canvas, Offset(w * 0.08, floorTop - 6));
    }

    final floorRect = Rect.fromLTWH(0, floorTop, w, top + h - floorTop);
    canvas.drawRect(
      floorRect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFE3B583), Color(0xFFD9A56E)],
        ).createShader(floorRect),
    );
    final plankPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.05)
      ..strokeWidth = 2;
    for (double y = floorTop + 24; y < top + h; y += 26) {
      canvas.drawLine(Offset(0, y), Offset(w, y), plankPaint);
    }

    if (hasWindow) {
      final rugRect = Rect.fromCenter(
        center: Offset(w / 2, top + h * 0.76),
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

    canvas.drawLine(
      Offset(0, top + h),
      Offset(w, top + h),
      Paint()
        ..color = const Color(0xFF6B4A3A).withValues(alpha: 0.3)
        ..strokeWidth = 3,
    );

    _label(canvas, w, top, label, const Color(0xFF6B4A3A));
  }

  void _drawBed(Canvas canvas, double w, double top) {
    final bedRect = Rect.fromCenter(center: Offset(w * 0.32, top + 260), width: 220, height: 130);
    canvas.drawRRect(
      RRect.fromRectAndRadius(bedRect, const Radius.circular(18)),
      Paint()..color = const Color(0xFF9B85FF),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bedRect.left + 10, bedRect.top + 10, bedRect.width - 20, 40),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFFFFF7E8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(bedRect.left, bedRect.top - 26, bedRect.width, 30),
        const Radius.circular(10),
      ),
      Paint()..color = const Color(0xFF7B61FF),
    );
  }

  void _drawKitchenCounter(Canvas canvas, double w, double top) {
    final counterRect = Rect.fromLTWH(w * 0.14, top + 190, w * 0.72, 70);
    canvas.drawRRect(
      RRect.fromRectAndRadius(counterRect, const Radius.circular(14)),
      Paint()..color = const Color(0xFFCDE8D0),
    );
    for (int i = 0; i < 4; i++) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(counterRect.left + 14 + i * (counterRect.width - 28) / 4, counterRect.top + 10, 6, 50),
          const Radius.circular(3),
        ),
        Paint()..color = Colors.white.withValues(alpha: 0.5),
      );
    }
    canvas.drawCircle(Offset(counterRect.left + counterRect.width * 0.75, counterRect.top - 4), 22, Paint()..color = const Color(0xFF3A2E29));
    canvas.drawCircle(Offset(counterRect.left + counterRect.width * 0.75, counterRect.top - 4), 16, Paint()..color = const Color(0xFF6B4A3A));
  }

  void _paintGarden(Canvas canvas, double w, double top) {
    final rect = Rect.fromLTWH(0, top, w, roomH);
    canvas.drawRect(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFCDE8B0), Color(0xFFB9DB98)],
        ).createShader(rect),
    );
    for (final dx in [0.12, 0.32, 0.68, 0.88]) {
      _drawFlowerBed(canvas, Offset(w * dx, top + 90));
    }
    _drawPlant(canvas, Offset(w * 0.5, top + 260));
    canvas.drawLine(
      Offset(0, top + roomH),
      Offset(w, top + roomH),
      Paint()
        ..color = const Color(0xFF5F9563).withValues(alpha: 0.4)
        ..strokeWidth = 3,
    );
    _label(canvas, w, top, 'الحديقة', const Color(0xFF3E6B41));
  }

  void _drawFlowerBed(Canvas canvas, Offset center) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: center, width: 70, height: 34), const Radius.circular(12)),
      Paint()..color = const Color(0xFF8B5E3C),
    );
    final colors = [const Color(0xFFFF9E9E), const Color(0xFFFFE9A8), const Color(0xFFCDE8D0)];
    for (int i = 0; i < 3; i++) {
      canvas.drawCircle(center + Offset(-18.0 + i * 18, -4), 8, Paint()..color = colors[i]);
    }
  }

  void _paintPool(Canvas canvas, double w, double top) {
    final rect = Rect.fromLTWH(0, top, w, roomH);
    canvas.drawRect(rect, Paint()..color = const Color(0xFFEFDFC0));

    final poolRect = Rect.fromCenter(center: Offset(w / 2, top + roomH * 0.55), width: w * 0.72, height: roomH * 0.6);
    canvas.drawRRect(
      RRect.fromRectAndRadius(poolRect.inflate(10), const Radius.circular(24)),
      Paint()..color = const Color(0xFFFFF7E8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(poolRect, const Radius.circular(18)),
      Paint()..color = const Color(0xFF6EC6D9),
    );
    final shimmer = Paint()..color = Colors.white.withValues(alpha: 0.35);
    for (int i = 0; i < 4; i++) {
      canvas.drawLine(
        Offset(poolRect.left + 20, poolRect.top + 24 + i * 26),
        Offset(poolRect.left + 60, poolRect.top + 24 + i * 26),
        shimmer..strokeWidth = 4,
      );
    }
    canvas.drawLine(
      Offset(0, top + roomH),
      Offset(w, top + roomH),
      Paint()
        ..color = const Color(0xFFC9A876).withValues(alpha: 0.5)
        ..strokeWidth = 3,
    );
    _label(canvas, w, top, 'المسبح', const Color(0xFF2C6E7A));
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
