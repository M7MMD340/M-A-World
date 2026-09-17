import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';

const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

String _generateInviteCode() {
  final rand = Random.secure();
  return List.generate(6, (_) => _codeChars[rand.nextInt(_codeChars.length)]).join();
}

/// Creates a brand new couple with the current user as its sole member and
/// links it to their profile. Returns the new couple id.
Future<String> createCouple(String uid) async {
  final code = _generateInviteCode();
  final coupleRef = FirebaseFirestore.instance.collection('couples').doc();
  await coupleRef.set({
    'inviteCode': code,
    'members': [uid],
    'createdAt': FieldValue.serverTimestamp(),
  });
  await FirebaseFirestore.instance.collection('users').doc(uid).set(
    {'coupleId': coupleRef.id},
    SetOptions(merge: true),
  );
  return coupleRef.id;
}

/// Looks up a couple by its invite code and adds the current user as its
/// second member. Returns the couple id. Throws a [StateError] with an
/// Arabic message on failure.
Future<String> joinCoupleByCode(String uid, String inviteCode) async {
  final query = await FirebaseFirestore.instance
      .collection('couples')
      .where('inviteCode', isEqualTo: inviteCode.trim().toUpperCase())
      .limit(1)
      .get();

  if (query.docs.isEmpty) {
    throw StateError('رمز الدعوة غير صحيح.');
  }

  final coupleDoc = query.docs.first;
  final members = (coupleDoc.data()['members'] as List?)?.cast<String>() ?? const [];

  if (members.contains(uid)) {
    throw StateError('أنت بالفعل جزء من هذا الحساب.');
  }
  if (members.length >= 2) {
    throw StateError('هذا الرمز مستخدم بالفعل من طرفين.');
  }

  await coupleDoc.reference.update({
    'members': FieldValue.arrayUnion([uid]),
  });
  await FirebaseFirestore.instance.collection('users').doc(uid).set(
    {'coupleId': coupleDoc.id},
    SetOptions(merge: true),
  );
  return coupleDoc.id;
}

/// Detaches the current user from a couple: removes them from the couple's
/// member list and clears the link on their own profile. Only touches the
/// caller's own user doc (security rules forbid writing another user's),
/// so each partner unlinks independently from their own Settings screen.
Future<void> unlinkCouple(String uid, String coupleId) async {
  await FirebaseFirestore.instance.collection('couples').doc(coupleId).update({
    'members': FieldValue.arrayRemove([uid]),
  });
  await FirebaseFirestore.instance.collection('users').doc(uid).update({
    'coupleId': FieldValue.delete(),
  });
}
