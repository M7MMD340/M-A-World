import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  String? _error;
  bool _loading = false;
  bool _isSignup = false;

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _loading = true;
    });
    try {
      if (_isSignup) {
        if (_name.text.trim().isEmpty) {
          setState(() => _error = 'اكتب اسمك أولاً.');
          return;
        }
        if (_password.text.length < 6) {
          setState(() => _error = 'كلمة المرور لازم تكون 6 أحرف أو أكثر.');
          return;
        }
        final credential =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
          'displayName': _name.text.trim(),
          'email': _email.text.trim(),
          'coupleId': null,
          'outfitColor': '#FF3D77',
          'createdAt': FieldValue.serverTimestamp(),
        });
      } else {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _error = e.code == 'email-already-in-use'
            ? 'هذا البريد مسجّل مسبقًا، جرّب تسجيل الدخول.'
            : _isSignup
                ? 'تعذّر إنشاء الحساب. حاول مرة ثانية.'
                : 'تعذّر تسجيل الدخول، تأكد من البيانات.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF15111A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'M ♥ A',
                  style: TextStyle(
                    color: Color(0xFFFF3D77),
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 28),
                _ModeToggle(
                  isSignup: _isSignup,
                  onChanged: (v) => setState(() {
                    _isSignup = v;
                    _error = null;
                  }),
                ),
                const SizedBox(height: 20),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Color(0xFFFF6B6B)),
                      textAlign: TextAlign.center,
                    ),
                  ),
                if (_isSignup) ...[
                  TextField(
                    controller: _name,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      hintText: 'الاسم',
                      hintStyle: TextStyle(color: Color(0xFF9C8FAE)),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                TextField(
                  controller: _email,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'البريد الإلكتروني',
                    hintStyle: TextStyle(color: Color(0xFF9C8FAE)),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _password,
                  obscureText: true,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    hintText: 'كلمة المرور',
                    hintStyle: TextStyle(color: Color(0xFF9C8FAE)),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _loading ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFFF3D77),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(_isSignup ? 'إنشاء حساب' : 'دخول'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ModeToggle extends StatelessWidget {
  const _ModeToggle({required this.isSignup, required this.onChanged});

  final bool isSignup;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF211A29),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _segment(context, 'دخول', !isSignup, () => onChanged(false)),
          _segment(context, 'حساب جديد', isSignup, () => onChanged(true)),
        ],
      ),
    );
  }

  Widget _segment(
    BuildContext context,
    String label,
    bool active,
    VoidCallback onTap,
  ) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: active ? const Color(0xFFFF3D77) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: active ? Colors.white : const Color(0xFF9C8FAE),
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
