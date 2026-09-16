import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'avatar_component.dart';
import 'interactive_object.dart';

class HomeWorld extends FlameGame {
  HomeWorld({
    required this.avatarLabel,
    required this.avatarColor,
    required this.onOpenChat,
    required this.onOpenMemories,
    required this.onOpenCamera,
  });

  final String avatarLabel;
  final Color avatarColor;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenMemories;
  final VoidCallback onOpenCamera;

  @override
  Color backgroundColor() => const Color(0xFFF7EEDD);

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFFF7EEDD),
    ));

    add(RectangleComponent(
      position: Vector2(size.x / 2, size.y * 0.72),
      size: Vector2(size.x * 0.7, size.y * 0.4),
      anchor: Anchor.center,
      paint: Paint()..color = const Color(0xFFE9CBA3),
    ));

    add(InteractiveObject(
      emoji: '📮',
      caption: 'رسائلنا',
      color: const Color(0xFFFF3D77),
      position: Vector2(size.x * 0.22, size.y * 0.28),
      onTap: onOpenChat,
    ));

    add(InteractiveObject(
      emoji: '🖼️',
      caption: 'ذكرياتنا',
      color: const Color(0xFF7B61FF),
      position: Vector2(size.x * 0.78, size.y * 0.28),
      onTap: onOpenMemories,
    ));

    add(InteractiveObject(
      emoji: '📷',
      caption: 'الكاميرا',
      color: const Color(0xFFFFD166),
      position: Vector2(size.x * 0.5, size.y * 0.18),
      onTap: onOpenCamera,
    ));

    add(AvatarComponent(
      label: avatarLabel,
      color: avatarColor,
      position: Vector2(size.x / 2, size.y * 0.62),
    ));
  }
}
