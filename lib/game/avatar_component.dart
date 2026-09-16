import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

/// A cozy hand-drawn style chibi character: rounded body, round head,
/// simple hair/face, drawn entirely with vector paths (no external art
/// assets, no cost). Draggable around the room, with a gentle idle bob
/// for a bit of life.
class AvatarComponent extends PositionComponent
    with DragCallbacks, HasGameReference {
  AvatarComponent({
    required this.label,
    required this.color,
    required super.position,
  }) : super(size: Vector2(78, 104), anchor: Anchor.center);

  final String label;
  final Color color;

  double _bobTime = 0;
  late final Color _hairColor;
  late final Color _skinColor;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final hsl = HSLColor.fromColor(color);
    _hairColor = hsl
        .withLightness((hsl.lightness - 0.30).clamp(0.0, 1.0))
        .withSaturation((hsl.saturation - 0.10).clamp(0.0, 1.0))
        .toColor();
    _skinColor = const Color(0xFFFAD3B0);

    add(TextComponent(
      text: label,
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, size.y + 4),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF3A2E29),
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    ));
  }

  @override
  void update(double dt) {
    super.update(dt);
    _bobTime += dt;
  }

  @override
  void render(Canvas canvas) {
    final bob = isDragged ? 0.0 : math.sin(_bobTime * 2.4) * 2.5;
    canvas.save();
    canvas.translate(0, bob);

    final w = size.x;
    final h = size.y;
    final cx = w / 2;

    // Soft ground shadow.
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h - 8),
        width: w * 0.62,
        height: 12,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.14),
    );

    // Feet.
    final shoePaint = Paint()..color = const Color(0xFF6B4A3A);
    for (final dx in [-11.0, 11.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(cx + dx, h - 16), width: 16, height: 14),
          const Radius.circular(7),
        ),
        shoePaint,
      );
    }

    // Arms.
    final armPaint = Paint()..color = color;
    for (final dx in [-1.0, 1.0]) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx + dx * (w * 0.34), h * 0.56),
            width: 16,
            height: 34,
          ),
          const Radius.circular(9),
        ),
        armPaint,
      );
    }

    // Body.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, h * 0.62),
          width: w * 0.58,
          height: h * 0.42,
        ),
        const Radius.circular(26),
      ),
      Paint()..color = color,
    );

    // Head.
    final headCenter = Offset(cx, h * 0.26);
    final headRadius = w * 0.30;
    canvas.drawCircle(headCenter, headRadius, Paint()..color = _skinColor);

    // Hair (back cap, drawn slightly larger, behind the face features).
    canvas.drawArc(
      Rect.fromCircle(center: headCenter, radius: headRadius + 3),
      math.pi,
      math.pi,
      true,
      Paint()..color = _hairColor,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, headCenter.dy - headRadius * 0.35),
          width: (headRadius + 3) * 2,
          height: headRadius * 0.9,
        ),
        Radius.circular(headRadius),
      ),
      Paint()..color = _hairColor,
    );

    // Blush.
    final blushPaint = Paint()..color = const Color(0xFFFF9E9E).withValues(alpha: 0.55);
    canvas.drawCircle(headCenter + Offset(-headRadius * 0.55, headRadius * 0.15), 4.2, blushPaint);
    canvas.drawCircle(headCenter + Offset(headRadius * 0.55, headRadius * 0.15), 4.2, blushPaint);

    // Eyes.
    final eyePaint = Paint()..color = const Color(0xFF3A2E29);
    canvas.drawCircle(headCenter + Offset(-headRadius * 0.32, 0), 2.6, eyePaint);
    canvas.drawCircle(headCenter + Offset(headRadius * 0.32, 0), 2.6, eyePaint);

    // Smile.
    final smilePath = Path()
      ..moveTo(headCenter.dx - 6, headCenter.dy + headRadius * 0.32)
      ..quadraticBezierTo(
        headCenter.dx,
        headCenter.dy + headRadius * 0.32 + 5,
        headCenter.dx + 6,
        headCenter.dy + headRadius * 0.32,
      );
    canvas.drawPath(
      smilePath,
      Paint()
        ..color = const Color(0xFF3A2E29)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round,
    );

    canvas.restore();
    super.render(canvas);
  }

  @override
  void onDragUpdate(DragUpdateEvent event) {
    super.onDragUpdate(event);
    final target = position + event.localDelta;
    final half = size / 2;
    final maxX = game.size.x - half.x;
    final maxY = game.size.y - half.y;
    position = Vector2(
      target.x.clamp(half.x, maxX <= half.x ? half.x : maxX),
      target.y.clamp(half.y, maxY <= half.y ? half.y : maxY),
    );
  }
}
