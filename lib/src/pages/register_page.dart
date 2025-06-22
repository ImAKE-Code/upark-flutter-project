// ---- lib/src/pages/register_page.dart (ฉบับสมบูรณ์) ----
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _register() async {
    if (mounted) setState(() => _isLoading = true);
    try {
      final credential = EmailAuthProvider.credential(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        UserCredential userCredential =
            await user.linkWithCredential(credential);
        User? newUser = userCredential.user;
        if (newUser != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(newUser.uid)
              .set({
            'uid': newUser.uid,
            'email': newUser.email,
            'createdAt': Timestamp.now(),
          });
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('สมัครสมาชิกสำเร็จ! กรุณาเข้าสู่ระบบ')),
          );
          Navigator.pop(context);
        }
      } else {
        // Should not happen if AuthGate is working correctly
        throw Exception("ไม่พบผู้ใช้ (Anonymous User)");
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message ?? "เกิดข้อผิดพลาดในการสมัคร"),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('สมัครสมาชิก UPark')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('สร้างบัญชีใหม่',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 32),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'อีเมล'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: 'รหัสผ่าน'),
                obscureText: true,
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                SizedBox(
                  width: double.infinity, // ทำให้ปุ่มยืดเต็มความกว้าง
                  child: ElevatedButton(
                    onPressed: _register,
                    // ใช้ style จาก Theme ที่เราตั้งไว้ใน main.dart
                    style: Theme.of(context).elevatedButtonTheme.style,
                    child: const Text('สมัครสมาชิก'),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('มีบัญชีอยู่แล้ว? กลับไปเข้าสู่ระบบ'),
              )
            ],
          ),
        ),
      ),
    );
  }
}
