import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class AdminFaqManagementPage extends StatefulWidget {
  const AdminFaqManagementPage({super.key});

  @override
  State<AdminFaqManagementPage> createState() => _AdminFaqManagementPageState();
}

class _AdminFaqManagementPageState extends State<AdminFaqManagementPage> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final _answerController = TextEditingController();
  final _orderController = TextEditingController();

  @override
  void dispose() {
    _questionController.dispose();
    _answerController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _showFaqDialog({DocumentSnapshot? faqDoc}) async {
    String dialogTitle = 'เพิ่มคำถามใหม่';
    if (faqDoc != null) {
      dialogTitle = 'แก้ไขคำถาม';
      final data = faqDoc.data() as Map<String, dynamic>;
      _questionController.text = data['question'] ?? '';
      _answerController.text = data['answer'] ?? '';
      _orderController.text = (data['order'] ?? 0).toString();
    } else {
      _questionController.clear();
      _answerController.clear();
      _orderController.clear();
    }

    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                        labelText: 'คำถาม', border: OutlineInputBorder()),
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'กรุณาใส่คำถาม'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _answerController,
                    decoration: const InputDecoration(
                        labelText: 'คำตอบ', border: OutlineInputBorder()),
                    maxLines: 3,
                    validator: (value) => (value == null || value.isEmpty)
                        ? 'กรุณาใส่คำตอบ'
                        : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _orderController,
                    decoration: const InputDecoration(
                        labelText: 'ลำดับการแสดงผล',
                        border: OutlineInputBorder()),
                    keyboardType: TextInputType.number,
                    validator: (value) => (value == null ||
                            value.isEmpty ||
                            int.tryParse(value) == null)
                        ? 'กรุณาใส่ลำดับเป็นตัวเลข'
                        : null,
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('ยกเลิก')),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final faqData = {
                    'question': _questionController.text,
                    'answer': _answerController.text,
                    'order': int.parse(_orderController.text),
                  };
                  if (faqDoc == null) {
                    await FirebaseFirestore.instance
                        .collection('faqs')
                        .add(faqData);
                  } else {
                    await FirebaseFirestore.instance
                        .collection('faqs')
                        .doc(faqDoc.id)
                        .update(faqData);
                  }
                  if (mounted) Navigator.of(context).pop();
                }
              },
              child: const Text('บันทึก'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('faqs')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('ยังไม่มีคำถามที่พบบ่อย'));
          }

          final faqs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(8.0),
            itemCount: faqs.length,
            itemBuilder: (context, index) {
              final faqDoc = faqs[index];
              final faqData = faqDoc.data() as Map<String, dynamic>;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: ListTile(
                  title: Text(faqData['question'] ?? 'N/A'),
                  subtitle: Text(faqData['answer'] ?? 'N/A',
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.edit, color: Colors.blueGrey[600]),
                        onPressed: () => _showFaqDialog(faqDoc: faqDoc),
                      ),
                      IconButton(
                        icon: Icon(Icons.delete, color: Colors.red[400]),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('ยืนยันการลบ'),
                              content: const Text(
                                  'คุณแน่ใจหรือไม่ว่าต้องการลบคำถามนี้?'),
                              actions: [
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(false),
                                    child: const Text('ยกเลิก')),
                                TextButton(
                                    onPressed: () =>
                                        Navigator.of(context).pop(true),
                                    child: const Text('ลบ',
                                        style: TextStyle(color: Colors.red))),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await FirebaseFirestore.instance
                                .collection('faqs')
                                .doc(faqDoc.id)
                                .delete();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showFaqDialog,
        tooltip: 'เพิ่มคำถามใหม่',
        child: const Icon(Icons.add),
      ),
    );
  }
}
