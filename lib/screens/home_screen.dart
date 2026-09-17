import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../game/home_world.dart';
import '../models/couple.dart';
import '../models/message.dart';
import '../models/user_profile.dart';
import '../services/chat.dart';
import 'chat_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.profile, required this.couple});

  final UserProfile profile;
  final Couple? couple;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Whether ChatScreen is currently pushed on top — read by [_UnreadToast]
  // so it doesn't pop up a banner for messages already visible on screen.
  // A ValueNotifier (not setState) so toggling it never rebuilds the
  // GameWidget below and resets the avatar/camera/presence state.
  final ValueNotifier<bool> _chatOpen = ValueNotifier(false);

  UserProfile get profile => widget.profile;
  Couple? get couple => widget.couple;

  @override
  void dispose() {
    _chatOpen.dispose();
    super.dispose();
  }

  Future<void> _openChat(BuildContext context) async {
    final partnerId = couple?.partnerId(profile.uid);
    if (couple == null || !couple!.isComplete || partnerId == null) {
      _openStub(
        context,
        'رسائلنا 💌',
        'اربط حسابك بشريكك من الإعدادات أول عشان تقدروا تتراسلوا.',
      );
      return;
    }
    _chatOpen.value = true;
    await Navigator.of(context).push(
      buildChatRoute(
        ChatScreen(
          coupleId: couple!.id,
          myUid: profile.uid,
          partnerId: partnerId,
        ),
      ),
    );
    _chatOpen.value = false;
  }

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
                myUid: profile.uid,
                coupleId: couple?.id,
                partnerId: couple?.partnerId(profile.uid),
                onOpenChat: () => _openChat(context),
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
          if (couple != null && couple!.isComplete)
            Positioned(
              left: 12,
              right: 12,
              top: 0,
              child: SafeArea(
                bottom: false,
                child: _UnreadToast(
                  coupleId: couple!.id,
                  myUid: profile.uid,
                  partnerId: couple!.partnerId(profile.uid)!,
                  chatOpen: _chatOpen,
                  onTap: () => _openChat(context),
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
                    builder: (_) => SettingsScreen(profile: profile, couple: couple),
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

/// A banner that slides down from the top when the partner sends a message
/// while we're not already inside the chat (that case is covered live by
/// ChatScreen itself). Tapping it opens the chat; it hides itself again
/// after a few seconds either way.
class _UnreadToast extends StatefulWidget {
  const _UnreadToast({
    required this.coupleId,
    required this.myUid,
    required this.partnerId,
    required this.chatOpen,
    required this.onTap,
  });

  final String coupleId;
  final String myUid;
  final String partnerId;
  final ValueNotifier<bool> chatOpen;
  final VoidCallback onTap;

  @override
  State<_UnreadToast> createState() => _UnreadToastState();
}

class _UnreadToastState extends State<_UnreadToast> {
  StreamSubscription<List<Message>>? _sub;
  Timer? _hideTimer;
  String? _senderName;
  String _preview = '';
  bool _visible = false;
  DateTime? _lastSeenAt;
  bool _isFirstSnapshot = true;

  @override
  void initState() {
    super.initState();
    _sub = watchMessages(widget.coupleId).listen(_onMessages);
  }

  @override
  void dispose() {
    _sub?.cancel();
    _hideTimer?.cancel();
    super.dispose();
  }

  void _onMessages(List<Message> messages) {
    if (messages.isEmpty) return;
    final latest = messages.first;

    // The first snapshot is the chat's existing history, not a new arrival
    // — just record its timestamp as the baseline without toasting.
    if (_isFirstSnapshot) {
      _isFirstSnapshot = false;
      _lastSeenAt = latest.createdAt;
      return;
    }

    final createdAt = latest.createdAt;
    final isNewFromPartner = latest.senderId == widget.partnerId &&
        createdAt != null &&
        (_lastSeenAt == null || createdAt.isAfter(_lastSeenAt!));
    _lastSeenAt = createdAt ?? _lastSeenAt;

    if (isNewFromPartner && !widget.chatOpen.value) {
      _showToast(latest.text);
    }
  }

  Future<void> _showToast(String text) async {
    var name = _senderName;
    if (name == null) {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.partnerId).get();
      name = (doc.data()?['displayName'] as String?) ?? 'شريكك';
      _senderName = name;
    }
    if (!mounted) return;
    setState(() {
      _preview = text;
      _visible = true;
    });
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 4), () {
      if (mounted) setState(() => _visible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_visible,
      child: AnimatedSlide(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        offset: _visible ? Offset.zero : const Offset(0, -1.4),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: _visible ? 1 : 0,
          child: GestureDetector(
            onTap: () {
              setState(() => _visible = false);
              widget.onTap();
            },
            child: Container(
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF211A29),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const Text('💌', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _senderName ?? 'شريكك',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _preview,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF9C8FAE), fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
