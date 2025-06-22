// ---- lib/src/pages/admin_debug_page.dart ----
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AdminDebugPage extends StatefulWidget {
  const AdminDebugPage({super.key});
  @override
  State<AdminDebugPage> createState() => _AdminDebugPageState();
}

class _AdminDebugPageState extends State<AdminDebugPage> {
  String _userClaims = "กำลังโหลด...";
  String? _userUID;
  String? _userEmail;

  @override
  void initState() {
    super.initState();
    _checkUserClaims();
  }

  Future<void> _checkUserClaims() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _userClaims = "ไม่มีผู้ใช้ล็อกอินเข้าระบบ";
      });
      return;
    }

    try {
      setState(() {
        _userUID = user.uid;
        _userEmail = user.email;
      });
      // บังคับให้รีเฟรช ID Token เพื่อดึง Custom Claims ล่าสุด
      final idTokenResult = await user.getIdTokenResult(true); 
      final claims = idTokenResult.claims;

      setState(() {
        if (claims == null || claims.isEmpty) {
          _userClaims = "ไม่พบ Custom Claims";
        } else {
          // แปลง Map เป็น String ที่อ่านง่าย
          _userClaims = claims.entries.map((e) => '${e.key}: ${e.value}').join('\n');
        }
      });

    } catch (e) {
      setState(() {
        _userClaims = "เกิดข้อผิดพลาดในการดึง Claims:\n$e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("เครื่องมือตรวจสอบสิทธิ์", style: Theme.of(context).textTheme.headlineSmall),
          const Divider(height: 24),
          const Text("ข้อมูล User ปัจจุบัน:", style: TextStyle(fontWeight: FontWeight.bold)),
          SelectableText("Email: $_userEmail"),
          SelectableText("UID: $_userUID"),
          const SizedBox(height: 16),
          const Text("Custom Claims ที่ได้รับ:", style: TextStyle(fontWeight: FontWeight.bold)),
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey[200],
            width: double.infinity,
            child: SelectableText(_userClaims),
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton(
              onPressed: _checkUserClaims,
              child: const Text('รีเฟรชข้อมูลสิทธิ์'),
            ),
          ),
        ],
      ),
    );
  }
}