import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/home_world.dart';
import '../models/user_profile.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.profile});

  final UserProfile profile;

  void _openStub(BuildContext context, String title, String message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF211A29),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(color: Color(0xFF9C8FAE)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameWidget(
        game: HomeWorld(
          avatarLabel: profile.displayName,
          avatarColor: profile.avatarColor,
          onOpenChat: () => _openStub(
            context,
            'رسائلنا 💌',
            'شاشة المحادثة قادمة هنا قريبًا.',
          ),
          onOpenMemories: () => _openStub(
            context,
            'ذكرياتنا 🖼️',
            'الخط الزمني للذكريات المشتركة قادم هنا.',
          ),
          onOpenCamera: () => _openStub(
            context,
            'الكاميرا 📷',
            'التقاط ومشاركة اللحظات قادم هنا.',
          ),
        ),
      ),
    );
  }
}
