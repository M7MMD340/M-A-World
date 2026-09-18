import 'package:cloud_firestore/cloud_firestore.dart';

class Photo {
  Photo({
    required this.id,
    required this.senderId,
    required this.imageBase64,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String imageBase64;

  /// Null for the brief moment before the server timestamp resolves.
  final DateTime? createdAt;

  factory Photo.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Photo(
      id: doc.id,
      senderId: (data['senderId'] as String?) ?? '',
      imageBase64: (data['imageBase64'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
    );
  }
}
