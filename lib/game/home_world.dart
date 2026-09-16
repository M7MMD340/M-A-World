import 'package:flame/components.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'house_world.dart';

/// The playable game: a house the couple's avatar can walk around freely
/// using an on-screen joystick. [joystick] is built in the constructor (not
/// onLoad) so it's always available synchronously for [HouseWorld] to read
/// every frame, with no async lifecycle race between the two.
class HomeWorld extends FlameGame<HouseWorld> {
  HomeWorld({
    required String avatarLabel,
    required Color avatarColor,
    required VoidCallback onOpenChat,
    required VoidCallback onOpenMemories,
    required VoidCallback onOpenCamera,
  })  : joystick = JoystickComponent(
          knob: CircleComponent(
            radius: 22,
            paint: Paint()..color = Colors.white.withValues(alpha: 0.95),
          ),
          background: CircleComponent(
            radius: 44,
            paint: Paint()..color = Colors.black.withValues(alpha: 0.22),
          ),
          margin: const EdgeInsets.only(left: 28, bottom: 28),
        ),
        super(
          world: HouseWorld(
            avatarLabel: avatarLabel,
            avatarColor: avatarColor,
            onOpenChat: onOpenChat,
            onOpenMemories: onOpenMemories,
            onOpenCamera: onOpenCamera,
          ),
        );

  final JoystickComponent joystick;

  @override
  Color backgroundColor() => const Color(0xFFF7EEDD);

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    camera.viewport.add(joystick);
  }
}
