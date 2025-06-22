import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminDailySchedulePage extends StatefulWidget {
  const AdminDailySchedulePage({super.key});

  @override
  State<AdminDailySchedulePage> createState() => _AdminDailySchedulePageState();
}

class _AdminDailySchedulePageState extends State<AdminDailySchedulePage> {
  DateTime _selectedDate = DateTime.now();

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final startOfDay =
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('ตารางงานสำหรับวันที่: ',
                    style: Theme.of(context).textTheme.titleLarge),
                ElevatedButton.icon(
                  onPressed: () => _selectDate(context),
                  icon: const Icon(Icons.calendar_month),
                  label: Text(
                      DateFormat('d MMMM yyyy', 'th_TH').format(_selectedDate)),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildScheduleList(
                  title: 'รายการรถเข้า',
                  query: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('bookingStatus', whereIn: [
                        'CONFIRMED',
                        'CHECKED_IN'
                      ]) // อนาคตอาจมีสถานะ Check-in
                      .where('checkInDateTime',
                          isGreaterThanOrEqualTo: startOfDay)
                      .where('checkInDateTime', isLessThan: endOfDay)
                      .orderBy('checkInDateTime'),
                  isCheckIn: true,
                ),
                const VerticalDivider(width: 1, thickness: 1),
                _buildScheduleList(
                  title: 'รายการรถออก',
                  query: FirebaseFirestore.instance
                      .collection('bookings')
                      .where('bookingStatus', isEqualTo: 'CONFIRMED')
                      .where('checkOutDateTime',
                          isGreaterThanOrEqualTo: startOfDay)
                      .where('checkOutDateTime', isLessThan: endOfDay)
                      .orderBy('checkOutDateTime'),
                  isCheckIn: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleList(
      {required String title, required Query query, required bool isCheckIn}) {
    return Expanded(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(title,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: query.snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  // แสดง Error ใน UI เพื่อให้เราเห็นและนำไปสร้าง Index
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text('เกิดข้อผิดพลาด:\n${snapshot.error}',
                          style: const TextStyle(color: Colors.red)),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('ไม่มีรายการ'));
                }
                final docs = snapshot.data!.docs;
                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final timeStamp = (isCheckIn
                        ? data['checkInDateTime']
                        : data['checkOutDateTime']) as Timestamp;
                    final time = DateFormat('HH:mm').format(timeStamp.toDate());
                    return ListTile(
                      leading: Icon(isCheckIn ? Icons.login : Icons.logout,
                          color: isCheckIn ? Colors.green : Colors.red),
                      title: Text('ทะเบียน: ${data['plateNumber'] ?? 'N/A'}'),
                      subtitle: Text(
                          'บริการรับส่ง: ${(data['needsShuttle'] ?? false) ? "ต้องการ" : "ไม่"}'),
                      trailing: Text(time,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
