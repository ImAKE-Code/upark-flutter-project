// ---- lib/src/pages/admin_dashboard_page.dart (ฉบับแก้ไข) ----

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminDashboardPage extends StatelessWidget {
  const AdminDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    // กำหนดช่วงเวลาของ "วันนี้"
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));

    // --- ลบ Scaffold ที่ครอบอยู่ออก ---
    // return Scaffold( ... )

    // --- ให้ return SingleChildScrollView โดยตรง ---
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'แดชบอร์ดภาพรวม',
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            // ใช้ FutureBuilder เพื่อดึงข้อมูล Config (ทำครั้งเดียว)
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('config')
                  .doc('Nez0wZtFS8JgS9iWorp5')
                  .get(),
              builder: (context, configSnapshot) {
                // ใช้ StreamBuilder ซ้อนข้างในเพื่อดึงข้อมูลการจองแบบ Real-time
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('bookings')
                      .snapshots(),
                  builder: (context, bookingSnapshot) {
                    if (!configSnapshot.hasData || !bookingSnapshot.hasData) {
                      return const Center(
                          child: Padding(
                              padding: EdgeInsets.all(32.0),
                              child: CircularProgressIndicator()));
                    }

                    final bookings = bookingSnapshot.data!.docs;
                    final totalCapacity = (configSnapshot.data!.data()
                            as Map<String, dynamic>)['totalCapacity'] ??
                        100;

                    // --- Logic การคำนวณทั้งหมด ---
                    final pendingBookings = bookings
                        .where((doc) =>
                            doc['bookingStatus'] == 'PENDING_VERIFICATION')
                        .length;

                    final confirmedBookings = bookings.where((doc) {
                      final status = doc['bookingStatus'];
                      return status == 'CONFIRMED' || status == 'COMPLETED';
                    }).toList();

                    final rejectedBookings = bookings
                        .where((doc) => doc['bookingStatus'] == 'REJECTED')
                        .length;

                    final totalRevenue =
                        confirmedBookings.fold<double>(0, (sum, doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      return sum + (data['totalCost'] ?? 0);
                    });

                    // --- Logic ใหม่สำหรับคำนวณการ์ดใหม่ ---
                    final currentlyParked = confirmedBookings.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      // เพิ่มการตรวจสอบ null ให้กับ Timestamp
                      final checkInTimestamp =
                          data['checkInDateTime'] as Timestamp?;
                      final checkOutTimestamp =
                          data['checkOutDateTime'] as Timestamp?;
                      if (checkInTimestamp == null || checkOutTimestamp == null)
                        return false;

                      final checkIn = checkInTimestamp.toDate();
                      final checkOut = checkOutTimestamp.toDate();
                      return checkIn.isBefore(now) && checkOut.isAfter(now);
                    }).length;

                    final arrivalsToday = confirmedBookings.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final checkInTimestamp =
                          data['checkInDateTime'] as Timestamp?;
                      if (checkInTimestamp == null) return false;
                      final checkIn = checkInTimestamp.toDate();
                      return checkIn.isAfter(startOfToday) &&
                          checkIn.isBefore(endOfToday);
                    }).length;

                    final departuresToday = confirmedBookings.where((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final checkOutTimestamp =
                          data['checkOutDateTime'] as Timestamp?;
                      if (checkOutTimestamp == null) return false;
                      final checkOut = checkOutTimestamp.toDate();
                      return checkOut.isAfter(startOfToday) &&
                          checkOut.isBefore(endOfToday);
                    }).length;

                    final availableSpots = totalCapacity - currentlyParked;

                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      alignment: WrapAlignment.center,
                      children: [
                        _buildStatCard('รอตรวจสอบ', pendingBookings.toString(),
                            Icons.hourglass_top, Colors.orange),
                        _buildStatCard(
                            'ยืนยันแล้ว',
                            confirmedBookings.length.toString(),
                            Icons.check_circle,
                            Colors.green),
                        _buildStatCard('ถูกปฏิเสธ', rejectedBookings.toString(),
                            Icons.cancel, Colors.red),
                        _buildStatCard(
                            'รายรับทั้งหมด',
                            '${totalRevenue.toStringAsFixed(2)} ฿',
                            Icons.attach_money,
                            Colors.blue),
                        // --- การ์ดใหม่ ---
                        _buildStatCard('ช่องจอดว่าง', availableSpots.toString(),
                            Icons.space_bar, Colors.purple),
                        _buildStatCard('รถเข้าวันนี้', arrivalsToday.toString(),
                            Icons.login, Colors.lightBlue),
                        _buildStatCard(
                            'รถออกวันนี้',
                            departuresToday.toString(),
                            Icons.logout,
                            Colors.pink),
                      ],
                    );
                  },
                );
              },
            )
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(20.0),
        width: 250,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 16),
            Text(value,
                style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            Text(title,
                style: TextStyle(fontSize: 16, color: Colors.grey[700])),
          ],
        ),
      ),
    );
  }
}
