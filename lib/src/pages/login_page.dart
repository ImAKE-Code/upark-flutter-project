// ---- lib/src/pages/login_page.dart (ฉบับแก้ไข) ----

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LoginPage extends StatefulWidget {
  final bool performAnonymousSignIn;
  const LoginPage({super.key, this.performAnonymousSignIn = false});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.performAnonymousSignIn) {
      _signInAnonymously();
    }
  }

  Future<void> _signInAnonymously() async {
    try {
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      debugPrint("Anonymous sign-in failed: $e");
    }
  }

  Future<void> _login() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // --- 2. เพิ่มการนำทางกลับไปหน้าหลักหลังล็อกอินสำเร็จ ---
      // เราใช้ pushNamedAndRemoveUntil เพื่อล้างหน้าเก่าๆ ออกไปทั้งหมด แล้วไปที่หน้าหลัก (/)
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
      }

    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(e.message ?? "เกิดข้อผิดพลาดในการเข้าสู่ระบบ"),
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
      appBar: AppBar(title: const Text('เข้าสู่ระบบ UPark')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('ยินดีต้อนรับกลับมา',
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
                // --- 1. ปรับปรุงปุ่มให้เต็มความกว้างและสวยงาม ---
                SizedBox(
                  width: double.infinity, // ทำให้ปุ่มยืดเต็มความกว้าง
                  child: ElevatedButton(
                    onPressed: _login,
                    // ใช้ style จาก Theme ที่เราตั้งไว้ใน main.dart
                    style: Theme.of(context).elevatedButtonTheme.style,
                    child: const Text('เข้าสู่ระบบ'),
                  ),
                ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                child: const Text('ยังไม่มีบัญชี? สมัครสมาชิก'),
              )
            ],
          ),
        ),
      ),
    );
  }
}