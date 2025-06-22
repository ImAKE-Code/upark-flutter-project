// ---- lib/src/pages/admin_role_management_page.dart ----

import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

class AdminRoleManagementPage extends StatefulWidget {
  const AdminRoleManagementPage({super.key});

  @override
  State<AdminRoleManagementPage> createState() => _AdminRoleManagementPageState();
}

class _AdminRoleManagementPageState extends State<AdminRoleManagementPage> {
  // ใช้ Future แทน Stream เพราะรายชื่อ User ไม่ได้เปลี่ยนบ่อย
  late Future<List<Map<String, dynamic>>> _usersFuture;

  @override
  void initState() {
    super.initState();
    _usersFuture = _listAllUsers();
  }

  Future<List<Map<String, dynamic>>> _listAllUsers() async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-southeast1').httpsCallable('listAllUsers');
      final result = await callable.call();
      final List<dynamic> userList = result.data['users'];
      return userList.map((user) => Map<String, dynamic>.from(user)).toList();
    } catch (e) {
      // แสดง Error ให้ User ทราบ
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดรายชื่อผู้ใช้: $e'), backgroundColor: Colors.red));
      return [];
    }
  }

  Future<void> _updateAdminRole(String email, bool isAdmin) async {
    final functionName = isAdmin ? 'addAdminRole' : 'removeAdminRole';
    try {
      final HttpsCallable callable = FirebaseFunctions.instanceFor(region: 'asia-southeast1').httpsCallable(functionName);
      await callable.call({'email': email});
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('อัปเดตสิทธิ์สำเร็จ!'), backgroundColor: Colors.green));
      // โหลดข้อมูลใหม่
      setState(() {
        _usersFuture = _listAllUsers();
      });
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการอัปเดตสิทธิ์: $e'), backgroundColor: Colors.red));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _usersFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(child: Text('ไม่สามารถโหลดข้อมูลผู้ใช้ได้'));
          }

          final users = snapshot.data!;

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              final user = users[index];
              final bool isAdmin = user['isAdmin'] ?? false;
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Icon(isAdmin ? Icons.shield : Icons.person_outline, color: isAdmin ? Colors.blue : Colors.grey),
                  title: Text(user['email'] ?? 'No Email'),
                  subtitle: Text(isAdmin ? 'Admin' : 'Customer', style: TextStyle(color: isAdmin ? Colors.blue : Colors.grey, fontWeight: FontWeight.bold)),
                  trailing: Switch(
                    value: isAdmin,
                    onChanged: (value) {
                      _updateAdminRole(user['email'], value);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}