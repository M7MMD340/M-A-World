import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// Shared visuals for both the local, joystick-driven avatar and the
/// partner's network-driven one: the illustrated sprite, ground shadow,
/// idle breathing bob / walking bounce, and a lean into the direction of
/// travel. Subclasses only decide *where* the avatar is each frame.
abstract class BaseAvatarComponent extends PositionComponent {
  BaseAvatarComponent({
    required this.label,
    required this.sprite,
    required super.position,
  }) : super(size: Vector2(64, 110), anchor: Anchor.bottomCenter);

  final String label;
  final ui.Image sprite;

  double _bobTime = 0;
  double _lean = 0;

  bool get isMoving;

  /// -1..1, which way to lean while moving.
  double get leanDirectionSign;

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

    final leanTarget = isMoving ? leanDirectionSign.clamp(-1.0, 1.0) * 0.14 : 0.0;
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
