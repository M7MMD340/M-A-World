import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/photo.dart';

/// Newest first, capped at the most recent 100 — the couple's own shared
/// photo stream lives entirely as base64 inside Firestore documents (no
/// Firebase Storage, to stay on the free Spark plan), so this also caps how
/// much data a single load pulls down.
Stream<List<Photo>> watchPhotos(String coupleId) {
  return FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .collection('photos')
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((snap) => snap.docs.map(Photo.fromDoc).toList());
}

/// [imageBytes] should already be a compressed, reasonably small JPEG (see
/// [CameraScreen]'s use of image_picker's own maxWidth/imageQuality) —
/// Firestore documents cap out at 1MiB, and base64 adds ~33% overhead.
Future<void> addPhoto(String coupleId, String senderId, List<int> imageBytes) {
  return FirebaseFirestore.instance.collection('couples').doc(coupleId).collection('photos').add({
    'senderId': senderId,
    'imageBase64': base64Encode(imageBytes),
    'createdAt': FieldValue.serverTimestamp(),
  });
}

Future<void> deletePhoto(String coupleId, String photoId) {
  return FirebaseFirestore.instance
      .collection('couples')
      .doc(coupleId)
      .collection('photos')
      .doc(photoId)
      .delete();
}
