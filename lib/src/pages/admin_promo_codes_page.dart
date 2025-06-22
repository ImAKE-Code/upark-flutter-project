// ---- lib/src/pages/admin_promo_codes_page.dart (ฉบับสมบูรณ์) ----

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class AdminPromoCodesPage extends StatefulWidget {
  const AdminPromoCodesPage({super.key});

  @override
  State<AdminPromoCodesPage> createState() => _AdminPromoCodesPageState();
}

class _AdminPromoCodesPageState extends State<AdminPromoCodesPage> {
  void _showPromoCodeDialog({DocumentSnapshot? promoDoc}) {
    final formKey = GlobalKey<FormState>();
    final codeController = TextEditingController();
    final discountValueController = TextEditingController();
    final usageLimitController = TextEditingController();

    String discountType = 'PERCENTAGE';
    bool isActive = true;
    DateTime? startDate = DateTime.now();
    DateTime? expiresAt;

    bool isEditing = promoDoc != null;

    if (isEditing) {
      final data = promoDoc!.data() as Map<String, dynamic>;
      codeController.text = promoDoc.id;
      discountValueController.text = (data['discountValue'] ?? 0).toString();
      usageLimitController.text = (data['usageLimit'] ?? '').toString();
      discountType = data['discountType'] ?? 'PERCENTAGE';
      isActive = data['isActive'] ?? true;
      if (data['startDate'] != null) {
        startDate = (data['startDate'] as Timestamp).toDate();
      }
      if (data['expiresAt'] != null) {
        expiresAt = (data['expiresAt'] as Timestamp).toDate();
      }
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                  isEditing ? 'แก้ไขโปรโมชั่นโค้ด' : 'สร้างโปรโมชั่นโค้ดใหม่'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextFormField(
                          controller: codeController,
                          readOnly: isEditing,
                          decoration: InputDecoration(
                            labelText: 'โค้ด (เช่น SUMMER2025)',
                            filled: isEditing,
                            fillColor: isEditing ? Colors.grey[200] : null,
                          ),
                          textCapitalization: TextCapitalization.characters,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'กรุณากรอกโค้ด';
                            }
                            if (value.contains(' ')) {
                              return 'โค้ดห้ามมีเว้นวรรค';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<String>(
                          value: discountType,
                          decoration:
                              const InputDecoration(labelText: 'ประเภทส่วนลด'),
                          items: const [
                            DropdownMenuItem(
                                value: 'PERCENTAGE',
                                child: Text('เปอร์เซ็นต์ (%)')),
                            DropdownMenuItem(
                                value: 'FIXED_AMOUNT',
                                child: Text('จำนวนเงิน (บาท)')),
                          ],
                          onChanged: (newValue) {
                            setDialogState(() {
                              discountType = newValue!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: discountValueController,
                          decoration:
                              const InputDecoration(labelText: 'มูลค่าส่วนลด'),
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                                RegExp(r'^\d+\.?\d{0,2}'))
                          ],
                          validator: (value) {
                            if (value == null || value.isEmpty)
                              return 'กรุณากรอกมูลค่า';
                            if (double.tryParse(value) == null)
                              return 'กรุณากรอกเป็นตัวเลข';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: usageLimitController,
                          decoration: const InputDecoration(
                              labelText:
                                  'จำกัดจำนวนครั้งที่ใช้ (เว้นว่างถ้าไม่จำกัด)'),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildDatePickerRow('วันเริ่มต้น:', startDate, (date) {
                          setDialogState(() => startDate = date);
                        }, context),
                        _buildDatePickerRow('วันหมดอายุ:', expiresAt, (date) {
                          setDialogState(() => expiresAt = date);
                        }, context),
                        SwitchListTile(
                            title: const Text('เปิดใช้งาน'),
                            value: isActive,
                            onChanged: (value) {
                              setDialogState(() => isActive = value);
                            }),
                      ],
                    ),
                  ),
                ),
              ),
              actions: [
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'ลบโค้ดนี้',
                    onPressed: () {
                      Navigator.of(context).pop();
                      _deletePromoCode(promoDoc.id);
                    },
                  ),
                const Spacer(),
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _submitPromoCode(
                        code: codeController.text.toUpperCase().trim(),
                        discountType: discountType,
                        discountValue:
                            double.parse(discountValueController.text),
                        isActive: isActive,
                        isEditing: isEditing,
                        usageLimit: usageLimitController.text,
                        startDate: startDate,
                        expiresAt: expiresAt,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(isEditing ? 'บันทึก' : 'สร้าง'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _submitPromoCode({
    required String code,
    required String discountType,
    required double discountValue,
    required bool isActive,
    required bool isEditing,
    String? usageLimit,
    DateTime? startDate,
    DateTime? expiresAt,
  }) async {
    final data = {
      'discountType': discountType,
      'discountValue': discountValue,
      'isActive': isActive,
      'createdAt': isEditing
          ? FieldValue.serverTimestamp()
          : FieldValue.serverTimestamp(), // อัปเดตเวลาเมื่อแก้ไข
      'timesUsed':
          isEditing ? FieldValue.increment(0) : 0, // ไม่รีเซ็ตค่าที่ใช้ไปแล้ว
      'usageLimit': (usageLimit != null && usageLimit.isNotEmpty)
          ? int.parse(usageLimit)
          : null,
      'startDate': startDate != null ? Timestamp.fromDate(startDate) : null,
      'expiresAt': expiresAt != null ? Timestamp.fromDate(expiresAt) : null,
    };

    data.removeWhere((key, value) => value == null);

    try {
      await FirebaseFirestore.instance
          .collection('promo_codes')
          .doc(code)
          .set(data, SetOptions(merge: true));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('บันทึกข้อมูลสำเร็จ'),
            backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _deletePromoCode(String code) async {
    try {
      await FirebaseFirestore.instance
          .collection('promo_codes')
          .doc(code)
          .delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('ลบโค้ดสำเร็จ'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('เกิดข้อผิดพลาดในการลบ: $e'),
            backgroundColor: Colors.red));
      }
    }
  }

  Widget _buildDatePickerRow(String title, DateTime? selectedDate,
      Function(DateTime?) onDateChanged, BuildContext dialogContext) {
    return Row(
      children: [
        Expanded(child: Text(title)),
        Expanded(
          flex: 2,
          child: Text(selectedDate == null
              ? 'ไม่กำหนด'
              : DateFormat('d MMM yy', 'th_TH').format(selectedDate)),
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today_outlined),
          tooltip: 'เลือกวันที่',
          onPressed: () async {
            final pickedDate = await showDatePicker(
              context: dialogContext,
              initialDate: selectedDate ?? DateTime.now(),
              firstDate: DateTime(2020),
              lastDate: DateTime(2101),
            );
            onDateChanged(pickedDate);
          },
        ),
        if (selectedDate != null)
          IconButton(
            icon: Icon(Icons.clear, color: Colors.grey[600]),
            tooltip: 'ล้างวันที่',
            onPressed: () => onDateChanged(null),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('promo_codes')
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
            return Center(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.confirmation_number_outlined,
                        size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('ยังไม่มีโปรโมชั่นโค้ด',
                        style: TextStyle(fontSize: 18, color: Colors.grey)),
                    const SizedBox(height: 20),
                    FloatingActionButton.extended(
                      onPressed: () => _showPromoCodeDialog(),
                      label: const Text('สร้างโค้ดแรก'),
                      icon: const Icon(Icons.add),
                    )
                  ]),
            );
          }

          final promoCodes = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: promoCodes.length,
            itemBuilder: (context, index) {
              final promoDoc = promoCodes[index];
              final data = promoDoc.data() as Map<String, dynamic>;

              final String code = promoDoc.id;
              final String discountType = data['discountType'] ?? 'N/A';
              final double discountValue =
                  (data['discountValue'] as num?)?.toDouble() ?? 0.0;
              final bool isActive = data['isActive'] ?? false;
              final startDate = (data['startDate'] as Timestamp?)?.toDate();
              final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
              final usageLimit = data['usageLimit'] as int?;
              final timesUsed = data['timesUsed'] as int? ?? 0;

              String discountText = '';
              if (discountType == 'PERCENTAGE') {
                discountText = 'ส่วนลด ${discountValue.toStringAsFixed(0)}%';
              } else {
                discountText =
                    'ส่วนลด ${NumberFormat("#,##0.00").format(discountValue)} บาท';
              }

              String durationText = 'ใช้งานได้ตลอด';
              if (startDate != null && expiresAt != null) {
                durationText =
                    'ใช้ได้ ${DateFormat('d/M/yy').format(startDate)} - ${DateFormat('d/M/yy').format(expiresAt)}';
              } else if (startDate != null) {
                durationText =
                    'เริ่มใช้ ${DateFormat('d/M/yy').format(startDate)}';
              } else if (expiresAt != null) {
                durationText =
                    'หมดอายุ ${DateFormat('d/M/yy').format(expiresAt)}';
              }

              String usageText = 'ไม่จำกัดจำนวน';
              if (usageLimit != null) {
                usageText = 'ใช้ไปแล้ว $timesUsed / $usageLimit ครั้ง';
              }

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: ListTile(
                  leading: Icon(
                    isActive ? Icons.check_circle : Icons.cancel,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                  title: Text(code,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16)),
                  subtitle: Text('$discountText\n$durationText\n$usageText'),
                  isThreeLine: true,
                  trailing: Switch(
                    value: isActive,
                    onChanged: (value) {
                      FirebaseFirestore.instance
                          .collection('promo_codes')
                          .doc(code)
                          .update({'isActive': value});
                    },
                  ),
                  onTap: () => _showPromoCodeDialog(promoDoc: promoDoc),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showPromoCodeDialog(),
        tooltip: 'สร้างโปรโมชั่นโค้ด',
        child: const Icon(Icons.add),
      ),
    );
  }
}
