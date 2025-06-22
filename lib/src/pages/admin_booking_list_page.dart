// ---- lib/src/pages/admin_booking_list_page.dart (ฉบับสมบูรณ์) ----

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'admin_booking_details_page.dart';

class AdminBookingListPage extends StatefulWidget {
  const AdminBookingListPage({super.key});

  @override
  State<AdminBookingListPage> createState() => _AdminBookingListPageState();
}

class _AdminBookingListPageState extends State<AdminBookingListPage> {
  Future<void> _updateBookingStatus(String docId, String newStatus) async {
    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .update({'bookingStatus': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('อัปเดตสถานะเป็น $newStatus สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการอัปเดต: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('bookings')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'ยังไม่มีรายการจองในระบบ',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            );
          }

          final bookings = snapshot.data!.docs;

          // --- ส่วน Return ที่ถูกต้อง ---
          return ListView.builder(
            itemCount: bookings.length,
            itemBuilder: (context, index) {
              final bookingDoc = bookings[index];
              final bookingData = bookingDoc.data() as Map<String, dynamic>;

              final String plateNumber = bookingData['plateNumber'] ?? 'N/A';
              final String status = bookingData['bookingStatus'] ?? 'N/A';
              final Timestamp createdAt =
                  bookingData['createdAt'] ?? Timestamp.now();
              final String formattedDate = DateFormat('d MMM y, HH:mm', 'th_TH')
                  .format(createdAt.toDate());
              final bool needsShuttle = bookingData['needsShuttle'] ?? false;
              final int passengerCount = bookingData['passengerCount'] ?? 0;

              String subtitleText = 'วันที่จอง: $formattedDate\nสถานะ: $status';
              if (needsShuttle) {
                subtitleText += '\nผู้โดยสาร: $passengerCount คน';
              }

              return Card(
                margin:
                    const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(status),
                    child: Icon(_getStatusIcon(status),
                        color: Colors.white, size: 20),
                  ),
                  title: Text('ทะเบียน: $plateNumber'),
                  subtitle: Text(subtitleText),
                  trailing: (status == 'PENDING_VERIFICATION')
                      ? SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check_circle,
                                    color: Colors.green),
                                tooltip: 'อนุมัติ',
                                onPressed: () => _updateBookingStatus(
                                    bookingDoc.id, 'CONFIRMED'),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.cancel, color: Colors.red),
                                tooltip: 'ปฏิเสธ',
                                onPressed: () => _updateBookingStatus(
                                    bookingDoc.id, 'REJECTED'),
                              ),
                            ],
                          ),
                        )
                      : const Icon(Icons.chevron_right),
                  isThreeLine: true,
                  onTap: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => AdminBookingDetailsPage(
                                bookingId: bookingDoc.id)));
                  },
                ),
              );
            },
          );
          // --------------------------
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Colors.green;
      case 'PENDING_VERIFICATION':
        return Colors.orange;
      case 'PENDING_PAYMENT':
        return Colors.blueGrey;
      case 'REJECTED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Icons.check_circle;
      case 'PENDING_VERIFICATION':
        return Icons.hourglass_top;
      case 'PENDING_PAYMENT':
        return Icons.payment;
      case 'REJECTED':
        return Icons.cancel;
      case 'COMPLETED':
        return Icons.directions_car_filled;
      default:
        return Icons.help_outline;
    }
  }
}
