// ---- lib/src/pages/summary_page.dart (ฉบับปรับปรุง UI สรุปค่าใช้จ่าย) ----

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'payment_page.dart';

class SummaryPage extends StatefulWidget {
  final DateTime checkInDate, checkOutDate;
  final int passengerCount, totalDays, remainingHours;
  final String plateNumber, province, taxName, taxAddress, taxId, shuttleType;
  final double parkingCost,
      shuttleCost,
      totalCost,
      dailyRate,
      hourlyRate,
      shuttleBasePrice,
      shuttlePerPersonPrice;

  const SummaryPage({
    super.key,
    required this.checkInDate,
    required this.checkOutDate,
    required this.passengerCount,
    required this.plateNumber,
    required this.province,
    required this.totalDays,
    required this.remainingHours,
    required this.parkingCost,
    required this.shuttleCost,
    required this.totalCost,
    required this.taxName,
    required this.taxAddress,
    required this.taxId,
    required this.dailyRate,
    required this.hourlyRate,
    required this.shuttleType,
    required this.shuttleBasePrice,
    required this.shuttlePerPersonPrice,
  });

  @override
  State<SummaryPage> createState() => _SummaryPageState();
}

class _SummaryPageState extends State<SummaryPage> {
  bool _isLoading = false;
  final _promoCodeController = TextEditingController();
  bool _isVerifyingCode = false;
  String? _appliedPromoCode;
  String? _promoDiscountType;
  double _promoDiscountValue = 0;
  double _discountAmount = 0;

  @override
  void dispose() {
    _promoCodeController.dispose();
    super.dispose();
  }

  Future<void> _validatePromoCode() async {
    final code = _promoCodeController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    setState(() {
      _isVerifyingCode = true;
    });
    try {
      final HttpsCallable callable =
          FirebaseFunctions.instanceFor(region: 'asia-southeast1')
              .httpsCallable('validatePromoCode');
      final result = await callable.call<Map<String, dynamic>>({'code': code});
      final data = result.data;
      setState(() {
        _appliedPromoCode = data['code'];
        _promoDiscountType = data['discountType'];
        _promoDiscountValue = (data['discountValue'] as num).toDouble();
        _calculateDiscount();
      });
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('ใช้โค้ดส่วนลดสำเร็จ!'),
            backgroundColor: Colors.green));
    } on FirebaseFunctionsException catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('โค้ดไม่ถูกต้องหรือใช้งานไม่ได้: ${e.message}'),
            backgroundColor: Colors.red));
      _resetPromoCode();
    } finally {
      if (mounted)
        setState(() {
          _isVerifyingCode = false;
        });
    }
  }

  void _calculateDiscount() {
    // คำนวณส่วนลดจากยอดรวมก่อนหักส่วนลดอื่นๆ (ถ้ามี)
    double originalTotal = widget.parkingCost + widget.shuttleCost;
    if (_promoDiscountType == 'PERCENTAGE') {
      _discountAmount = originalTotal * (_promoDiscountValue / 100);
    } else if (_promoDiscountType == 'FIXED_AMOUNT') {
      _discountAmount = _promoDiscountValue;
    } else {
      _discountAmount = 0;
    }
    // ไม่ให้ส่วนลดมากกว่าราคารวม
    if (_discountAmount > originalTotal) {
      _discountAmount = originalTotal;
    }
  }

  void _resetPromoCode() {
    setState(() {
      _promoCodeController.clear();
      _appliedPromoCode = null;
      _promoDiscountType = null;
      _promoDiscountValue = 0;
      _discountAmount = 0;
    });
  }

  Future<void> _submitBooking() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      final bookingData = {
        'checkInDateTime': widget.checkInDate,
        'checkOutDateTime': widget.checkOutDate,
        'plateNumber': widget.plateNumber, 'province': widget.province,
        'passengerCount': widget.passengerCount, 'userId': user.uid,
        'bookingStatus': 'PENDING_PAYMENT',
        'createdAt': FieldValue.serverTimestamp(),
        'parkingCost': widget.parkingCost, 'shuttleCost': widget.shuttleCost,
        'totalCost': widget.totalCost, // ราคารวมก่อนหักส่วนลด
        'discountAmount': _discountAmount,
        'promoCodeUsed': _appliedPromoCode,
        'totalDays': widget.totalDays, 'remainingHours': widget.remainingHours,
        'dailyRate': widget.dailyRate, 'hourlyRate': widget.hourlyRate,
        'shuttleType': widget.shuttleType,
        'needsShuttle': widget.shuttleType != 'NONE',
        'shuttleBasePrice': widget.shuttleBasePrice,
        'shuttlePerPersonPrice': widget.shuttlePerPersonPrice,
        'taxName': widget.taxName, 'taxAddress': widget.taxAddress,
        'taxId': widget.taxId,
      };

      final docRef = await FirebaseFirestore.instance
          .collection('bookings')
          .add(bookingData);

      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            bookingId: docRef.id,
            totalCost: widget.totalCost -
                _discountAmount, // ส่งราคาสุทธิไปหน้าชำระเงิน
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('เกิดข้อผิดพลาด: ${e.toString()}'),
              backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final DateFormat formatter = DateFormat('d MMMM y, HH:mm', 'th_TH');

    String shuttleText = 'ไม่ใช้บริการ';
    switch (widget.shuttleType) {
      case 'ONEWAY_DEPART':
        shuttleText = 'เฉพาะขาไป (${widget.passengerCount} คน)';
        break;
      case 'ONEWAY_RETURN':
        shuttleText = 'เฉพาะขากลับ (${widget.passengerCount} คน)';
        break;
      case 'ROUND_TRIP':
        shuttleText = 'ไป-กลับ (${widget.passengerCount} คน)';
        break;
    }

    // สร้าง List ของ Widget สำหรับแสดงรายละเอียดค่าใช้จ่าย
    List<Widget> costDetails = [];
    if (widget.parkingCost > 0) {
      if (widget.totalDays > 0) {
        costDetails.add(_buildInfoRow('ค่าจอดรถ (รายวัน)',
            '${widget.totalDays} วัน x ${widget.dailyRate.toStringAsFixed(2)} = ${(widget.totalDays * widget.dailyRate).toStringAsFixed(2)} บาท'));
      }
      if (widget.remainingHours > 0) {
        costDetails.add(_buildInfoRow('ค่าจอดรถ (รายชั่วโมง)',
            '${widget.remainingHours} ชั่วโมง x ${widget.hourlyRate.toStringAsFixed(2)} = ${(widget.remainingHours * widget.hourlyRate).toStringAsFixed(2)} บาท'));
      }
    }
    if (widget.shuttleCost > 0) {
      int tripCount = (widget.shuttleType == 'ROUND_TRIP') ? 2 : 1;
      if (widget.shuttleBasePrice > 0) {
        costDetails.add(_buildInfoRow('ค่ารถรับส่ง (พื้นฐาน)',
            '$tripCount เที่ยว x ${widget.shuttleBasePrice.toStringAsFixed(2)} = ${(widget.shuttleBasePrice * tripCount).toStringAsFixed(2)} บาท'));
      }
      if (widget.passengerCount > 1 && widget.shuttlePerPersonPrice > 0) {
        final additionalPassengers = widget.passengerCount - 1;
        costDetails.add(_buildInfoRow('ค่าผู้โดยสารเพิ่มเติม',
            '${additionalPassengers * tripCount} คน/เที่ยว x ${widget.shuttlePerPersonPrice.toStringAsFixed(2)} = ${(additionalPassengers * tripCount * widget.shuttlePerPersonPrice).toStringAsFixed(2)} บาท'));
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('สรุปและยืนยันการจอง')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildDetailCard(
            title: 'ข้อมูลการเดินทาง',
            children: [
              _buildInfoRow('เข้าจอด:', formatter.format(widget.checkInDate)),
              _buildInfoRow(
                  'ออกจากที่จอด:', formatter.format(widget.checkOutDate)),
              _buildInfoRow('ระยะเวลา:',
                  '${widget.totalDays} วัน ${widget.remainingHours} ชั่วโมง'),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailCard(
            title: 'ข้อมูลรถยนต์และบริการเสริม',
            children: [
              _buildInfoRow('ทะเบียนรถ:', widget.plateNumber),
              _buildInfoRow('จังหวัด:', widget.province),
              _buildInfoRow('บริการรับส่ง:', shuttleText),
            ],
          ),
          const Divider(height: 24, thickness: 1),
          Text('โค้ดส่วนลด (ถ้ามี)',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: TextFormField(
                controller: _promoCodeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'กรอกโค้ดส่วนลด',
                  border: const OutlineInputBorder(),
                  suffixIcon: _appliedPromoCode != null
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                ),
                readOnly: _appliedPromoCode != null,
              )),
              const SizedBox(width: 8),
              _isVerifyingCode
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator())
                  : OutlinedButton(
                      onPressed: _appliedPromoCode != null
                          ? _resetPromoCode
                          : _validatePromoCode,
                      style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.all(16)),
                      child:
                          Text(_appliedPromoCode != null ? 'ล้าง' : 'ใช้โค้ด'),
                    ),
            ],
          ),
          const SizedBox(height: 24),
          _buildDetailCard(
            title: 'สรุปค่าใช้จ่าย',
            children: [
              ...costDetails,
              const Divider(),
              if (_discountAmount > 0)
                _buildInfoRow(
                    'ส่วนลด:', '-${_discountAmount.toStringAsFixed(2)} บาท',
                    valueColor: Colors.green),
              _buildInfoRow('ยอดรวมสุทธิ:',
                  '${(widget.totalCost - _discountAmount).toStringAsFixed(2)} บาท',
                  isBold: true,
                  valueColor: Theme.of(context).colorScheme.primary),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: _isLoading ? null : _submitBooking,
              child: _isLoading
                  ? const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white))
                  : const Text('ยืนยันและดำเนินการต่อ',
                      style: TextStyle(fontSize: 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false, Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                  fontSize: 16,
                  color: valueColor,
                  fontWeight: isBold ? FontWeight.bold : FontWeight.normal),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailCard(
      {required String title, required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }
}
