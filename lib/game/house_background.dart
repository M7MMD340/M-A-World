import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

/// The whole house — living room, stairs, garden, and pool — as a single
/// continuous painted illustration, so it reads as one real place instead
/// of stitched-together scenes. Falls back to a plain placeholder if the
/// image hasn't loaded yet.
class HouseBackground extends PositionComponent {
  HouseBackground({required Vector2 worldSize, this.houseImage})
      : super(size: worldSize, position: Vector2.zero(), anchor: Anchor.topLeft);

  final ui.Image? houseImage;

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    final image = houseImage;
    if (image != null) {
      paintImage(
        canvas: canvas,
        rect: Rect.fromLTWH(0, 0, w, h),
        image: image,
        fit: BoxFit.fill,
      );
    } else {
      canvas.drawRect(
        Rect.fromLTWH(0, 0, w, h),
        Paint()..color = const Color(0xFFF7EEDD),
      );
    }

    _paintDayNightOverlay(canvas, w, h);
  }

  /// A soft color wash over the whole house that shifts with the real
  /// clock — warm midday light, an amber sunset, and a cool dim night —
  /// no extra art needed, just a time-driven tint.
  void _paintDayNightOverlay(Canvas canvas, double w, double h) {
    final hour = DateTime.now().hour + DateTime.now().minute / 60.0;

    Color tint;
    double alpha;
    if (hour >= 6 && hour < 17) {
      // Daytime: essentially no tint.
      tint = const Color(0xFFFFF3D6);
      alpha = 0.0;
    } else if (hour >= 17 && hour < 19) {
      // Sunset: warm amber wash, ramping in.
      final t = (hour - 17) / 2.0;
      tint = const Color(0xFFFF9E5E);
      alpha = 0.05 + 0.18 * t;
    } else if (hour >= 19 && hour < 21) {
      // Dusk fading to night.
      final t = (hour - 19) / 2.0;
      tint = Color.lerp(const Color(0xFFFF9E5E), const Color(0xFF2B2A55), t)!;
      alpha = 0.23 + 0.22 * t;
    } else if (hour >= 21 || hour < 5) {
      // Night: cool dim wash.
      tint = const Color(0xFF23244A);
      alpha = 0.45;
    } else {
      // Dawn fading back to day.
      final t = (hour - 5) / 1.0;
      tint = Color.lerp(const Color(0xFF23244A), const Color(0xFFFFF3D6), t)!;
      alpha = 0.45 * (1 - t);
    }

    if (alpha <= 0) return;
    canvas.drawRect(
      Rect.fromLTWH(0, 0, w, h),
      Paint()..color = tint.withValues(alpha: alpha),
    );
  }
}
