// ---- lib/src/pages/my_bookings_page.dart (ฉบับเพิ่มรายละเอียดระยะเวลา) ----

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:suvarnabhumi_parking_app/services/receipt_service.dart';
import 'package:suvarnabhumi_parking_app/src/pages/customer_booking_details_page.dart';

class MyBookingsPage extends StatefulWidget {
  const MyBookingsPage({super.key});

  @override
  State<MyBookingsPage> createState() => _MyBookingsPageState();
}

class _MyBookingsPageState extends State<MyBookingsPage> {
  final User? currentUser = FirebaseAuth.instance.currentUser;
  bool _isPrinting = false;

  Future<void> _printReceipt(String bookingId) async {
    if (_isPrinting) return;
    if (!mounted) return;
    setState(() => _isPrinting = true);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('bookings')
          .doc(bookingId)
          .get();

      if (!mounted) return;
      if (doc.exists) {
        final data = doc.data()!;
        data['id'] = doc.id;

        final pdfData = await ReceiptService.generateReceipt(data);

        await Printing.layoutPdf(onLayout: (format) => pdfData);
      } else {
        throw Exception('ไม่พบข้อมูลการจองนี้');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาดในการสร้างใบเสร็จ: $e'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isPrinting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (currentUser == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('ประวัติการจองของฉัน')),
        body: const Center(
          child: Text('ไม่พบข้อมูลผู้ใช้, กรุณาล็อกอินใหม่อีกครั้ง'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('ประวัติการจองของฉัน')),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('bookings')
                .where('userId', isEqualTo: currentUser!.uid)
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
                    'คุณยังไม่มีประวัติการจอง',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                );
              }

              final bookings = snapshot.data!.docs;

              return ListView.builder(
                itemCount: bookings.length,
                itemBuilder: (context, index) {
                  final bookingDoc = bookings[index];
                  final bookingData = bookingDoc.data() as Map<String, dynamic>;

                  // --- ดึงข้อมูลมาแสดงผล ---
                  final String plateNumber =
                      bookingData['plateNumber'] ?? 'N/A';
                  final String status = bookingData['bookingStatus'] ?? 'N/A';
                  final double totalCost =
                      (bookingData['totalCost'] as num? ?? 0).toDouble();
                  final int totalDays = bookingData['totalDays'] ?? 0;
                  final int remainingHours = bookingData['remainingHours'] ?? 0;
                  // ---------------------------

                  // --- สร้างข้อความ Subtitle ใหม่ ---
                  String subtitleText = 'สถานะ: $status';
                  if (totalDays > 0 || remainingHours > 0) {
                    subtitleText +=
                        '\nระยะเวลา: $totalDays วัน $remainingHours ชั่วโมง';
                  }
                  // ------------------------------

                  return Card(
                    margin: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 4.0),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getStatusColor(status),
                        child: Icon(_getStatusIcon(status),
                            color: Colors.white, size: 20),
                      ),
                      title: Text('ทะเบียน: $plateNumber'),
                      subtitle: Text(subtitleText), // <-- ใช้ subtitleText ใหม่
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '฿${totalCost.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.print_outlined),
                            color: Theme.of(context).colorScheme.primary,
                            tooltip: 'พิมพ์ใบเสร็จ',
                            onPressed: () => _printReceipt(bookingDoc.id),
                          ),
                          const Icon(Icons.chevron_right, color: Colors.grey),
                        ],
                      ),
                      isThreeLine: true,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CustomerBookingDetailsPage(
                                bookingId: bookingDoc.id),
                          ),
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),
          if (_isPrinting)
            Container(
              color: Colors.black54,
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('กำลังสร้างใบเสร็จ...',
                        style: TextStyle(color: Colors.white, fontSize: 16)),
                  ],
                ),
              ),
            ),
        ],
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
