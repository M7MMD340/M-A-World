import 'package:cloud_firestore/cloud_firestore.dart';

/// Live position sharing between the two partners: each device writes its
/// own avatar's position into `couples/{coupleId}/presence/{uid}` on a
/// short interval, and watches the partner's document to move their
/// avatar smoothly on screen.
Stream<Map<String, dynamic>?> watchPresence(String coupleId, String uid) {
  return FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .collection('presence')
      .doc(uid)
      .snapshots()
      .map((doc) => doc.data());
}

Future<void> writePresence(String coupleId, String uid, double x, double y) {
  return FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .collection('presence')
      .doc(uid)
      .set({'x': x, 'y': y, 'updatedAt': FieldValue.serverTimestamp()});
}
