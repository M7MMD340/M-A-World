import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

class AvatarComponent extends PositionComponent
    with DragCallbacks, HasGameReference {
  AvatarComponent({
    required this.label,
    required this.color,
    required super.position,
  }) : super(size: Vector2.all(72), anchor: Anchor.center);

  final String label;
  final Color color;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(CircleComponent(
      radius: size.x / 2,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()..color = Colors.black.withValues(alpha: 0.12),
    )..position += Vector2(0, 6));

    add(CircleComponent(
      radius: size.x / 2,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()..color = color,
    ));

    add(CircleComponent(
      radius: size.x / 2,
      anchor: Anchor.center,
      position: size / 2,
      paint: Paint()
        ..color = Colors.white.withValues(alpha: 0.85)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    ));

    add(TextComponent(
      text: label.isNotEmpty ? label.substring(0, 1) : '؟',
      anchor: Anchor.center,
      position: size / 2,
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
    ));

    add(TextComponent(
      text: label,
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, size.y + 6),
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
