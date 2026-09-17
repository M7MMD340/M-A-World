import 'dart:math' as math;

import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import 'base_avatar_component.dart';

/// The partner's avatar: not driven by local input at all. Its
/// [targetPosition] is updated from Firestore presence snapshots
/// (see [HouseWorld]), and this component just eases toward it each
/// frame so remote movement reads as smooth walking instead of teleports.
/// Tapping it is how the chat opens (see [onTap]), [hasUnread] draws a
/// small red dot when the partner has an unread message waiting, and
/// [isTyping] shows a little bouncing-dots bubble above their head so you
/// know they're writing even while you're out in the house.
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
  bool isTyping = false;

  Vector2 _lastStep = Vector2.zero();
  double _typingTime = 0;

  @override
  bool get isMoving => _lastStep.length2 > 0.25;

  @override
  double get leanDirectionSign => _lastStep.x;

  @override
  void update(double dt) {
    final before = position.clone();
    position += (targetPosition - position) * (dt * 6).clamp(0.0, 1.0);
    _lastStep = position - before;
    if (isTyping) _typingTime += dt;
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
    if (isTyping) _renderTypingBubble(canvas);
  }

  void _renderTypingBubble(Canvas canvas) {
    const width = 44.0;
    const height = 22.0;
    final rect = Rect.fromCenter(center: Offset(size.x / 2, -16), width: width, height: height);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(11));

    canvas.drawRRect(
      rrect.shift(const Offset(0, 2)),
      Paint()..color = Colors.black.withValues(alpha: 0.12),
    );
    canvas.drawRRect(rrect, Paint()..color = const Color(0xFFFFF7E8));

    final tail = Path()
      ..moveTo(rect.center.dx - 5, rect.bottom)
      ..lineTo(rect.center.dx, rect.bottom + 6)
      ..lineTo(rect.center.dx + 5, rect.bottom)
      ..close();
    canvas.drawPath(tail, Paint()..color = const Color(0xFFFFF7E8));

    for (var i = 0; i < 3; i++) {
      final dx = rect.left + 12 + i * 10.0;
      final phase = _typingTime * 6 - i * 0.6;
      final dy = rect.center.dy + math.sin(phase).clamp(-1.0, 1.0) * 2.5;
      canvas.drawCircle(Offset(dx, dy), 2.4, Paint()..color = const Color(0xFFFF3D77));
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
