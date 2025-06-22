// ---- โค้ดสำหรับ booking_page.dart ----
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'summary_page.dart';

class BookingPage extends StatefulWidget {
  const BookingPage({super.key});
  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  // --- State ทั้งหมดของฟอร์ม ---
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  String _shuttleType = 'NONE'; // NONE, ONEWAY_DEPART, ONEWAY_RETURN, ROUND_TRIP
  int _passengerCount = 1;
  final TextEditingController _plateNumberController = TextEditingController();
  String? _selectedProvince;
  int? _availableSpots;
  bool _isCheckingSpots = false;
  String _receiptType = 'SIMPLE';
  final _taxNameController = TextEditingController();
  final _taxAddressController = TextEditingController();
  final _taxIdController = TextEditingController();
  final List<String> _provinces = [
    'กรุงเทพมหานคร',
    'กระบี่',
    'กาญจนบุรี',
    'กาฬสินธุ์',
    'กำแพงเพชร',
    'ขอนแก่น',
    'จันทบุรี',
    'ฉะเชิงเทรา',
    'ชลบุรี',
    'ชัยนาท',
    'ชัยภูมิ',
    'ชุมพร',
    'เชียงราย',
    'เชียงใหม่',
    'ตรัง',
    'ตราด',
    'ตาก',
    'นครนายก',
    'นครปฐม',
    'นครพนม',
    'นครราชสีมา',
    'นครศรีธรรมราช',
    'นครสวรรค์',
    'นนทบุรี',
    'นราธิวาส',
    'น่าน',
    'บึงกาฬ',
    'บุรีรัมย์',
    'ปทุมธานี',
    'ประจวบคีรีขันธ์',
    'ปราจีนบุรี',
    'ปัตตานี',
    'พระนครศรีอยุธยา',
    'พะเยา',
    'พังงา',
    'พัทลุง',
    'พิจิตร',
    'พิษณุโลก',
    'เพชรบุรี',
    'เพชรบูรณ์',
    'แพร่',
    'ภูเก็ต',
    'มหาสารคาม',
    'มุกดาหาร',
    'แม่ฮ่องสอน',
    'ยโสธร',
    'ยะลา',
    'ร้อยเอ็ด',
    'ระนอง',
    'ระยอง',
    'ราชบุรี',
    'ลพบุรี',
    'ลำปาง',
    'ลำพูน',
    'เลย',
    'ศรีสะเกษ',
    'สกลนคร',
    'สงขลา',
    'สตูล',
    'สมุทรปราการ',
    'สมุทรสงคราม',
    'สมุทรสาคร',
    'สระแก้ว',
    'สระบุรี',
    'สิงห์บุรี',
    'สุโขทัย',
    'สุพรรณบุรี',
    'สุราษฎร์ธานี',
    'สุรินทร์',
    'หนองคาย',
    'หนองบัวลำภู',
    'อ่างทอง',
    'อำนาจเจริญ',
    'อุดรธานี',
    'อุตรดิตถ์',
    'อุทัยธานี',
    'อุบลราชธานี',
  ];

   @override
  void dispose() {
    _plateNumberController.dispose();
    _taxNameController.dispose();
    _taxAddressController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  Future<void> _selectDateTime(BuildContext context, bool isCheckIn) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _checkInDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (!mounted) return;
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(DateTime.now()),
      );
      if (!mounted) return;
      if (pickedTime != null) {
        final selectedDateTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );
        setState(() {
          if (isCheckIn) {
            _checkInDate = selectedDateTime;
          } else {
            _checkOutDate = selectedDateTime;
          }
        });
        if (_checkInDate != null && _checkOutDate != null) {
          _fetchAvailableSpots();
        }
      }
    }
  }

  Future<void> _fetchAvailableSpots() async {
    if (_checkInDate == null ||
        _checkOutDate == null ||
        _checkOutDate!.isBefore(_checkInDate!)) {
      return;
    }
    setState(() {
      _isCheckingSpots = true;
      _availableSpots = null;
    });
    try {
      final callable = FirebaseFunctions.instanceFor(
        region: 'asia-southeast1',
      ).httpsCallable('getAvailableSpots');
      final response = await callable.call({
        'checkIn': _checkInDate!.toIso8601String(),
        'checkOut': _checkOutDate!.toIso8601String(),
      });
      setState(() {
        _availableSpots = response.data['availableSpots'];
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ไม่สามารถตรวจสอบช่องจอดได้'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() {
        _availableSpots = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingSpots = false;
        });
      }
    }
  }

  Future<void> _calculateAndProceed() async {
    // ... (ส่วน validation ตรวจสอบข้อมูลเหมือนเดิม) ...

    try {
      const String configDocId = 'Nez0wZtFS8JgS9iWorp5';
      final configDoc = await FirebaseFirestore.instance
          .collection('config')
          .doc(configDocId)
          .get();
      if (!configDoc.exists) {
        _showErrorDialog('ไม่พบข้อมูลการตั้งค่าราคาในระบบ');
        return;
      }
      final configData = configDoc.data()!;
      // --- 1. ดึงค่าการตั้งค่าใหม่จาก Firestore ---
      final bool isShuttleEnabled = configData['isShuttleEnabled'] ?? false;
      final double dailyRate = (configData['dailyRate'] as num).toDouble();
      final double hourlyRate = (configData['hourlyRate'] as num).toDouble();
      final double shuttleBasePrice =
          (configData['shuttleBasePrice'] as num).toDouble();
      final double shuttlePerPersonPrice =
          (configData['shuttlePerPersonPrice'] as num).toDouble();
      // ---------------------------------------------

      final duration = _checkOutDate!.difference(_checkInDate!);
      final totalDays = duration.inDays;
      final remainingHours = duration.inHours % 24;
      double parkingCost =
          (totalDays * dailyRate) + (remainingHours * hourlyRate);

      double shuttleCost = 0;
      if (isShuttleEnabled) {
          final tieredPrice = shuttleBasePrice + ((_passengerCount - 1) * shuttlePerPersonPrice);
          switch (_shuttleType) {
            case 'ONEWAY_DEPART':
            case 'ONEWAY_RETURN':
              shuttleCost = tieredPrice;
              break;
            case 'ROUND_TRIP':
              shuttleCost = tieredPrice * 2; // สมมติว่าไปกลับคือ 2 เท่า
              break;
          }
      }
      // -----------------------------------
      final double totalCost = parkingCost + shuttleCost;

      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => SummaryPage (
            checkInDate: _checkInDate!, checkOutDate: _checkOutDate!,
            passengerCount: _passengerCount, plateNumber: _plateNumberController.text,
            province: _selectedProvince!, totalDays: totalDays, remainingHours: remainingHours,
            parkingCost: parkingCost, shuttleCost: shuttleCost, totalCost: totalCost,
            taxName: _taxNameController.text, taxAddress: _taxAddressController.text, taxId: _taxIdController.text,
            dailyRate: dailyRate, hourlyRate: hourlyRate,
            shuttleType: _shuttleType, // ส่งประเภทบริการไป
            shuttleBasePrice: shuttleBasePrice, shuttlePerPersonPrice: shuttlePerPersonPrice,),
        ),
      );
    } catch (e) {
      _showErrorDialog('เกิดข้อผิดพลาดในการดึงข้อมูลราคา: $e');
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('ข้อมูลไม่ครบถ้วน'),
          content: Text(message),
          actions: <Widget>[
            TextButton(
              child: const Text('ตกลง'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('กรอกข้อมูลการจอง')),
      body: ListView(
        padding: const EdgeInsets.all(32.0),
        children: [
          // ... ส่วนเลือกวัน-เวลา และ ช่องจอดว่าง (เหมือนเดิม) ...
          const Text(
            'วัน-เวลาที่นำรถเข้าจอด',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDateTime(context, true),
            label: Text(
              _checkInDate == null
                  ? 'กรุณาเลือกวัน-เวลา'
                  : DateFormat(
                      'd MMMM y, HH:mm',
                      'th_TH',
                    ).format(_checkInDate!),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'วัน-เวลาที่นำรถออกจากที่จอด',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today),
            onPressed: () => _selectDateTime(context, false),
            label: Text(
              _checkOutDate == null
                  ? 'กรุณาเลือกวัน-เวลา'
                  : DateFormat(
                      'd MMMM y, HH:mm',
                      'th_TH',
                    ).format(_checkOutDate!),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          _buildAvailabilityIndicator(),
          const Divider(height: 32),

          // ... ส่วนบริการรถรับส่ง (เหมือนเดิม) ...
          const Text('บริการรถรับส่ง', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _shuttleType,
            decoration: const InputDecoration(
              labelText: 'เลือกประเภทบริการ',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.airport_shuttle),
            ),
            items: const [
              DropdownMenuItem(value: 'NONE', child: Text('ไม่ใช้บริการ')),
              DropdownMenuItem(value: 'ONEWAY_DEPART', child: Text('เฉพาะขาไป (ส่งสนามบิน)')),
              DropdownMenuItem(value: 'ONEWAY_RETURN', child: Text('เฉพาะขากลับ (รับจากสนามบิน)')),
              DropdownMenuItem(value: 'ROUND_TRIP', child: Text('ไป-กลับ')),
            ],
            onChanged: (String? newValue) {
              setState(() {
                _shuttleType = newValue!;
              });
            },
          ),
          if (_shuttleType != 'NONE') ...[
            const SizedBox(height: 16),
            DropdownButtonFormField<int>(
              value: _passengerCount,
              items: List.generate(10, (index) => index + 1)
                  .map(
                    (number) => DropdownMenuItem(
                      value: number,
                      child: Text('$number คน'),
                    ),
                  )
                  .toList(),
              onChanged: (int? newValue) {
                setState(() {
                  _passengerCount = newValue!;
                });
              },
              decoration: const InputDecoration(
                labelText: 'จำนวนผู้โดยสาร',
                border: OutlineInputBorder(),
              ),
            ),
          ],
          const Divider(height: 48),

          // ... ส่วนข้อมูลรถยนต์ (เหมือนเดิม) ...
          const Text(
            'ข้อมูลรถยนต์',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _plateNumberController,
            decoration: const InputDecoration(
              labelText: 'หมายเลขทะเบียนรถ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            value: _selectedProvince,
            hint: const Text('เลือกจังหวัด'),
            isExpanded: true,
            items: _provinces.map((String province) {
              return DropdownMenuItem<String>(
                value: province,
                child: Text(province),
              );
            }).toList(),
            onChanged: (String? newValue) {
              setState(() {
                _selectedProvince = newValue;
              });
            },
            decoration: const InputDecoration(
              labelText: 'จังหวัด',
              border: OutlineInputBorder(),
            ),
          ),
          const Divider(height: 48),

          // --- ส่วนเลือกใบกำกับภาษี (ที่นำกลับมา) ---
          const Text(
            'ข้อมูลใบเสร็จ',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          RadioListTile<String>(
            title: const Text('ออกใบเสร็จรับเงินอย่างย่อ'),
            value: 'SIMPLE',
            groupValue: _receiptType,
            onChanged: (value) => setState(() => _receiptType = value!),
          ),
          RadioListTile<String>(
            title: const Text('ออกใบกำกับภาษีเต็มรูปแบบ'),
            value: 'TAX_INVOICE',
            groupValue: _receiptType,
            onChanged: (value) => setState(() => _receiptType = value!),
          ),
          if (_receiptType == 'TAX_INVOICE') ...[
            const SizedBox(height: 16),
            TextFormField(
              controller: _taxNameController,
              decoration: const InputDecoration(
                labelText: 'ชื่อ-นามสกุล หรือชื่อบริษัท',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taxAddressController,
              decoration: const InputDecoration(
                labelText: 'ที่อยู่สำหรับออกใบกำกับภาษี',
                border: OutlineInputBorder(), // <-- ย้าย border มาไว้ในนี้
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _taxIdController,
              decoration: const InputDecoration(
                labelText: 'เลขประจำตัวผู้เสียภาษี (13 หลัก)',
                border: OutlineInputBorder(),
              ),
              maxLength: 13,
              keyboardType: TextInputType.number,
            ),
          ],

          // --- สิ้นสุดส่วนใบกำกับภาษี ---
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _calculateAndProceed,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'ตรวจสอบราคาและดำเนินการต่อ',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityIndicator() {
    if (_isCheckingSpots) {
      return const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(width: 16),
          Text('กำลังตรวจสอบ...'),
        ],
      );
    }
    if (_availableSpots != null) {
      final color = _availableSpots! > 10
          ? Colors.green
          : (_availableSpots! > 0 ? Colors.orange : Colors.red);
      final text = _availableSpots! > 0
          ? 'จำนวนช่องจอดที่ว่าง: $_availableSpots ช่อง'
          : 'ที่จอดรถเต็มแล้ว';
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}
