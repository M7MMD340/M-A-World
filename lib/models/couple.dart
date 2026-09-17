import 'package:cloud_firestore/cloud_firestore.dart';

class Couple {
  Couple({
    required this.id,
    required this.inviteCode,
    required this.members,
    this.marriageDate,
  });

  final String id;
  final String inviteCode;
  final List<String> members;
  final DateTime? marriageDate;

  bool get isComplete => members.length >= 2;

  String? partnerId(String myUid) {
    for (final m in members) {
      if (m != myUid) return m;
    }
    return null;
  }

  factory Couple.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return Couple(
      id: doc.id,
      inviteCode: (data['inviteCode'] as String?) ?? '',
      members: (data['members'] as List?)?.cast<String>() ?? const [],
      marriageDate: (data['marriageDate'] as Timestamp?)?.toDate(),
    );
  }
}
