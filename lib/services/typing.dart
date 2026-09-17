import 'package:cloud_firestore/cloud_firestore.dart';

Future<void> setTyping(String coupleId, String uid, bool typing) {
  return FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .collection('typing')
      .doc(uid)
      .set({'isTyping': typing, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
}

/// True only while [uid] is actively typing — auto-expires a few seconds
/// after their last keystroke in case their app closed without clearing
/// the flag (e.g. a crash or a killed browser tab).
Stream<bool> watchTyping(String coupleId, String uid) {
  return FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .collection('typing')
      .doc(uid)
      .snapshots()
      .map((doc) {
    final data = doc.data();
    final isTyping = data?['isTyping'] as bool? ?? false;
    final updatedAt = (data?['updatedAt'] as Timestamp?)?.toDate();
    if (!isTyping || updatedAt == null) return false;
    return DateTime.now().difference(updatedAt) < const Duration(seconds: 6);
  });
}
