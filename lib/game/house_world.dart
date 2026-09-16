import 'package:flame/components.dart';
import 'package:flame/experimental.dart';
import 'package:flame/flame.dart';
import 'package:flutter/material.dart';

import 'avatar_component.dart';
import 'home_world.dart';
import 'house_background.dart';
import 'interactive_object.dart';

/// The whole walkable house: the living room, with the garden and pool
/// right outside, the couple's avatar can roam between freely. [avatar] is
/// built inside onLoad (after its sprite image is loaded); this world's own
/// update() only ever runs after that onLoad fully completes, so reading
/// [avatar] there is never a race.
class HouseWorld extends World with HasGameReference<HomeWorld> {
  HouseWorld({
    required this.avatarLabel,
    required this.onOpenChat,
    required this.onOpenMemories,
    required this.onOpenCamera,
  });

  final String avatarLabel;
  final VoidCallback onOpenChat;
  final VoidCallback onOpenMemories;
  final VoidCallback onOpenCamera;

  static const double roomWidth = 700;
  static const double roomHeight = 350;
  // The garden+pool illustration is taller than it is wide relative to the
  // living room's, so it gets its own band height (derived from its actual
  // pixel aspect ratio) instead of reusing roomHeight, to avoid stretching.
  static const double gardenPoolHeight = 840;
  static final Vector2 size = Vector2(
    roomWidth,
    roomHeight + gardenPoolHeight - HouseBackground.gardenOverlap,
  );

  late final AvatarComponent avatar;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    final livingRoomImage = await Flame.images.load('rooms/living_room.png');
    final gardenPoolImage = await Flame.images.load('rooms/garden_pool.jpg');
    add(HouseBackground(
      worldSize: size,
      livingRoomImage: livingRoomImage,
      gardenPoolImage: gardenPoolImage,
    ));

    add(InteractiveObject(
      kind: ObjectKind.mailbox,
      caption: 'رسائلنا',
      color: const Color(0xFFFF3D77),
      position: Vector2(roomWidth * 0.15, roomHeight * 0.85),
      onTap: onOpenChat,
    ));

    // These two align with the camera and photo frames already painted
    // into the living room illustration, so the icon card is hidden and
    // only the tap zone + label bubble remain — the interaction stays
    // embedded in the art instead of floating on top of it.
    add(InteractiveObject(
      kind: ObjectKind.memories,
      caption: 'ذكرياتنا',
      color: const Color(0xFF7B61FF),
      position: Vector2(roomWidth * 0.32, roomHeight * 0.28),
      onTap: onOpenMemories,
      showIcon: false,
    ));

    add(InteractiveObject(
      kind: ObjectKind.camera,
      caption: 'الكاميرا',
      color: const Color(0xFFFFD166),
      position: Vector2(roomWidth * 0.49, roomHeight * 0.33),
      onTap: onOpenCamera,
      showIcon: false,
    ));

    // TODO: let each person pick boy/girl once the wardrobe/character
    // picker exists; everyone gets the boy sprite for now.
    final avatarSprite = await Flame.images.load('characters/boy.png');
    avatar = AvatarComponent(
      label: avatarLabel,
      sprite: avatarSprite,
      worldSize: size,
      position: Vector2(roomWidth / 2, roomHeight * 0.85),
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
