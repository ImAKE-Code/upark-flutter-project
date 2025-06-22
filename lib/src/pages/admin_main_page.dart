// ---- lib/src/pages/admin_main_page.dart (ฉบับแสดงอีเมล) ----
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_booking_list_page.dart';
import 'admin_dashboard_page.dart';
import 'admin_daily_schedule_page.dart';
import 'admin_expense_page.dart';
import 'admin_faq_management_page.dart';
import 'admin_promo_codes_page.dart';
import 'admin_role_management_page.dart';
import 'admin_settings_page.dart';
import 'admin_debug_page.dart';

class AdminMainPage extends StatefulWidget {
  const AdminMainPage({super.key});
  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> {
  int _selectedIndex = 0;

  static final List<Widget> _adminPages = <Widget>[
    const AdminDashboardPage(),
    const AdminBookingListPage(),
    const AdminDailySchedulePage(),
    const AdminExpensePage(),
    const AdminPromoCodesPage(),
    const AdminRoleManagementPage(), // หน้าจัดการสิทธิ์
    const AdminFaqManagementPage(),
    const AdminSettingsPage(),
  ];

  static const List<String> _pageTitles = <String>[
    'แดชบอร์ด',
    'รายการจอง',
    'ตารางงานรายวัน',
    'บันทึกรายจ่าย',
    'จัดการโปรโมชั่น',
    'จัดการสิทธิ์',
    'จัดการ FAQ',
    'ตั้งค่าระบบ',
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: Text(_pageTitles.elementAt(_selectedIndex)),
        actions: [
          // --- เพิ่มการแสดงอีเมลของ Admin ---
          if (user != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(user.email ?? 'Admin',
                    style: TextStyle(color: Colors.grey[600])),
              ),
            ),
        ],
      ),
      body: _adminPages.elementAt(_selectedIndex),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
              icon: Icon(Icons.dashboard), label: 'แดชบอร์ด'),
          BottomNavigationBarItem(
              icon: Icon(Icons.list_alt), label: 'รายการจอง'),
          BottomNavigationBarItem(
              icon: Icon(Icons.calendar_today), label: 'ตารางงาน'),
          BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long), label: 'รายจ่าย'),
          BottomNavigationBarItem(icon: Icon(Icons.sell), label: 'โปรโมชั่น'),
          BottomNavigationBarItem(
              icon: Icon(Icons.manage_accounts), label: 'สิทธิ์'),
          BottomNavigationBarItem(icon: Icon(Icons.quiz), label: 'FAQ'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'ตั้งค่า'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        backgroundColor: Colors.white,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        type: BottomNavigationBarType.fixed,
        elevation: 4,
      ),
    );
  }
}
