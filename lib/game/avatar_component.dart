import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// The couple's avatar: a real illustrated sprite (matching the house art
/// style), not a code-drawn shape. Walks around the house driven by
/// [inputDir] (fed each frame from a joystick), with an idle breathing bob,
/// a walking bounce, and a lean into the direction of travel.
class AvatarComponent extends PositionComponent {
  AvatarComponent({
    required this.label,
    required this.sprite,
    required this.worldSize,
    required super.position,
    this.speed = 220,
  }) : super(size: Vector2(64, 110), anchor: Anchor.bottomCenter);

  final String label;
  final ui.Image sprite;
  final Vector2 worldSize;
  final double speed;

  /// Set every frame by the owning game from the joystick's relativeDelta.
  /// Magnitude 0..1, direction is the desired travel direction.
  Vector2 inputDir = Vector2.zero();

  double _bobTime = 0;
  double _lean = 0;
  bool get isMoving => inputDir.length2 > 0.01;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

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

    if (isMoving) {
      final half = size / 2;
      final target = position + inputDir * speed * dt;
      position = Vector2(
        target.x.clamp(half.x, worldSize.x - half.x),
        target.y.clamp(0, worldSize.y),
      );
    }

    final leanTarget = isMoving ? inputDir.x.clamp(-1.0, 1.0) * 0.14 : 0.0;
    _lean += (leanTarget - _lean) * math.min(1, dt * 10);
    angle = _lean;
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;
    final cx = w / 2;

    // Bouncy footstep rhythm while walking; gentle breathing while idle.
    final bob = isMoving
        ? -math.sin(_bobTime * 9.0).abs() * 3.5
        : math.sin(_bobTime * 2.4) * 2.5;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h - 4),
        width: w * 0.62 * (1 - (isMoving ? 0.08 : 0)),
        height: 10,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.16),
    );

    canvas.save();
    canvas.translate(0, bob);
    paintImage(
      canvas: canvas,
      rect: Rect.fromLTWH(0, 0, w, h),
      image: sprite,
      fit: BoxFit.contain,
      alignment: Alignment.bottomCenter,
      filterQuality: FilterQuality.medium,
    );
    canvas.restore();

    super.render(canvas);
  }
}
