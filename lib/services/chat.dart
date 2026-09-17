import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/message.dart';

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

Future<void> sendMessage(String coupleId, String senderId, String text) {
  final trimmed = text.trim();
  if (trimmed.isEmpty) return Future.value();
  return FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .collection('messages')
      .add({
    'senderId': senderId,
    'text': trimmed,
    'createdAt': FieldValue.serverTimestamp(),
  });
}

Future<void> sendSticker(String coupleId, String senderId, String stickerKey) {
  return FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .collection('messages')
      .add({
    'senderId': senderId,
    'text': '',
    'stickerKey': stickerKey,
    'createdAt': FieldValue.serverTimestamp(),
  });
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
