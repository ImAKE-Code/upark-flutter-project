// ---- lib/src/pages/customer_booking_details_page.dart (ฉบับสมบูรณ์ Final) ----

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:suvarnabhumi_parking_app/services/receipt_service.dart';

class CustomerBookingDetailsPage extends StatefulWidget {
  final String bookingId;
  const CustomerBookingDetailsPage({super.key, required this.bookingId});

  @override
  State<CustomerBookingDetailsPage> createState() =>
      _CustomerBookingDetailsPageState();
}

class _CustomerBookingDetailsPageState
    extends State<CustomerBookingDetailsPage> {
  bool _isPrinting = false;

  Future<void> _printReceipt(Map<String, dynamic> bookingData) async {
    if (_isPrinting) return;
    if (!mounted) return;
    setState(() => _isPrinting = true);

    try {
      final dataWithId = Map<String, dynamic>.from(bookingData);
      dataWithId['id'] = widget.bookingId;

      final pdfData = await ReceiptService.generateReceipt(dataWithId);
      await Printing.layoutPdf(onLayout: (format) => pdfData);
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

  // --- เพิ่ม Helper Widget ที่ขาดไปเข้ามาใน Class นี้ ---
  Widget _buildDetailSection({
    required BuildContext context,
    required String title,
    required IconData icon,
    required Map<String, String> details,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(left: 32.0),
          child: Column(
            children: details.entries
                .map((entry) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                              width: 150,
                              child: Text('${entry.key}:',
                                  style: TextStyle(color: Colors.grey[700]))),
                          Expanded(
                              child: Text(entry.value,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold))),
                        ],
                      ),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
  // ----------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('รายละเอียดการจอง'),
        actions: [
          if (user != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Text(user.email ?? '',
                    style: TextStyle(color: Colors.grey[600])),
              ),
            ),
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('bookings')
            .doc(widget.bookingId)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('ไม่พบข้อมูลการจองนี้'));
          }

          final bookingData = snapshot.data!.data() as Map<String, dynamic>;

          final DateFormat formatter = DateFormat('d MMMM y, HH:mm', 'th_TH');
          final int totalDays = bookingData['totalDays'] ?? 0;
          final int remainingHours = bookingData['remainingHours'] ?? 0;
          final String durationText = '$totalDays วัน $remainingHours ชั่วโมง';
          final int passengerCount = bookingData['passengerCount'] ?? 0;
          final String shuttleType = bookingData['shuttleType'] ?? 'NONE';

          String shuttleText = 'ไม่ใช้บริการ';
          switch (shuttleType) {
            case 'ONEWAY_DEPART':
              shuttleText = 'เฉพาะขาไป';
              break;
            case 'ONEWAY_RETURN':
              shuttleText = 'เฉพาะขากลับ';
              break;
            case 'ROUND_TRIP':
              shuttleText = 'ไป-กลับ';
              break;
          }

          final double totalCost =
              (bookingData['totalCost'] as num? ?? 0).toDouble();
          final double discountAmount =
              (bookingData['discountAmount'] as num? ?? 0).toDouble();
          final String? promoCode = bookingData['promoCodeUsed'];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildDetailSection(
                context: context,
                title: 'ข้อมูลการเดินทาง',
                icon: Icons.map_outlined,
                details: {
                  'สถานะ': bookingData['bookingStatus'] ?? 'N/A',
                  'ทะเบียนรถ':
                      '${bookingData['plateNumber'] ?? 'N/A'} (${bookingData['province'] ?? ''})',
                  'วัน-เวลาเข้าจอด': formatter.format(
                      (bookingData['checkInDateTime'] as Timestamp).toDate()),
                  'วัน-เวลาออก': formatter.format(
                      (bookingData['checkOutDateTime'] as Timestamp).toDate()),
                  'ระยะเวลาจอดทั้งหมด': durationText,
                },
              ),
              const Divider(height: 32),
              _buildDetailSection(
                context: context,
                title: 'บริการเสริม',
                icon: Icons.airport_shuttle_outlined,
                details: {'รถรับส่ง': '$shuttleText ($passengerCount คน)'},
              ),
              const Divider(height: 32),
              _buildDetailSection(
                context: context,
                title: 'สรุปค่าใช้จ่าย',
                icon: Icons.receipt_long_outlined,
                details: {
                  'ยอดรวม (ก่อนหักส่วนลด)':
                      '${totalCost.toStringAsFixed(2)} บาท',
                  if (discountAmount > 0)
                    'ส่วนลด (${promoCode ?? ''})':
                        '-${discountAmount.toStringAsFixed(2)} บาท',
                  'ยอดรวมสุทธิที่ชำระ':
                      '${(totalCost - discountAmount).toStringAsFixed(2)} บาท',
                },
              ),
              const SizedBox(height: 32),
              ElevatedButton.icon(
                onPressed:
                    _isPrinting ? null : () => _printReceipt(bookingData),
                icon: _isPrinting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 3.0))
                    : const Icon(Icons.print),
                label: const Text('พิมพ์ใบกำกับภาษี/ใบเสร็จ'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
