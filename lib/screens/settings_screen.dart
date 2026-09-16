import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../models/user_profile.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late String _gender;
  DateTime? _marriageDate;
  bool _saving = false;
  String? _savedMessage;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.profile.displayName);
    _age = TextEditingController(text: widget.profile.age?.toString() ?? '');
    _gender = widget.profile.gender ?? 'boy';
    _marriageDate = widget.profile.marriageDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _age.dispose();
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
      final data = <String, Object?>{
        'displayName': _name.text.trim(),
        'gender': _gender,
        'age': int.tryParse(_age.text.trim()),
      };
      if (_marriageDate != null) {
        data['marriageDate'] = Timestamp.fromDate(_marriageDate!);
      }
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.profile.uid)
          .set(data, SetOptions(merge: true));
      if (mounted) setState(() => _savedMessage = 'تم الحفظ ✓');
    } finally {
      if (mounted) setState(() => _saving = false);
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
            const Text(
              'الاسم',
              style: TextStyle(color: Color(0xFF9C8FAE), fontSize: 12, fontWeight: FontWeight.w700),
            ),
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
            const Text(
              'الجنس',
              style: TextStyle(color: Color(0xFF9C8FAE), fontSize: 12, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _genderCard('boy', 'ولد')),
                const SizedBox(width: 12),
                Expanded(child: _genderCard('girl', 'بنت')),
              ],
            ),
            const SizedBox(height: 20),
            const Text(
              'العمر',
              style: TextStyle(color: Color(0xFF9C8FAE), fontSize: 12, fontWeight: FontWeight.w700),
            ),
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
            const Text(
              'تاريخ الزواج',
              style: TextStyle(color: Color(0xFF9C8FAE), fontSize: 12, fontWeight: FontWeight.w700),
            ),
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
          ],
        ),
      ),
    );
  }

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
