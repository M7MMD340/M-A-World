import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'base_avatar_component.dart';

/// The partner's avatar: not driven by local input at all. Its
/// [targetPosition] is updated from Firestore presence snapshots
/// (see [HouseWorld]), and this component just eases toward it each
/// frame so remote movement reads as smooth walking instead of teleports.
/// Tapping it is how the chat opens (see [onTap]), and [hasUnread] draws a
/// small red dot when the partner has an unread message waiting.
class RemoteAvatarComponent extends BaseAvatarComponent with TapCallbacks {
  RemoteAvatarComponent({
    required super.label,
    required super.sprite,
    required super.position,
    required this.onTap,
  }) : targetPosition = position!.clone();

  Vector2 targetPosition;
  final VoidCallback onTap;
  bool hasUnread = false;

  Vector2 _lastStep = Vector2.zero();

  @override
  bool get isMoving => _lastStep.length2 > 0.25;

  @override
  double get leanDirectionSign => _lastStep.x;

  @override
  void update(double dt) {
    final before = position.clone();
    position += (targetPosition - position) * (dt * 6).clamp(0.0, 1.0);
    _lastStep = position - before;
    super.update(dt);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    if (hasUnread) {
      final center = Offset(size.x * 0.8, size.y * 0.1);
      canvas.drawCircle(center, 8, Paint()..color = Colors.white);
      canvas.drawCircle(center, 6, Paint()..color = const Color(0xFFFF3D77));
    }
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    add(
      ScaleEffect.to(
        Vector2.all(0.94),
        EffectController(
          duration: 0.07,
          reverseDuration: 0.22,
          curve: Curves.easeOut,
          reverseCurve: Curves.elasticOut,
        ),
      ),
    );
  }

  @override
  void onTapUp(TapUpEvent event) {
    super.onTapUp(event);
    onTap();
  }
}
