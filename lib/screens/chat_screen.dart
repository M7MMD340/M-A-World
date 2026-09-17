import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/message.dart';
import '../services/chat.dart';

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

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15111A),
        foregroundColor: Colors.white,
        centerTitle: true,
        title: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          future: FirebaseFirestore.instance.collection('users').doc(widget.partnerId).get(),
          builder: (context, snap) {
            final name = snap.data?.data()?['displayName'] as String?;
            return Text(name == null ? 'رسائلنا 💌' : '$name 💌');
          },
        ),
      ),
      body: SafeArea(
        child: Column(
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
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (showDayDivider) _DayDivider(date: message.createdAt),
                          _Bubble(message: message, isMine: isMine),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
            _Composer(controller: _controller, sending: _sending, onSend: _send),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message, required this.isMine});

  final Message message;
  final bool isMine;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.72),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine ? const Color(0xFFFF3D77) : const Color(0xFF211A29),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMine ? 16 : 4),
            bottomRight: Radius.circular(isMine ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(message.text, style: const TextStyle(color: Colors.white, fontSize: 15)),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.createdAt),
              textAlign: isMine ? TextAlign.left : TextAlign.right,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 10,
              ),
            ),
          ],
        ),
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
            color: const Color(0xFF211A29),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _label(date),
            style: const TextStyle(color: Color(0xFF9C8FAE), fontSize: 11, fontWeight: FontWeight.w700),
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
  const _Composer({required this.controller, required this.sending, required this.onSend});

  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: const BoxDecoration(
        color: Color(0xFF15111A),
        border: Border(top: BorderSide(color: Color(0xFF211A29), width: 1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFF211A29),
                hintText: 'اكتب رسالة...',
                hintStyle: TextStyle(color: Color(0xFF9C8FAE)),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20)), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFFFF3D77),
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
        ],
      ),
    );
  }
}
