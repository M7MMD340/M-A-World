import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import 'avatar_component.dart';
import 'home_world.dart';
import 'house_background.dart';
import 'interactive_object.dart';

/// The whole walkable house: one continuous illustration (living room,
/// stairs, garden, pool) the couple's avatar can roam across freely.
/// [avatar] is built inside onLoad (after its sprite image is loaded);
/// this world's own update() only ever runs after that onLoad fully
/// completes, so reading [avatar] there is never a race.
class HouseWorld extends World with HasGameReference<HomeWorld> {
  HouseWorld({
    required this.avatarLabel,
    required this.characterAsset,
    required this.onOpenChat,
    required this.onOpenMemories,
    required this.onOpenCamera,
  });

  final String avatarLabel;
  final String characterAsset;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenMemories;
  final VoidCallback onOpenCamera;

  static const double roomWidth = 700;
  // The house illustration's own pixel aspect ratio (765x1024) scaled to
  // roomWidth, so nothing stretches.
  static const double houseHeight = 936;
  static final Vector2 size = Vector2(roomWidth, houseHeight);

  late final AvatarComponent avatar;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final houseImage = await Flame.images.load('rooms/house.jpg');
    add(HouseBackground(worldSize: size, houseImage: houseImage));

    add(InteractiveObject(
      kind: ObjectKind.mailbox,
      caption: 'رسائلنا',
      color: const Color(0xFFFF3D77),
      position: Vector2(roomWidth * 0.15, houseHeight * 0.83),
      onTap: onOpenChat,
    ));

    // These align with the camera and photo frames already painted into
    // the house illustration, so the icon card is hidden and only the tap
    // zone + label bubble remain — the interaction stays embedded in the
    // art instead of floating on top of it.
    add(InteractiveObject(
      kind: ObjectKind.memories,
      caption: 'ذكرياتنا',
      color: const Color(0xFF7B61FF),
      position: Vector2(roomWidth * 0.56, houseHeight * 0.16),
      onTap: onOpenMemories,
      showIcon: false,
    ));

    add(InteractiveObject(
      kind: ObjectKind.camera,
      caption: 'الكاميرا',
      color: const Color(0xFFFFD166),
      position: Vector2(roomWidth * 0.16, houseHeight * 0.29),
      onTap: onOpenCamera,
      showIcon: false,
    ));

    final avatarSprite = await Flame.images.load('characters/$characterAsset.png');
    avatar = AvatarComponent(
      label: avatarLabel,
      sprite: avatarSprite,
      worldSize: size,
      position: Vector2(roomWidth * 0.45, houseHeight * 0.36),
    );
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
