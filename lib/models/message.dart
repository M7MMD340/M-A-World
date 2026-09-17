import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.stickerKey,
  });

  final String id;
  final String senderId;
  final String text;

  /// Null for the brief moment before the server timestamp resolves.
  final DateTime? createdAt;

  /// Set only for sticker messages — see [StickerCatalog]. When set, [text]
  /// is empty and the bubble renders the sticker instead of plain text.
  final String? stickerKey;

  bool get isSticker => stickerKey != null;

  factory Message.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Message(
      id: doc.id,
      senderId: (data['senderId'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      stickerKey: data['stickerKey'] as String?,
    );
  }
}
