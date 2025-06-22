import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class PaymentPage extends StatefulWidget {
  final String bookingId;
  final double totalCost;
  const PaymentPage({super.key, required this.bookingId, required this.totalCost});
  @override
  State<PaymentPage> createState() => _PaymentPageState();
}
class _PaymentPageState extends State<PaymentPage> {
  bool _isUploading = false;
  XFile? _selectedSlip;
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() { _selectedSlip = image; });
    }
  }
  Future<void> _confirmUpload() async {
    if (_selectedSlip == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกไฟล์สลิปก่อน'), backgroundColor: Colors.red));
      return;
    }
    setState(() { _isUploading = true; });
    try {
      final imageBytes = await _selectedSlip!.readAsBytes();
      final fileBase64 = base64Encode(imageBytes);
      final callable = FirebaseFunctions.instanceFor(region: 'asia-southeast1').httpsCallable('uploadSlip');
      final response = await callable.call({
        'fileBase64': fileBase64,
        'fileName': '${widget.bookingId}-${_selectedSlip!.name}',
        'contentType': _selectedSlip!.mimeType ?? 'image/jpeg',
      });
      final publicUrl = response.data['publicUrl'];
      await FirebaseFirestore.instance.collection('bookings').doc(widget.bookingId).update({'slipUrl': publicUrl, 'bookingStatus': 'PENDING_VERIFICATION'});
      if (!mounted) return;
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: const Row(children: [Icon(Icons.check_circle, color: Colors.green), SizedBox(width: 10), Text('ทำรายการสำเร็จ')]),
          content: const Text('เราได้รับข้อมูลการชำระเงินของคุณแล้ว และจะทำการตรวจสอบโดยเร็วที่สุด ขอบคุณที่ใช้บริการ UPark ครับ'),
          actions: [TextButton(onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst), child: const Text('กลับสู่หน้าแรก'))],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาด: ${e.toString()}'), backgroundColor: Colors.red));
    } finally {
      if (mounted) { setState(() { _isUploading = false; }); }
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ชำระเงิน')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const Text('สแกน QR Code เพื่อชำระเงิน', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('ยอดชำระ: ${widget.totalCost.toStringAsFixed(2)} บาท', style: TextStyle(fontSize: 20, color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            Container(padding: const EdgeInsets.all(8), color: Colors.white, child: Image.asset('assets/images/qr_code_placeholder.png', width: 250, height: 250)),
            const Divider(height: 64),
            const Text('แจ้งการชำระเงิน', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Text('กรุณาอัปโหลดสลิปหลักฐานการโอนเงินเพื่อยืนยันการจองของคุณ', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 24),
            if (_selectedSlip != null) Padding(padding: const EdgeInsets.only(bottom: 16.0), child: Text('ไฟล์ที่เลือก: ${_selectedSlip!.name}', style: const TextStyle(color: Colors.green))),
            SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: _isUploading ? null : _pickImage, icon: const Icon(Icons.upload_file), label: Text(_selectedSlip == null ? 'เลือกไฟล์สลิป' : 'เลือกไฟล์ใหม่'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)))),
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _selectedSlip == null || _isUploading ? null : _confirmUpload, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)), child: _isUploading ? const CircularProgressIndicator() : const Text('ยืนยันการแจ้งโอน'))),
          ],
        ),
      ),
    );
  }
}