import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../models/couple.dart';
import '../models/user_profile.dart';
import '../services/pairing.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.profile, required this.couple});

  final UserProfile profile;
  final Couple? couple;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _joinCode;
  late String _gender;
  late String? _coupleId;
  DateTime? _marriageDate;
  bool _saving = false;
  bool _pairing = false;
  bool _unlinking = false;
  String? _savedMessage;
  String? _pairingError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.displayName);
    _age = TextEditingController(text: widget.profile.age?.toString() ?? '');
    _joinCode = TextEditingController();
    _gender = widget.profile.gender ?? 'boy';
    _coupleId = widget.couple?.id ?? widget.profile.coupleId;
    _marriageDate = widget.couple?.marriageDate ?? widget.profile.marriageDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
    _joinCode.dispose();
    super.dispose();
  }

  Future<void> _pickMarriageDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _marriageDate ?? DateTime(now.year - 1, 11, 11),
      firstDate: DateTime(1970),
      lastDate: now,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFFF3D77),
            surface: Color(0xFF211A29),
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _marriageDate = picked);
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _savedMessage = null;
    });
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.profile.uid)
          .set({
        'displayName': _name.text.trim(),
        'gender': _gender,
        'age': int.tryParse(_age.text.trim()),
      }, SetOptions(merge: true));

      if (_marriageDate != null) {
        final coupleId = _coupleId;
        if (coupleId != null) {
          await FirebaseFirestore.instance
              .collection('couples')
              .doc(coupleId)
              .set({'marriageDate': Timestamp.fromDate(_marriageDate!)}, SetOptions(merge: true));
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(widget.profile.uid)
              .set({'marriageDate': Timestamp.fromDate(_marriageDate!)}, SetOptions(merge: true));
        }
      }
      if (mounted) setState(() => _savedMessage = 'تم الحفظ ✓');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _createCouple() async {
    setState(() {
      _pairing = true;
      _pairingError = null;
    });
    try {
      final id = await createCouple(widget.profile.uid);
      if (mounted) setState(() => _coupleId = id);
    } catch (_) {
      if (mounted) setState(() => _pairingError = 'تعذّر إنشاء رمز الدعوة، حاول مرة ثانية.');
    } finally {
      if (mounted) setState(() => _pairing = false);
    }
  }

  Future<void> _joinCouple() async {
    if (_joinCode.text.trim().isEmpty) {
      setState(() => _pairingError = 'اكتب رمز الدعوة أول.');
      return;
    }
    setState(() {
      _pairing = true;
      _pairingError = null;
    });
    try {
      final id = await joinCoupleByCode(widget.profile.uid, _joinCode.text);
      if (mounted) setState(() => _coupleId = id);
    } on StateError catch (e) {
      if (mounted) setState(() => _pairingError = e.message);
    } catch (_) {
      if (mounted) setState(() => _pairingError = 'تعذّر الانضمام، تأكد من الرمز.');
    } finally {
      if (mounted) setState(() => _pairing = false);
    }
  }

  Future<void> _unlink() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF211A29),
        title: const Text('إلغاء الربط؟', style: TextStyle(color: Colors.white)),
        content: const Text(
          'ستنفصل شخصيتك عن شريكك ولن تظهرا معًا في البيت بعد الآن. يمكنكما الربط من جديد لاحقًا.',
          style: TextStyle(color: Color(0xFF9C8FAE)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('تراجع'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('إلغاء الربط', style: TextStyle(color: Color(0xFFFF6B6B))),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final coupleId = _coupleId;
    if (coupleId == null) return;
    setState(() => _unlinking = true);
    try {
      await unlinkCouple(widget.profile.uid, coupleId);
      if (mounted) setState(() => _coupleId = null);
    } finally {
      if (mounted) setState(() => _unlinking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15111A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF15111A),
        foregroundColor: Colors.white,
        title: const Text('الإعدادات'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _label('ربط الحساب'),
            const SizedBox(height: 6),
            _coupleId == null
                ? _PairingSection(
                    couple: null,
                    myUid: widget.profile.uid,
                    joinCodeController: _joinCode,
                    pairing: _pairing,
                    unlinking: _unlinking,
                    error: _pairingError,
                    onCreate: _createCouple,
                    onJoin: _joinCouple,
                    onUnlink: _unlink,
                  )
                : StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                    stream: FirebaseFirestore.instance.collection('couples').doc(_coupleId).snapshots(),
                    builder: (context, snap) {
                      final liveCouple = snap.data != null && snap.data!.exists
                          ? Couple.fromDoc(snap.data!)
                          : null;
                      return _PairingSection(
                        couple: liveCouple,
                        myUid: widget.profile.uid,
                        joinCodeController: _joinCode,
                        pairing: _pairing,
                        unlinking: _unlinking,
                        error: _pairingError,
                        onCreate: _createCouple,
                        onJoin: _joinCouple,
                        onUnlink: _unlink,
                      );
                    },
                  ),
            const SizedBox(height: 24),
            _label('الاسم'),
            const SizedBox(height: 6),
            TextField(
              controller: _name,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFF211A29),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            _label('الجنس'),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _genderCard('boy', 'ولد')),
                const SizedBox(width: 12),
                Expanded(child: _genderCard('girl', 'بنت')),
              ],
            ),
            const SizedBox(height: 20),
            _label('العمر'),
            const SizedBox(height: 6),
            TextField(
              controller: _age,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                filled: true,
                fillColor: Color(0xFF211A29),
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide.none),
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),
            _label(_coupleId != null ? 'تاريخ الزواج (مشترك)' : 'تاريخ الزواج'),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickMarriageDate,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF211A29),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.favorite, color: Color(0xFFFF3D77), size: 18),
                    const SizedBox(width: 10),
                    Text(
                      _marriageDate == null
                          ? 'اختر التاريخ'
                          : '${_marriageDate!.year}/${_marriageDate!.month.toString().padLeft(2, '0')}/${_marriageDate!.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        color: _marriageDate == null ? const Color(0xFF9C8FAE) : Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            if (_savedMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  _savedMessage!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Color(0xFF4ADE80), fontWeight: FontWeight.w700),
                ),
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFFF3D77),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('حفظ'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                  FirebaseAuth.instance.signOut();
                },
                child: const Text('تسجيل خروج', style: TextStyle(color: Color(0xFFFF6B6B))),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(color: Color(0xFF9C8FAE), fontSize: 12, fontWeight: FontWeight.w700),
      );

  Widget _genderCard(String key, String label) {
    final active = _gender == key;
    return GestureDetector(
      onTap: () => setState(() => _gender = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF211A29),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? const Color(0xFFFF3D77) : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Image.asset('assets/images/characters/$key.png', height: 64),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: active ? Colors.white : const Color(0xFF9C8FAE),
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PairingSection extends StatelessWidget {
  const _PairingSection({
    required this.couple,
    required this.myUid,
    required this.joinCodeController,
    required this.pairing,
    required this.unlinking,
    required this.error,
    required this.onCreate,
    required this.onJoin,
    required this.onUnlink,
  });

  final Couple? couple;
  final String myUid;
  final TextEditingController joinCodeController;
  final bool pairing;
  final bool unlinking;
  final String? error;
  final VoidCallback onCreate;
  final VoidCallback onJoin;
  final VoidCallback onUnlink;

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(error!, style: const TextStyle(color: Color(0xFFFF6B6B)), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          _body(context),
        ],
      );
    }
    return _body(context);
  }

  Widget _body(BuildContext context) {
    final c = couple;

    if (c != null && c.isComplete) {
      final partnerId = c.partnerId(myUid);
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF211A29),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.favorite, color: Color(0xFFFF3D77)),
                const SizedBox(width: 10),
                Expanded(
                  child: partnerId == null
                      ? const Text('مرتبط ✓', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700))
                      : FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          future: FirebaseFirestore.instance.collection('users').doc(partnerId).get(),
                          builder: (context, snap) {
                            final name = snap.data?.data()?['displayName'] as String?;
                            return Text(
                              name == null ? 'مرتبط ✓' : 'مرتبط مع $name ✓',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            );
                          },
                        ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: unlinking ? null : onUnlink,
                child: unlinking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6B6B)),
                      )
                    : const Text('إلغاء الربط', style: TextStyle(color: Color(0xFFFF6B6B))),
              ),
            ),
          ],
        ),
      );
    }

    if (c != null && !c.isComplete) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF211A29),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('بانتظار انضمام شريكك — أعطه هذا الرمز:', style: TextStyle(color: Color(0xFF9C8FAE))),
            const SizedBox(height: 8),
            Text(
              c.inviteCode,
              style: const TextStyle(color: Color(0xFFFF3D77), fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 3),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: unlinking ? null : onUnlink,
                child: unlinking
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFFF6B6B)),
                      )
                    : const Text('إلغاء الدعوة', style: TextStyle(color: Color(0xFFFF6B6B))),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: pairing ? null : onCreate,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFFFF3D77)),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: const Text('إنشاء رمز دعوة جديد'),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: joinCodeController,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white),
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Color(0xFF211A29),
                  hintText: 'رمز الدعوة',
                  hintStyle: TextStyle(color: Color(0xFF9C8FAE)),
                  border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14)), borderSide: BorderSide.none),
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(width: 10),
            FilledButton(
              onPressed: pairing ? null : onJoin,
              style: FilledButton.styleFrom(backgroundColor: const Color(0xFF7B61FF)),
              child: const Text('انضمام'),
            ),
          ],
        ),
      ],
    );
  }
}
