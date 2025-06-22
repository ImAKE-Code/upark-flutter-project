// ---- lib/src/pages/admin_settings_page.dart (ฉบับราคา 2 ระดับ + สวิตช์เปิด/ปิด) ----

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminSettingsPage extends StatefulWidget {
  const AdminSettingsPage({super.key});

  @override
  State<AdminSettingsPage> createState() => _AdminSettingsPageState();
}

class _AdminSettingsPageState extends State<AdminSettingsPage> {
  final String _configDocId = 'Nez0wZtFS8JgS9iWorp5';
  final _formKey = GlobalKey<FormState>();

  // --- 1. กลับมาใช้ Controller เดิม + เพิ่ม State สำหรับสวิตช์ ---
  bool _isShuttleEnabled = true;
  final _shuttleBasePriceController = TextEditingController();
  final _shuttlePerPersonPriceController = TextEditingController();

  final _totalCapacityController = TextEditingController();
  final _dailyRateController = TextEditingController();
  final _hourlyRateController = TextEditingController();
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('config').doc(_configDocId).get();
      if (doc.exists) {
        final data = doc.data()!;
        
        // --- 2. โหลดข้อมูลทั้งหมดจาก Firestore ---
        setState(() {
          _isShuttleEnabled = data['isShuttleEnabled'] ?? true; 
        });
        _shuttleBasePriceController.text = (data['shuttleBasePrice'] ?? 0).toString();
        _shuttlePerPersonPriceController.text = (data['shuttlePerPersonPrice'] ?? 0).toString();
        
        _totalCapacityController.text = (data['totalCapacity'] ?? 0).toString();
        _dailyRateController.text = (data['dailyRate'] ?? 0).toString();
        _hourlyRateController.text = (data['hourlyRate'] ?? 0).toString();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: $e')));
      }
    } finally {
      if (mounted) {
        setState(() { _isLoading = false; });
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() { _isLoading = true; });
      try {
        // --- 3. เตรียมข้อมูลทั้งหมดเพื่อบันทึก ---
        final updatedData = {
          'isShuttleEnabled': _isShuttleEnabled,
          'shuttleBasePrice': double.parse(_shuttleBasePriceController.text),
          'shuttlePerPersonPrice': double.parse(_shuttlePerPersonPriceController.text),

          'totalCapacity': int.parse(_totalCapacityController.text),
          'dailyRate': double.parse(_dailyRateController.text),
          'hourlyRate': double.parse(_hourlyRateController.text),
        };

        await FirebaseFirestore.instance.collection('config').doc(_configDocId).update(updatedData);

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('บันทึกการเปลี่ยนแปลงสำเร็จ'), backgroundColor: Colors.green),
        );
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('เกิดข้อผิดพลาดในการบันทึก: $e'), backgroundColor: Colors.red));
        }
      } finally {
        if (mounted) {
          setState(() { _isLoading = false; });
        }
      }
    }
  }

  @override
  void dispose() {
    _shuttleBasePriceController.dispose();
    _shuttlePerPersonPriceController.dispose();
    _totalCapacityController.dispose();
    _dailyRateController.dispose();
    _hourlyRateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.all(16.0),
                children: [
                  // --- ส่วนตั้งค่าทั่วไปและราคา (เหมือนเดิม) ---
                  _buildSectionTitle('ตั้งค่าทั่วไป'),
                  const SizedBox(height: 24),
                  _buildTextField(_totalCapacityController, 'จำนวนช่องจอดทั้งหมด (คัน)'),
                  const Divider(height: 48),
                  _buildSectionTitle('ตั้งค่าราคาบริการ'),
                  const SizedBox(height: 24),
                  _buildTextField(_dailyRateController, 'อัตราค่าจอดรายวัน (บาท)'),
                  const SizedBox(height: 16),
                  _buildTextField(_hourlyRateController, 'อัตราค่าจอดรายชั่วโมง (บาท)'),
                  const Divider(height: 48),

                  // --- 4. UI ส่วนตั้งค่ารถรับส่งที่กลับมาใช้ราคา 2 ระดับ ---
                  _buildSectionTitle('ตั้งค่ารถรับส่ง'),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: const Text('เปิดใช้งานบริการรถรับส่ง'),
                    value: _isShuttleEnabled,
                    onChanged: (bool value) {
                      setState(() {
                        _isShuttleEnabled = value;
                      });
                    },
                    secondary: const Icon(Icons.airport_shuttle),
                    activeColor: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 16),

                  if (_isShuttleEnabled) ...[
                    // --- เปลี่ยนข้อความ Label ที่นี่ ---
                    _buildTextField(
                      _shuttleBasePriceController,
                      'ราคาต่อเที่ยวสำหรับคนแรก (บาท)',
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      _shuttlePerPersonPriceController,
                      'ราคาต่อเที่ยวสำหรับคนที่ 2 ขึ้นไป (บาท)',
                    ),
                  ],
                  
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isLoading ? null : _saveSettings,
                      icon: const Icon(Icons.save),
                      label: const Text('บันทึกการเปลี่ยนแปลง'),
                      style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}'))],
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'กรุณากรอกข้อมูล';
          }
          if (double.tryParse(value) == null) {
            return 'กรุณากรอกเป็นตัวเลขเท่านั้น';
          }
          return null;
        },
      ),
    );
  }
}