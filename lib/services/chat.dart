import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message.dart';
import '../models/sticker_catalog.dart';

/// Newest first (for a reversed chat ListView), capped at the most recent
/// 200 messages — plenty for a two-person chat without an unbounded read.
Stream<List<Message>> watchMessages(String coupleId) {
  return FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots()
      .map((snap) => snap.docs.map(Message.fromDoc).toList());
}

Future<void> sendMessage(
  String coupleId,
  String senderId,
  String text, {
  Message? replyTo,
}) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return Future.value();
  return FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('messages').add({
    'senderId': senderId,
    'text': trimmed,
    'createdAt': FieldValue.serverTimestamp(),
    ..._replyFields(replyTo),
  });
}

Future<void> sendSticker(
  String coupleId,
  String senderId,
  String stickerKey, {
  Message? replyTo,
}) {
  return FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('messages').add({
    'senderId': senderId,
    'text': '',
    'stickerKey': stickerKey,
    'createdAt': FieldValue.serverTimestamp(),
    ..._replyFields(replyTo),
  });
}

Map<String, dynamic> _replyFields(Message? replyTo) {
  if (replyTo == null) return const {};
  return {
    'replyToId': replyTo.id,
    'replyToSenderId': replyTo.senderId,
    'replyToPreview': replyTo.isSticker ? (stickerCatalog[replyTo.stickerKey] ?? 'ملصق') : replyTo.text,
  };
}

Future<void> deleteMessage(String coupleId, String messageId) {
  return FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .collection('messages')
      .doc(messageId)
      .delete();
}

/// Sets [uid]'s reaction on a message, or clears it if they tap the same
/// emoji again — at most one reaction per person per message.
Future<void> toggleReaction(String coupleId, Message message, String uid, String emoji) {
  final ref = FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('messages').doc(message.id);
  if (message.reactions[uid] == emoji) {
    return ref.update({'reactions.$uid': FieldValue.delete()});
  }
  return ref.set({
    'reactions': {uid: emoji},
  }, SetOptions(merge: true));
}

/// Stamps "now" as the moment [uid] last saw the chat — read by both the
/// unread badge on the partner's avatar and the incoming-message toast.
Future<void> markRead(String coupleId, String uid) {
  return FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .collection('reads')
      .doc(uid)
      .set({'lastReadAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
}

Stream<DateTime?> watchLastRead(String coupleId, String uid) {
  return FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .collection('reads')
      .doc(uid)
      .snapshots()
      .map((doc) => (doc.data()?['lastReadAt'] as Timestamp?)?.toDate());
}
