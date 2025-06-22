// ---- lib/src/pages/customer_booking_details_page.dart (แก้ไขการแสดงรายละเอียดค่าใช้จ่าย) ----

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
    required List<Widget>
        detailWidgets, // เปลี่ยนจาก Map<String, String> เป็น List<Widget>
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
            children: detailWidgets, // ใช้ detailWidgets โดยตรง
          ),
        ),
      ],
    );
  }

  // Helper Widget สำหรับแสดงแต่ละบรรทัดรายละเอียด
  Widget _buildInfoRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
              width: 150,
              child: Text(label, style: TextStyle(color: Colors.grey[700]))),
          Expanded(
              child: Text(value,
                  style: TextStyle(
                      fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                      color: valueColor))),
        ],
      ),
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

          final double parkingCost =
              (bookingData['parkingCost'] as num? ?? 0).toDouble();
          final double shuttleCost =
              (bookingData['shuttleCost'] as num? ?? 0).toDouble();
          final double totalCost = (bookingData['totalCost'] as num? ?? 0)
              .toDouble(); // ราคารวมก่อนส่วนลด
          final double discountAmount =
              (bookingData['discountAmount'] as num? ?? 0).toDouble();
          final String? promoCode = bookingData['promoCodeUsed'];

          // ดึงอัตราค่าบริการเพิ่มเติมสำหรับแจกแจง
          final double dailyRate =
              (bookingData['dailyRate'] as num? ?? 0).toDouble();
          final double hourlyRate =
              (bookingData['hourlyRate'] as num? ?? 0).toDouble();
          final double shuttleBasePrice =
              (bookingData['shuttleBasePrice'] as num? ?? 0).toDouble();
          final double shuttlePerPersonPrice =
              (bookingData['shuttlePerPersonPrice'] as num? ?? 0).toDouble();

          // สร้าง List ของ Widget สำหรับรายละเอียดการคำนวณค่าใช้จ่าย
          List<Widget> costCalculationDetails = [];

          // รายละเอียดค่าจอดรถ
          if (totalDays > 0) {
            costCalculationDetails.add(_buildInfoRow(
                'ค่าจอดรถ (${totalDays} วัน):',
                '${NumberFormat("#,##0.00").format(totalDays * dailyRate)} บาท'));
          }
          if (remainingHours > 0) {
            costCalculationDetails.add(_buildInfoRow(
                'ค่าจอดรถ (${remainingHours} ชั่วโมง):',
                '${NumberFormat("#,##0.00").format(remainingHours * hourlyRate)} บาท'));
          }

          // รายละเอียดค่ารถรับส่ง
          if (shuttleType != 'NONE') {
            int tripCount = (shuttleType == 'ROUND_TRIP') ? 2 : 1;
            String tripDesc = '';
            if (shuttleType == 'ONEWAY_DEPART') tripDesc = ' (ขาไป)';
            if (shuttleType == 'ONEWAY_RETURN') tripDesc = ' (ขากลับ)';
            if (shuttleType == 'ROUND_TRIP') tripDesc = ' (ไป-กลับ)';

            if (shuttleBasePrice > 0) {
              costCalculationDetails.add(_buildInfoRow(
                  'ค่ารถรับส่งพื้นฐาน$tripDesc:',
                  '${NumberFormat("#,##0.00").format(shuttleBasePrice * tripCount)} บาท'));
            }

            if (passengerCount > 1 && shuttlePerPersonPrice > 0) {
              final additionalPassengers = passengerCount - 1;
              costCalculationDetails.add(_buildInfoRow(
                  'ค่าผู้โดยสารเพิ่มเติม$tripDesc (${additionalPassengers} คน):',
                  '${NumberFormat("#,##0.00").format(additionalPassengers * tripCount * shuttlePerPersonPrice)} บาท'));
            }
          }

          // ยอดรวม (ก่อนส่วนลด)
          costCalculationDetails.add(_buildInfoRow('รวมค่าบริการ:',
              '${NumberFormat("#,##0.00").format(parkingCost + shuttleCost)} บาท',
              isBold: true));

          // ส่วนลด (ถ้ามี)
          if (discountAmount > 0) {
            costCalculationDetails.add(_buildInfoRow(
                'ส่วนลด (${promoCode ?? 'ไม่ระบุ'}):',
                '-${NumberFormat("#,##0.00").format(discountAmount)} บาท',
                valueColor: Colors.green,
                isBold: true));
          }

          // ยอดรวมสุทธิ
          costCalculationDetails.add(_buildInfoRow('ยอดรวมสุทธิที่ชำระ:',
              '${NumberFormat("#,##0.00").format(totalCost - discountAmount)} บาท',
              isBold: true, valueColor: Theme.of(context).colorScheme.primary));

          return ListView(
            padding: const EdgeInsets.all(16.0),
            children: [
              _buildDetailSection(
                context: context,
                title: 'ข้อมูลการเดินทาง',
                icon: Icons.map_outlined,
                detailWidgets: [
                  _buildInfoRow(
                      'สถานะ:', bookingData['bookingStatus'] ?? 'N/A'),
                  _buildInfoRow('ทะเบียนรถ:',
                      '${bookingData['plateNumber'] ?? 'N/A'} (${bookingData['province'] ?? ''})'),
                  _buildInfoRow(
                      'วัน-เวลาเข้าจอด:',
                      formatter.format(
                          (bookingData['checkInDateTime'] as Timestamp)
                              .toDate())),
                  _buildInfoRow(
                      'วัน-เวลาออก:',
                      formatter.format(
                          (bookingData['checkOutDateTime'] as Timestamp)
                              .toDate())),
                  _buildInfoRow('ระยะเวลาจอดทั้งหมด:', durationText),
                ],
              ),
              const Divider(height: 32),
              _buildDetailSection(
                context: context,
                title: 'บริการเสริม',
                icon: Icons.airport_shuttle_outlined,
                detailWidgets: [
                  _buildInfoRow(
                      'รถรับส่ง:', '$shuttleText ($passengerCount คน)'),
                ],
              ),
              const Divider(height: 32),
              // ใช้ List ของ Widget ที่สร้างไว้
              _buildDetailSection(
                context: context,
                title: 'สรุปค่าใช้จ่าย',
                icon: Icons.receipt_long_outlined,
                detailWidgets:
                    costCalculationDetails, // <-- ใช้ List ที่แจกแจงรายละเอียด
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
