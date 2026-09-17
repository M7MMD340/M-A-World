import 'package:cloud_firestore/cloud_firestore.dart';

class Message {
  Message({
    required this.id,
    required this.senderId,
    required this.text,
    required this.createdAt,
    this.stickerKey,
    this.replyToId,
    this.replyToPreview,
    this.replyToSenderId,
    this.reactions = const {},
  });

  final String id;
  final String senderId;
  final String text;

  /// Null for the brief moment before the server timestamp resolves.
  final DateTime? createdAt;

  /// Set only for sticker messages — see [StickerCatalog]. When set, [text]
  /// is empty and the bubble renders the sticker instead of plain text.
  final String? stickerKey;

  /// Denormalized quote of the message this one replies to, if any — kept
  /// as a copy on the reply itself so rendering it never needs an extra
  /// Firestore read (and still shows something if the original is later
  /// deleted).
  final String? replyToId;
  final String? replyToPreview;
  final String? replyToSenderId;

  /// uid -> emoji. At most one reaction per person, toggled off by sending
  /// the same emoji again.
  final Map<String, String> reactions;

  bool get isSticker => stickerKey != null;
  bool get isReply => replyToId != null;

  factory Message.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    return Message(
      id: doc.id,
      senderId: (data['senderId'] as String?) ?? '',
      text: (data['text'] as String?) ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      stickerKey: data['stickerKey'] as String?,
      replyToId: data['replyToId'] as String?,
      replyToPreview: data['replyToPreview'] as String?,
      replyToSenderId: data['replyToSenderId'] as String?,
      reactions: (data['reactions'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v as String)) ?? const {},
    );
  }
}
