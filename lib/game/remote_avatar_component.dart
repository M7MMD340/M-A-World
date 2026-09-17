import 'package:flame/components.dart';

import 'base_avatar_component.dart';

/// The partner's avatar: not driven by local input at all. Its
/// [targetPosition] is updated from Firestore presence snapshots
/// (see [HouseWorld]), and this component just eases toward it each
/// frame so remote movement reads as smooth walking instead of teleports.
class RemoteAvatarComponent extends BaseAvatarComponent {
  RemoteAvatarComponent({
    required super.label,
    required super.sprite,
    required super.position,
  }) : targetPosition = position!.clone();

  Vector2 targetPosition;

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
}
