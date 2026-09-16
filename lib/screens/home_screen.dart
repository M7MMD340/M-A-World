import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/home_world.dart';
import '../models/user_profile.dart';
import 'settings_screen.dart';

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
      backgroundColor: const Color(0xFFF7EEDD),
      body: Stack(
        children: [
          Positioned.fill(
            child: GameWidget(
              game: HomeWorld(
                avatarLabel: profile.displayName,
                characterAsset: profile.characterAsset,
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
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: SafeArea(
              top: false,
              child: _BottomNav(
                onEditHome: () => _openStub(
                  context,
                  'تعديل البيت 🏠',
                  'إعادة ترتيب الأثاث واختيار التصاميم قادمة هنا.',
                ),
                onStore: () => _openStub(
                  context,
                  'المتجر 🏪',
                  'قطع وأثاث جديدة للبيت قادمة هنا.',
                ),
                onActivities: () => _openStub(
                  context,
                  'الفعاليات 🎉',
                  'ألعاب وتحديات مشتركة قادمة هنا.',
                ),
                onSettings: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => SettingsScreen(profile: profile),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.onEditHome,
    required this.onStore,
    required this.onActivities,
    required this.onSettings,
  });

  final VoidCallback onEditHome;
  final VoidCallback onStore;
  final VoidCallback onActivities;
  final VoidCallback onSettings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7E8),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _NavItem(icon: Icons.home_rounded, label: 'تعديل البيت', color: const Color(0xFFFF3D77), onTap: onEditHome),
          _NavItem(icon: Icons.storefront_rounded, label: 'المتجر', color: const Color(0xFFFFA94D), onTap: onStore),
          _NavItem(icon: Icons.celebration_rounded, label: 'الفعاليات', color: const Color(0xFF6EC6D9), onTap: onActivities),
          _NavItem(icon: Icons.settings_rounded, label: 'الإعدادات', color: const Color(0xFF7B61FF), onTap: onSettings),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.14),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B4A3A),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
