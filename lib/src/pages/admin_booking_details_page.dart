// ---- lib/src/pages/admin_booking_details_page.dart (ฉบับสมบูรณ์) ----
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminBookingDetailsPage extends StatefulWidget {
  final String bookingId;
  const AdminBookingDetailsPage({super.key, required this.bookingId});

  @override
  State<AdminBookingDetailsPage> createState() =>
      _AdminBookingDetailsPageState();
}

class _AdminBookingDetailsPageState extends State<AdminBookingDetailsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('รายละเอียดการจอง #${widget.bookingId.substring(0, 6)}'),
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
          final String? slipUrl = bookingData['slipUrl'];

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildDetailSection(
                context: context,
                title: 'ข้อมูลหลัก',
                icon: Icons.info_outline,
                details: {
                  'รหัสการจอง': widget.bookingId,
                  'สถานะ': bookingData['bookingStatus'] ?? 'N/A',
                  'User ID': bookingData['userId'] ?? 'N/A',
                },
              ),
              const Divider(height: 24),
              _buildDetailSection(
                context: context,
                title: 'ข้อมูลการเดินทาง',
                icon: Icons.map_outlined,
                details: {
                  'ทะเบียนรถ':
                      '${bookingData['plateNumber'] ?? 'N/A'} (${bookingData['province'] ?? ''})',
                  'วัน-เวลาเข้าจอด': formatter.format(
                      (bookingData['checkInDateTime'] as Timestamp).toDate()),
                  'วัน-เวลาออก': formatter.format(
                      (bookingData['checkOutDateTime'] as Timestamp).toDate()),
                  'ระยะเวลาจอดทั้งหมด': durationText,
                },
              ),
              const Divider(height: 24),
              _buildDetailSection(
                context: context,
                title: 'บริการเสริม',
                icon: Icons.airport_shuttle_outlined,
                details: {
                  'รถรับส่ง': '$shuttleText ($passengerCount คน)',
                },
              ),
              const Divider(height: 24),
              _buildDetailSection(
                context: context,
                title: 'ข้อมูลลูกค้า (สำหรับใบกำกับภาษี)',
                icon: Icons.person_outline,
                details: {
                  'ชื่อ-นามสกุล': bookingData['taxName'] ?? '-',
                  'ที่อยู่': bookingData['taxAddress'] ?? '-',
                  'เลขประจำตัวผู้เสียภาษี': bookingData['taxId'] ?? '-',
                },
              ),
              const Divider(height: 24),
              _buildDetailSection(
                context: context,
                title: 'สรุปค่าใช้จ่าย',
                icon: Icons.receipt_long_outlined,
                details: {
                  'ค่าจอดรถ':
                      '${(bookingData['parkingCost'] as num? ?? 0).toStringAsFixed(2)} บาท',
                  'ค่ารถรับส่ง':
                      '${(bookingData['shuttleCost'] as num? ?? 0).toStringAsFixed(2)} บาท',
                  'ยอดรวม (ก่อนหักส่วนลด)':
                      '${totalCost.toStringAsFixed(2)} บาท',
                  if (discountAmount > 0)
                    'ส่วนลด (${promoCode ?? ''})':
                        '-${discountAmount.toStringAsFixed(2)} บาท',
                  'ยอดรวมสุทธิที่ชำระ':
                      '${(totalCost - discountAmount).toStringAsFixed(2)} บาท',
                },
              ),
              const Divider(height: 32),
              Text('สลิปการชำระเงิน',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              if (slipUrl != null && slipUrl.isNotEmpty)
                Center(
                  child: Image.network(
                    slipUrl,
                    height: 400,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                          child: Text('ไม่สามารถโหลดรูปสลิปได้'));
                    },
                  ),
                )
              else
                const Center(child: Text('ยังไม่มีการอัปโหลดสลิป')),
            ],
          );
        },
      ),
    );
  }

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
}
