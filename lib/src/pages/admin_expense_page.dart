// ---- lib/src/pages/admin_expense_page.dart (ฉบับสมบูรณ์ แก้ไข Scaffold ซ้อน) ----

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../services/excel_service.dart';

class AdminExpensePage extends StatefulWidget {
  const AdminExpensePage({super.key});

  @override
  State<AdminExpensePage> createState() => _AdminExpensePageState();
}

class _AdminExpensePageState extends State<AdminExpensePage> {
  // --- State สำหรับ Filter ---
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  final List<int> _years =
      List.generate(5, (index) => DateTime.now().year - index);
  final List<String> _months = [
    'มกราคม',
    'กุมภาพันธ์',
    'มีนาคม',
    'เมษายน',
    'พฤษภาคม',
    'มิถุนายน',
    'กรกฎาคม',
    'สิงหาคม',
    'กันยายน',
    'ตุลาคม',
    'พฤศจิกายน',
    'ธันวาคม'
  ];
  final List<String> _expenseCategories = [
    'เงินเดือน',
    'ค่าน้ำมัน',
    'ค่าซ่อมบำรุง',
    'ค่าการตลาด',
    'ค่าเช่า',
    'ค่าสาธารณูปโภค (น้ำ/ไฟ)',
    'อื่นๆ'
  ];

  // --- ฟังก์ชันสำหรับสร้าง Stream แบบไดนามิก ---
  Stream<QuerySnapshot> _getExpensesStream() {
    final DateTime startDate = DateTime(_selectedYear, _selectedMonth, 1);
    final DateTime endDate = (_selectedMonth == 12)
        ? DateTime(_selectedYear + 1, 1, 1)
        : DateTime(_selectedYear, _selectedMonth + 1, 1);

    return FirebaseFirestore.instance
        .collection('expenses')
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
        .where('createdAt', isLessThan: Timestamp.fromDate(endDate))
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // --- ฟังก์ชันสำหรับ Export ---
  Future<void> _exportFilteredData() async {
    final stream = _getExpensesStream();
    final snapshot = await stream.first;
    final expenses = snapshot.docs;

    if (expenses.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('ไม่มีข้อมูลให้ Export ในช่วงเวลาที่เลือก'),
              backgroundColor: Colors.orange),
        );
      }
      return;
    }
    await ExcelService.exportExpensesToExcel(
        expenses, _selectedYear, _selectedMonth);
  }

  // --- ฟังก์ชันสำหรับแสดง Dialog เพิ่ม/แก้ไข ---
  void _showAddExpenseDialog({DocumentSnapshot? expenseDoc}) {
    final formKey = GlobalKey<FormState>();
    final itemController = TextEditingController();
    final amountController = TextEditingController();
    String? selectedCategory;

    bool isEditing = expenseDoc != null;

    if (isEditing) {
      final data = expenseDoc.data() as Map<String, dynamic>;
      itemController.text = data['item'] ?? '';
      amountController.text = (data['amount'] ?? 0).toString();
      selectedCategory = data['category'];
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(isEditing ? 'แก้ไขรายการ' : 'เพิ่มรายการค่าใช้จ่าย'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: itemController,
                        decoration: const InputDecoration(labelText: 'รายการ'),
                        validator: (value) => (value == null || value.isEmpty)
                            ? 'กรุณากรอกชื่อรายการ'
                            : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: amountController,
                        decoration:
                            const InputDecoration(labelText: 'จำนวนเงิน (บาท)'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                              RegExp(r'^\d+\.?\d{0,2}'))
                        ],
                        validator: (value) {
                          if (value == null || value.isEmpty)
                            return 'กรุณากรอกจำนวนเงิน';
                          if (double.tryParse(value) == null)
                            return 'กรุณากรอกเป็นตัวเลข';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: selectedCategory,
                        hint: const Text('เลือกหมวดหมู่'),
                        items: _expenseCategories.map((String category) {
                          return DropdownMenuItem<String>(
                              value: category, child: Text(category));
                        }).toList(),
                        onChanged: (newValue) {
                          setDialogState(() {
                            selectedCategory = newValue;
                          });
                        },
                        validator: (value) =>
                            value == null ? 'กรุณาเลือกหมวดหมู่' : null,
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                if (isEditing)
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'ลบรายการนี้',
                    onPressed: () {
                      Navigator.of(context).pop();
                      _deleteExpense(expenseDoc.id);
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
                      _submitExpense(
                        item: itemController.text,
                        amount: double.parse(amountController.text),
                        category: selectedCategory!,
                        docId: isEditing ? expenseDoc.id : null,
                      );
                      Navigator.of(context).pop();
                    }
                  },
                  child: Text(isEditing ? 'บันทึก' : 'เพิ่ม'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // --- ฟังก์ชันสำหรับบันทึกข้อมูล ---
  Future<void> _submitExpense(
      {required String item,
      required double amount,
      required String category,
      String? docId}) async {
    // ... โค้ด submitExpense เหมือนเดิม ...
  }

  // --- ฟังก์ชันสำหรับลบข้อมูล ---
  Future<void> _deleteExpense(String docId) async {
    // ... โค้ด deleteExpense เหมือนเดิม ...
  }

  @override
  Widget build(BuildContext context) {
    // --- เอา Scaffold ที่ครอบทั้งหมดออก และคืนค่าเป็น Column โดยตรง ---
    return Column(
      children: [
        // ส่วนของ Filter และปุ่ม Export
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedYear,
                      decoration: const InputDecoration(
                          labelText: 'ปี', border: OutlineInputBorder()),
                      items: _years
                          .map((year) => DropdownMenuItem(
                              value: year, child: Text(year.toString())))
                          .toList(),
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _selectedYear = value);
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: _selectedMonth,
                      decoration: const InputDecoration(
                          labelText: 'เดือน', border: OutlineInputBorder()),
                      items: List.generate(
                          12,
                          (index) => DropdownMenuItem(
                              value: index + 1, child: Text(_months[index]))),
                      onChanged: (value) {
                        if (value != null)
                          setState(() => _selectedMonth = value);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.download_for_offline),
                  label: const Text('Export to Excel'),
                  onPressed: _exportFilteredData,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),

        // StreamBuilder สำหรับแสดงผล
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _getExpensesStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting)
                return const Center(child: CircularProgressIndicator());
              if (snapshot.hasError)
                return Center(child: Text('เกิดข้อผิดพลาด: ${snapshot.error}'));
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty)
                return _buildEmptyState(isFiltered: true);

              final expenses = snapshot.data!.docs;
              double totalAmount = expenses.fold(
                  0.0,
                  (sum, doc) =>
                      sum +
                      ((doc.data() as Map<String, dynamic>)['amount'] as num? ??
                          0.0));

              // --- สร้าง Scaffold ใหม่ข้างในนี้ เพื่อให้ FAB ทำงานได้ถูกต้อง ---
              return Scaffold(
                body: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildSummaryCard(
                          'ยอดรวมเดือน ${_months[_selectedMonth - 1]}',
                          totalAmount),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.only(top: 8.0),
                        itemCount: expenses.length,
                        itemBuilder: (context, index) {
                          final expenseDoc = expenses[index];
                          final expense =
                              expenseDoc.data() as Map<String, dynamic>;
                          return ListTile(
                            leading: const Icon(Icons.receipt_long_outlined),
                            title: Text(expense['item'] ?? 'N/A'),
                            subtitle: Text(
                                '${expense['category'] ?? 'N/A'} - ${DateFormat('d MMM yy', 'th_TH').format((expense['createdAt'] ?? Timestamp.now()).toDate())}'),
                            trailing: Text(
                                '${NumberFormat("#,##0.00").format((expense['amount'] as num?)?.toDouble() ?? 0.0)} ฿',
                                style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.red,
                                    fontWeight: FontWeight.w500)),
                            onTap: () =>
                                _showAddExpenseDialog(expenseDoc: expenseDoc),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => _showAddExpenseDialog(),
                  tooltip: 'เพิ่มรายการค่าใช้จ่าย',
                  child: const Icon(Icons.add),
                ),
              );
              // --------------------------------------------------------
            },
          ),
        ),
      ],
    );
  }

  // --- Helper Widgets ---
  Widget _buildSummaryCard(String title, double amount) {
    final formattedAmount = NumberFormat("#,##0.00", "en_US").format(amount);
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(title,
                style: TextStyle(fontSize: 16, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('$formattedAmount ฿',
                style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.red)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState({bool isFiltered = false}) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.money_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
              isFiltered
                  ? 'ไม่พบข้อมูลในเดือน/ปีที่เลือก'
                  : 'ยังไม่มีรายการค่าใช้จ่าย',
              style: TextStyle(color: Colors.grey[600], fontSize: 18)),
          if (!isFiltered) ...[
            const SizedBox(height: 20),
            FloatingActionButton.extended(
              onPressed: () => _showAddExpenseDialog(),
              label: const Text('เพิ่มรายการแรก'),
              icon: const Icon(Icons.add),
            )
          ]
        ],
      ),
    );
  }
}
