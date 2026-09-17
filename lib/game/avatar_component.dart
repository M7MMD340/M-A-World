import 'package:flame/components.dart';

import 'base_avatar_component.dart';

/// The signed-in person's own avatar: driven by [inputDir] (fed each frame
/// from a joystick), clamped to the walkable house bounds.
class AvatarComponent extends BaseAvatarComponent {
  AvatarComponent({
    required super.label,
    required super.sprite,
    required this.worldSize,
    required super.position,
    this.speed = 220,
  });

  final Vector2 worldSize;
  final double speed;

  /// Set every frame by the owning game from the joystick's relativeDelta.
  /// Magnitude 0..1, direction is the desired travel direction.
  Vector2 inputDir = Vector2.zero();

  @override
  bool get isMoving => inputDir.length2 > 0.01;

  @override
  double get leanDirectionSign => inputDir.x;

  @override
  void update(double dt) {
    if (isMoving) {
      final half = size / 2;
      final target = position + inputDir * speed * dt;
      position = Vector2(
        target.x.clamp(half.x, worldSize.x - half.x),
        target.y.clamp(0, worldSize.y),
      );
    }
    super.update(dt);
  }
}
