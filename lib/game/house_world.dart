import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flutter/material.dart';

import 'avatar_component.dart';
import 'home_world.dart';
import 'house_background.dart';
import 'interactive_object.dart';

/// The whole walkable house: a single vertical strip of rooms (bedroom,
/// living room, kitchen, garden, pool) the couple's avatar can roam
/// between freely. [avatar] is built in the constructor (not onLoad) so it
/// is always available synchronously — no async lifecycle race with the
/// outer game reading it.
class HouseWorld extends World with HasGameReference<HomeWorld> {
  HouseWorld({
    required String avatarLabel,
    required Color avatarColor,
    required this.onOpenChat,
    required this.onOpenMemories,
    required this.onOpenCamera,
  }) : avatar = AvatarComponent(
          label: avatarLabel,
          color: avatarColor,
          worldSize: size,
          position: Vector2(roomWidth / 2, roomHeight * 1.5),
        );

  final VoidCallback onOpenChat;
  final VoidCallback onOpenMemories;
  final VoidCallback onOpenCamera;

  static const double roomWidth = 700;
  static const double roomHeight = 350;
  static const int roomCount = 5;
  static final Vector2 size = Vector2(roomWidth, roomHeight * roomCount);

  final AvatarComponent avatar;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(HouseBackground(worldSize: size));

    add(InteractiveObject(
      kind: ObjectKind.mailbox,
      caption: 'رسائلنا',
      color: const Color(0xFFFF3D77),
      position: Vector2(roomWidth * 0.18, roomHeight * 1.7),
      onTap: onOpenChat,
    ));

    add(InteractiveObject(
      kind: ObjectKind.memories,
      caption: 'ذكرياتنا',
      color: const Color(0xFF7B61FF),
      position: Vector2(roomWidth * 0.82, roomHeight * 1.28),
      onTap: onOpenMemories,
    ));

    add(InteractiveObject(
      kind: ObjectKind.camera,
      caption: 'الكاميرا',
      color: const Color(0xFFFFD166),
      position: Vector2(roomWidth * 0.5, roomHeight * 1.24),
      onTap: onOpenCamera,
    ));

    add(avatar);

    game.camera.follow(avatar, maxSpeed: 320, snap: true);
    game.camera.setBounds(Rectangle.fromLTWH(0, 0, size.x, size.y));
  }

  @override
  void update(double dt) {
    super.update(dt);
    avatar.inputDir = game.joystick.relativeDelta;
  }
}
