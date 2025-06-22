// ---- lib/src/pages/dev_tool_page.dart ----

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class DevToolPage extends StatefulWidget {
  const DevToolPage({super.key});

  @override
  State<DevToolPage> createState() => _DevToolPageState();
}

class _DevToolPageState extends State<DevToolPage> {
  bool _isLoading = false;
  String _resultMessage = '';

  // --- ระบุอีเมลของ Admin ที่นี่ ---
  final String adminEmail = "im_ake_@hotmail.com";
  // ---------------------------------

  Future<void> _addAdminRole() async {
    setState(() {
      _isLoading = true;
      _resultMessage = 'กำลังดำเนินการ...';
    });

    try {
      final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-southeast1')
          .httpsCallable('addAdminRole');

      // ส่งอีเมลที่กำหนดไว้ไปให้ฟังก์ชันโดยตรง
      final result = await callable.call<Map<String, dynamic>>({
        'email': adminEmail,
      });

      setState(() {
        _resultMessage = result.data['message'] ?? 'สำเร็จ!';
      });

    } on FirebaseFunctionsException catch (e) {
      setState(() {
        _resultMessage = 'เกิดข้อผิดพลาด: ${e.code} - ${e.message}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dev Tool'),
        backgroundColor: Colors.indigo[700],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.admin_panel_settings, size: 64, color: Colors.indigo),
              const SizedBox(height: 24),
              const Text(
                'เครื่องมือแต่งตั้ง Admin',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Text(
                'เมื่อกดปุ่มด้านล่าง ระบบจะมอบสิทธิ์ Admin ให้กับอีเมล:\n$adminEmail',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 32),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                ElevatedButton.icon(
                  icon: const Icon(Icons.verified_user),
                  label: const Text('ยืนยันการมอบสิทธิ์ Admin'),
                  onPressed: _addAdminRole,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(fontSize: 16)
                  ),
                ),
              const SizedBox(height: 32),
              if (_resultMessage.isNotEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _resultMessage.startsWith('เกิดข้อผิดพลาด') ? Colors.red[50] : Colors.green[50],
                    borderRadius: BorderRadius.circular(8)
                  ),
                  child: Text(
                    _resultMessage,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _resultMessage.startsWith('เกิดข้อผิดพลาด') ? Colors.red[800] : Colors.green[800],
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}