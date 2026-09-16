import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class UserProfile {
  UserProfile({
    required this.uid,
    required this.displayName,
    required this.email,
    this.coupleId,
    this.outfitColor,
  });

  final String uid;
  final String displayName;
  final String email;
  final String? coupleId;
  final String? outfitColor;

  Color get avatarColor {
    if (outfitColor == null) return const Color(0xFFFF3D77);
    final hex = outfitColor!.replaceFirst('#', '');
    return Color(int.parse('FF$hex', radix: 16));
  }

  factory UserProfile.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return UserProfile(
      uid: doc.id,
      displayName: (data['displayName'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      coupleId: data['coupleId'] as String?,
      outfitColor: data['outfitColor'] as String?,
    );
  }
}
