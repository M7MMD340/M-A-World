import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.coupleId,
    this.outfitColor,
    this.gender,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? coupleId;
  final String? outfitColor;

  /// 'boy' or 'girl' — picked at signup. Falls back to 'boy' for accounts
  /// created before this existed.
  final String? gender;

  String get characterAsset => gender == 'girl' ? 'girl' : 'boy';

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      displayName: (data['displayName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      coupleId: data['coupleId'] as String?,
      outfitColor: data['outfitColor'] as String?,
      gender: data['gender'] as String?,
    );
  }
}
