import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class InteractiveObject extends PositionComponent with TapCallbacks {
  InteractiveObject({
    required this.emoji,
    required this.caption,
    required this.color,
    required this.onTap,
    required super.position,
  }) : super(size: Vector2.all(64), anchor: Anchor.center);

  final String emoji;
  final String caption;
  final Color color;
  final VoidCallback onTap;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(RectangleComponent(
      size: size,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()..color = Colors.black.withValues(alpha: 0.10),
    )..position += Vector2(0, 5));

    add(RRectComponent(
      size: size,
      radius: 18,
      position: size / 2,
      anchor: Anchor.center,
      paint: Paint()..color = color.withValues(alpha: 0.85),
    ));

    add(TextComponent(
      text: emoji,
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(style: const TextStyle(fontSize: 28)),
    ));

    add(TextComponent(
      text: caption,
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, size.y + 6),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF3A2E29),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ));
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    add(
      ScaleEffect.to(
        Vector2.all(0.9),
        EffectController(duration: 0.08, reverseDuration: 0.08),
      ),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    onTap();
  }
}

class RRectComponent extends PositionComponent {
  RRectComponent({
    required this.radius,
    required this.paint,
    required super.size,
    required super.position,
    required super.anchor,
  });

  final double radius;
  final Paint paint;

  @override
  void render(Canvas canvas) {
    final rect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      Radius.circular(radius),
    );
    canvas.drawRRect(rect, paint);
  }
}
