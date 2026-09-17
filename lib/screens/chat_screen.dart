import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/message.dart';
import '../models/sticker_catalog.dart';
import '../services/chat.dart';
import '../services/presence.dart';
import '../services/typing.dart';

const _defaultBubbleColor = Color(0xFFFF3D77);
const _defaultTextColor = Colors.white;
const _partnerBubbleColorFallback = Color(0xFF211A29);
const _defaultWallpaper = 'default';

const _bubbleColorOptions = <Color>[
  _defaultBubbleColor,
  Color(0xFF7B61FF),
  Color(0xFF2DD4BF),
  Color(0xFFFFA94D),
  Color(0xFF4DA6FF),
  Color(0xFFFF6B6B),
];

const _textColorOptions = <Color>[
  _defaultTextColor,
  Color(0xFF15111A),
  Color(0xFFFFF3D9),
];

const _wallpapers = <String, List<Color>>{
  'default': [Color(0xFF241A33), Color(0xFF120D19)],
  'sunset': [Color(0xFF4A1F52), Color(0xFF7B1E4A)],
  'ocean': [Color(0xFF0B2340), Color(0xFF12586A)],
  'forest': [Color(0xFF203A26), Color(0xFF13291A)],
};

const _wallpaperLabels = <String, String>{
  'default': 'داكن',
  'sunset': 'غروب',
  'ocean': 'محيط',
  'forest': 'غابة',
};

/// A faint scattered-hearts texture drawn over the wallpaper gradient —
/// cheap (no image asset) but reads as far less flat/plain than a solid
/// color block.
class _HeartPatternPainter extends CustomPainter {
  const _HeartPatternPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.035);
    const step = 64.0;
    var row = 0;
    for (double y = -step; y < size.height + step; y += step) {
      final offsetX = (row.isEven ? 0.0 : step / 2);
      for (double x = -step; x < size.width + step; x += step) {
        _drawHeart(canvas, Offset(x + offsetX, y), 7, paint);
      }
      row++;
    }
  }

  void _drawHeart(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path()
      ..moveTo(center.dx, center.dy + size * 0.6)
      ..cubicTo(
        center.dx - size * 1.3, center.dy - size * 0.4,
        center.dx - size * 0.4, center.dy - size * 1.2,
        center.dx, center.dy - size * 0.3,
      )
      ..cubicTo(
        center.dx + size * 0.4, center.dy - size * 1.2,
        center.dx + size * 1.3, center.dy - size * 0.4,
        center.dx, center.dy + size * 0.6,
      )
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A gentle slide-up + fade instead of the default side slide — feels like
/// the chat opens out of the character you just tapped.
Route<T> buildChatRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class ChatScreen extends StatefulWidget {
  const ChatScreen({
    super.key,
    required this.coupleId,
    required this.myUid,
    required this.partnerId,
  });

  final String coupleId;
  final String myUid;
  final String partnerId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  bool _sending = false;

  String? _partnerName;
  String _partnerAsset = 'boy';
  bool _partnerOnline = false;
  bool _partnerTyping = false;
  DateTime? _partnerLastRead;
  Color _partnerBubbleColor = _partnerBubbleColorFallback;
  Color _myBubbleColor = _defaultBubbleColor;
  Color _myTextColor = _defaultTextColor;
  String _wallpaperKey = _defaultWallpaper;

  bool _iAmTyping = false;
  Timer? _typingStopTimer;

  StreamSubscription<Map<String, dynamic>?>? _presenceSub;
  StreamSubscription<bool>? _typingSub;
  StreamSubscription<DateTime?>? _lastReadSub;

  @override
  void initState() {
    super.initState();
    markRead(widget.coupleId, widget.myUid);
    _loadPrefs();
    _controller.addListener(_onTextChanged);
    _presenceSub = watchPresence(widget.coupleId, widget.partnerId).listen((data) {
      final updatedAt = (data?['updatedAt'] as Timestamp?)?.toDate();
      final online = updatedAt != null && DateTime.now().difference(updatedAt) < const Duration(seconds: 8);
      if (mounted) setState(() => _partnerOnline = online);
    });
    _typingSub = watchTyping(widget.coupleId, widget.partnerId).listen((typing) {
      if (mounted) setState(() => _partnerTyping = typing);
    });
    _lastReadSub = watchLastRead(widget.coupleId, widget.partnerId).listen((lastRead) {
      if (mounted) setState(() => _partnerLastRead = lastRead);
    });
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    _typingStopTimer?.cancel();
    if (hasText) {
      if (!_iAmTyping) {
        _iAmTyping = true;
        setTyping(widget.coupleId, widget.myUid, true);
      }
      _typingStopTimer = Timer(const Duration(seconds: 3), () {
        _iAmTyping = false;
        setTyping(widget.coupleId, widget.myUid, false);
      });
    } else if (_iAmTyping) {
      _iAmTyping = false;
      setTyping(widget.coupleId, widget.myUid, false);
    }
  }

  @override
  void dispose() {
    // Anything that arrived while we were actively looking at the chat
    // counts as read too, once we leave.
    markRead(widget.coupleId, widget.myUid);
    if (_iAmTyping) setTyping(widget.coupleId, widget.myUid, false);
    _typingStopTimer?.cancel();
    _presenceSub?.cancel();
    _typingSub?.cancel();
    _lastReadSub?.cancel();
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final results = await Future.wait([
      FirebaseFirestore.instance.collection('users').doc(widget.myUid).get(),
      FirebaseFirestore.instance.collection('users').doc(widget.partnerId).get(),
    ]);
    if (!mounted) return;
    final my = results[0].data();
    final partner = results[1].data();
    setState(() {
      _myBubbleColor = _colorFromInt(my?['chatBubbleColor'] as int?) ?? _defaultBubbleColor;
      _myTextColor = _colorFromInt(my?['chatTextColor'] as int?) ?? _defaultTextColor;
      _wallpaperKey = (my?['chatWallpaper'] as String?) ?? _defaultWallpaper;
      _partnerName = partner?['displayName'] as String?;
      _partnerAsset = (partner?['gender'] as String?) == 'girl' ? 'girl' : 'boy';
      _partnerBubbleColor = _colorFromInt(partner?['chatBubbleColor'] as int?) ?? _partnerBubbleColorFallback;
    });
  }

  Color? _colorFromInt(int? value) => value == null ? null : Color(value);

  Future<void> _savePrefs({Color? bubbleColor, Color? textColor, String? wallpaper}) async {
    setState(() {
      if (bubbleColor != null) _myBubbleColor = bubbleColor;
      if (textColor != null) _myTextColor = textColor;
      if (wallpaper != null) _wallpaperKey = wallpaper;
    });
    await FirebaseFirestore.instance.collection('users').doc(widget.myUid).set({
      'chatBubbleColor': ?bubbleColor?.toARGB32(),
      'chatTextColor': ?textColor?.toARGB32(),
      'chatWallpaper': ?wallpaper,
    }, SetOptions(merge: true));
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty || _sending) return;
    setState(() => _sending = true);
    _controller.clear();
    try {
      await sendMessage(widget.coupleId, widget.myUid, text);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _sendSticker(String key) async {
    Navigator.of(context).pop();
    await sendSticker(widget.coupleId, widget.myUid, key);
  }

  void _openCustomizeSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B1522),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => _CustomizeSheet(
        bubbleColor: _myBubbleColor,
        textColor: _myTextColor,
        wallpaperKey: _wallpaperKey,
        onBubbleColor: (c) => _savePrefs(bubbleColor: c),
        onTextColor: (c) => _savePrefs(textColor: c),
        onWallpaper: (w) => _savePrefs(wallpaper: w),
      ),
    );
  }

  void _openStickerPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1B1522),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => _StickerPicker(onPick: _sendSticker),
    );
  }

  @override
  Widget build(BuildContext context) {
    final wallpaperColors = _wallpapers[_wallpaperKey] ?? _wallpapers[_defaultWallpaper]!;
    return Scaffold(
      backgroundColor: wallpaperColors.first,
      appBar: AppBar(
        backgroundColor: wallpaperColors.first,
        foregroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                ClipOval(
                  child: Container(
                    width: 36,
                    height: 36,
                    color: const Color(0xFF211A29),
                    child: Image.asset(
                      'assets/images/characters/$_partnerAsset.png',
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                    ),
                  ),
                ),
                if (_partnerOnline)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80),
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF15111A), width: 2),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _partnerName ?? 'رسائلنا',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    _partnerTyping ? 'يكتب الآن...' : (_partnerOnline ? 'متصل الآن' : ' '),
                    style: TextStyle(
                      fontSize: 11,
                      color: _partnerTyping ? const Color(0xFFFFA94D) : const Color(0xFF4ADE80),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _openCustomizeSheet,
            icon: const Icon(Icons.palette_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: wallpaperColors,
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(child: CustomPaint(painter: const _HeartPatternPainter())),
              _buildChatColumn(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatColumn() {
    return Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Message>>(
                  stream: watchMessages(widget.coupleId),
                  builder: (context, snap) {
                    final messages = snap.data ?? const <Message>[];
                    if (!snap.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(color: Color(0xFFFF3D77)),
                      );
                    }
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'ابدأ أول رسالة 💌',
                          style: TextStyle(color: Color(0xFF9C8FAE)),
                        ),
                      );
                    }
                    return ListView.builder(
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMine = message.senderId == widget.myUid;
                        final showDayDivider = index == messages.length - 1 ||
                            !_isSameDay(message.createdAt, messages[index + 1].createdAt);
                        // ListView is reversed (newest at the bottom), so a
                        // later item in this list renders ABOVE an earlier
                        // one — the divider must come first in the Column to
                        // land above that day's oldest message, not below it.
                        final isRead = isMine &&
                            message.createdAt != null &&
                            _partnerLastRead != null &&
                            !_partnerLastRead!.isBefore(message.createdAt!);
                        return Column(
                          key: ValueKey(message.id),
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (showDayDivider) _DayDivider(date: message.createdAt),
                            _Bubble(
                              message: message,
                              isMine: isMine,
                              isRead: isRead,
                              bubbleColor: isMine ? _myBubbleColor : _partnerBubbleColor,
                              textColor: isMine ? _myTextColor : Colors.white,
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              ),
              if (_partnerTyping)
                const Padding(
                  padding: EdgeInsets.only(left: 14, bottom: 4),
                  child: Align(alignment: Alignment.centerLeft, child: _TypingBubble()),
                ),
              _Composer(
                controller: _controller,
                sending: _sending,
                onSend: _send,
                onSticker: _openStickerPicker,
              ),
      ],
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _Bubble extends StatefulWidget {
  const _Bubble({
    required this.message,
    required this.isMine,
    required this.isRead,
    required this.bubbleColor,
    required this.textColor,
  });

  final Message message;
  final bool isMine;
  final bool isRead;
  final Color bubbleColor;
  final Color textColor;

  @override
  State<_Bubble> createState() => _BubbleState();
}

class _BubbleState extends State<_Bubble> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 260),
  )..forward();
  late final _fade = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
  late final _slide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero).animate(_fade);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final message = widget.message;
    final isMine = widget.isMine;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Align(
          alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
          child: message.isSticker ? _stickerContent(message) : _textContent(context, message, isMine),
        ),
      ),
    );
  }

  Widget _stickerContent(Message message) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: widget.isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Image.asset(stickerAssetPath(message.stickerKey!), height: 96),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 10),
              ),
              _receipt(Colors.white.withValues(alpha: 0.55)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _textContent(BuildContext context, Message message, bool isMine) {
    return Container(
      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(widget.bubbleColor, Colors.white, 0.12)!,
            Color.lerp(widget.bubbleColor, Colors.black, 0.10)!,
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMine ? 18 : 4),
          bottomRight: Radius.circular(isMine ? 4 : 18),
        ),
        boxShadow: [
          BoxShadow(color: widget.bubbleColor.withValues(alpha: 0.35), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message.text, style: TextStyle(color: widget.textColor, fontSize: 15)),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Text(
                _formatTime(message.createdAt),
                style: TextStyle(
                  color: widget.textColor.withValues(alpha: 0.65),
                  fontSize: 10,
                ),
              ),
              _receipt(widget.textColor.withValues(alpha: 0.65)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _receipt(Color tint) {
    if (!widget.isMine) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(left: 3),
      child: Icon(
        widget.isRead ? Icons.done_all_rounded : Icons.done_rounded,
        size: 13,
        color: widget.isRead ? const Color(0xFF4DA6FF) : tint,
      ),
    );
  }

  String _formatTime(DateTime? dt) {
    if (dt == null) return '...';
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'ص' : 'م';
    return '$hour:$minute $period';
  }
}

/// Three softly bouncing dots in a small bubble — the classic "typing..."
/// indicator, shown above the composer while the partner is writing.
class _TypingBubble extends StatefulWidget {
  const _TypingBubble();

  @override
  State<_TypingBubble> createState() => _TypingBubbleState();
}

class _TypingBubbleState extends State<_TypingBubble> with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF211A29),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
          bottomRight: Radius.circular(16),
          bottomLeft: Radius.circular(4),
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 8, offset: const Offset(0, 3)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final t = (_controller.value + i * 0.2) % 1.0;
              final bounce = -4 * (1 - (2 * t - 1).abs());
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Transform.translate(
                  offset: Offset(0, bounce),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(color: Color(0xFF9C8FAE), shape: BoxShape.circle),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}

class _DayDivider extends StatelessWidget {
  const _DayDivider({required this.date});

  final DateTime? date;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.28),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _label(date),
            style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
          ),
        ),
      ),
    );
  }

  String _label(DateTime? date) {
    if (date == null) return '...';
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'اليوم';
    if (diff == 1) return 'أمس';
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
    required this.onSticker,
  });

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;
  final VoidCallback onSticker;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: onSticker,
                    icon: const Icon(Icons.emoji_emotions_rounded, color: Color(0xFFFFA94D)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      onSubmitted: (_) => onSend(),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'اكتب رسالة...',
                        hintStyle: TextStyle(color: Color(0xFF9C8FAE)),
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF6B9D), Color(0xFFFF3D77)],
              ),
              boxShadow: [
                BoxShadow(color: const Color(0xFFFF3D77).withValues(alpha: 0.45), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: sending ? null : onSend,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: sending
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StickerPicker extends StatelessWidget {
  const _StickerPicker({required this.onPick});

  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ملصقات',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: stickerCatalog.entries.map((entry) {
                return GestureDetector(
                  onTap: () => onPick(entry.key),
                  child: Column(
                    children: [
                      Container(
                        width: 72,
                        height: 72,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF211A29),
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Image.asset(stickerAssetPath(entry.key), fit: BoxFit.contain),
                      ),
                      const SizedBox(height: 4),
                      Text(entry.value, style: const TextStyle(color: Color(0xFF9C8FAE), fontSize: 11)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

class _CustomizeSheet extends StatefulWidget {
  const _CustomizeSheet({
    required this.bubbleColor,
    required this.textColor,
    required this.wallpaperKey,
    required this.onBubbleColor,
    required this.onTextColor,
    required this.onWallpaper,
  });

  final Color bubbleColor;
  final Color textColor;
  final String wallpaperKey;
  final ValueChanged<Color> onBubbleColor;
  final ValueChanged<Color> onTextColor;
  final ValueChanged<String> onWallpaper;

  @override
  State<_CustomizeSheet> createState() => _CustomizeSheetState();
}

class _CustomizeSheetState extends State<_CustomizeSheet> {
  late Color _bubbleColor = widget.bubbleColor;
  late Color _textColor = widget.textColor;
  late String _wallpaperKey = widget.wallpaperKey;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'تخصيص المحادثة',
              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 20),
            _sectionLabel('لون فقاعتك'),
            const SizedBox(height: 10),
            _colorSwatches(_bubbleColorOptions, _bubbleColor, (c) {
              setState(() => _bubbleColor = c);
              widget.onBubbleColor(c);
            }),
            const SizedBox(height: 20),
            _sectionLabel('لون خط رسائلك'),
            const SizedBox(height: 10),
            _colorSwatches(_textColorOptions, _textColor, (c) {
              setState(() => _textColor = c);
              widget.onTextColor(c);
            }),
            const SizedBox(height: 20),
            _sectionLabel('خلفية المحادثة'),
            const SizedBox(height: 10),
            _wallpaperSwatches(_wallpaperKey, (w) {
              setState(() => _wallpaperKey = w);
              widget.onWallpaper(w);
            }),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(color: Color(0xFF9C8FAE), fontSize: 12, fontWeight: FontWeight.w700),
      );

  Widget _colorSwatches(List<Color> options, Color selected, ValueChanged<Color> onSelect) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: options.map((color) {
        final isSelected = color.toARGB32() == selected.toARGB32();
        return GestureDetector(
          onTap: () => onSelect(color),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 6, offset: const Offset(0, 2)),
              ],
            ),
            child: isSelected
                ? Icon(Icons.check, color: color.computeLuminance() > 0.5 ? Colors.black : Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _wallpaperSwatches(String selectedKey, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: _wallpapers.entries.map((entry) {
        final isSelected = entry.key == selectedKey;
        return GestureDetector(
          onTap: () => onSelect(entry.key),
          child: Column(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: entry.value,
                  ),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? Colors.white : Colors.transparent,
                    width: 3,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _wallpaperLabels[entry.key] ?? entry.key,
                style: const TextStyle(color: Color(0xFF9C8FAE), fontSize: 11),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
