import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

enum ObjectKind { mailbox, memories, camera }

/// A tappable room object drawn as hand-illustrated vector art (no emoji,
/// no external assets) sitting on a soft rounded card that matches the
/// room's cozy palette.
class InteractiveObject extends PositionComponent with TapCallbacks {
  InteractiveObject({
    required this.kind,
    required this.caption,
    required this.color,
    required this.onTap,
    required super.position,
  }) : super(size: Vector2.all(64), anchor: Anchor.center);

  final ObjectKind kind;
  final String caption;
  final Color color;
  final VoidCallback onTap;

  @override
  Future<void> onLoad() async {
    await super.onLoad();

    add(TextComponent(
      text: caption,
      anchor: Anchor.topCenter,
      position: Vector2(size.x / 2, size.y + 6),
      textRenderer: TextPaint(
        style: const TextStyle(
          color: Color(0xFF3A2E29),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    ));
  }

  @override
  void render(Canvas canvas) {
    final w = size.x;
    final h = size.y;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(2, 6, w, h), const Radius.circular(18)),
      Paint()..color = Colors.black.withValues(alpha: 0.10),
    );
    final cardPaint = Paint()..color = color.withValues(alpha: 0.85);
    final cardRect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, w, h), const Radius.circular(18));
    canvas.drawRRect(cardRect, cardPaint);

    switch (kind) {
      case ObjectKind.mailbox:
        _drawMailbox(canvas, w, h);
      case ObjectKind.memories:
        _drawMemories(canvas, w, h);
      case ObjectKind.camera:
        _drawCamera(canvas, w, h);
    }

    super.render(canvas);
  }

  void _drawMailbox(Canvas canvas, double w, double h) {
    final cx = w / 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.66), width: 8, height: h * 0.36),
        const Radius.circular(4),
      ),
      Paint()..color = const Color(0xFF6B4A3A),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(cx, h * 0.40), width: w * 0.5, height: h * 0.34),
        const Radius.circular(12),
      ),
      Paint()..color = const Color(0xFFFFF7E8),
    );
    canvas.drawPath(
      (Path()
        ..moveTo(cx + w * 0.14, h * 0.30)
        ..lineTo(cx + w * 0.30, h * 0.24)
        ..lineTo(cx + w * 0.30, h * 0.36)
        ..close()),
      Paint()..color = const Color(0xFFFF6B6B),
    );
    final heartPaint = Paint()..color = color;
    final hc = Offset(cx, h * 0.42);
    canvas.drawCircle(hc + const Offset(-3.2, -1.5), 3.6, heartPaint);
    canvas.drawCircle(hc + const Offset(3.2, -1.5), 3.6, heartPaint);
    canvas.drawPath(
      Path()
        ..moveTo(hc.dx - 6.2, hc.dy - 0.5)
        ..lineTo(hc.dx, hc.dy + 6)
        ..lineTo(hc.dx + 6.2, hc.dy - 0.5)
        ..close(),
      heartPaint,
    );
  }

  void _drawMemories(Canvas canvas, double w, double h) {
    final frameRect = Rect.fromCenter(center: Offset(w / 2, h * 0.5), width: w * 0.58, height: h * 0.62);
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect.inflate(6), const Radius.circular(10)),
      Paint()..color = const Color(0xFFFFF7E8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frameRect, const Radius.circular(6)),
      Paint()..color = const Color(0xFFCDE8D0),
    );
    canvas.drawCircle(
      Offset(frameRect.left + frameRect.width * 0.28, frameRect.top + frameRect.height * 0.32),
      frameRect.width * 0.16,
      Paint()..color = const Color(0xFFFFE9A8),
    );
    final mountain = Path()
      ..moveTo(frameRect.left + 2, frameRect.bottom - 4)
      ..lineTo(frameRect.left + frameRect.width * 0.42, frameRect.top + frameRect.height * 0.35)
      ..lineTo(frameRect.left + frameRect.width * 0.68, frameRect.bottom - 4)
      ..close();
    canvas.drawPath(mountain, Paint()..color = const Color(0xFF7FAE7A));
    final mountain2 = Path()
      ..moveTo(frameRect.left + frameRect.width * 0.35, frameRect.bottom - 4)
      ..lineTo(frameRect.left + frameRect.width * 0.72, frameRect.top + frameRect.height * 0.48)
      ..lineTo(frameRect.right - 2, frameRect.bottom - 4)
      ..close();
    canvas.drawPath(mountain2, Paint()..color = const Color(0xFF5F9563));
  }

  void _drawCamera(Canvas canvas, double w, double h) {
    final body = Rect.fromCenter(center: Offset(w / 2, h * 0.56), width: w * 0.62, height: h * 0.42);
    canvas.drawRRect(
      RRect.fromRectAndRadius(body, const Radius.circular(10)),
      Paint()..color = const Color(0xFFFFF7E8),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(body.center.dx - body.width * 0.28, body.top), width: 12, height: 8),
        const Radius.circular(3),
      ),
      Paint()..color = const Color(0xFFFFF7E8),
    );
    canvas.drawCircle(body.center, body.height * 0.42, Paint()..color = const Color(0xFF3A2E29));
    canvas.drawCircle(body.center, body.height * 0.30, Paint()..color = const Color(0xFF6B93D6));
    canvas.drawCircle(
      body.center + Offset(-body.height * 0.10, -body.height * 0.10),
      body.height * 0.09,
      Paint()..color = Colors.white.withValues(alpha: 0.8),
    );
  }

  @override
  void onTapDown(TapDownEvent event) {
    super.onTapDown(event);
    add(
      ScaleEffect.to(
        Vector2.all(0.88),
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
