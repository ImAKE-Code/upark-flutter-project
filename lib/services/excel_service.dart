// ---- lib/services/excel_service.dart (ฉบับแก้ไข const) ----

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:excel/excel.dart';
import 'package:intl/intl.dart';
import 'package:universal_html/html.dart' as html;
import 'package:flutter/foundation.dart'; // Import สำหรับ kDebugMode

class ExcelService {
  static Future<void> exportExpensesToExcel(
    List<QueryDocumentSnapshot> expenses,
    int year,
    int month,
  ) async {
    try {
      final excel = Excel.createExcel();
      final Sheet sheet = excel[excel.getDefaultSheet()!];

      // --- สร้าง Header (ลบ const ออก) ---
      sheet.appendRow([
        TextCellValue('วันที่'),
        TextCellValue('รายการ'),
        TextCellValue('หมวดหมู่'),
        TextCellValue('จำนวนเงิน (บาท)'),
      ]);

      // --- วนลูปเพื่อเพิ่มข้อมูลแต่ละแถว ---
      double totalAmount = 0;
      for (var doc in expenses) {
        final data = doc.data() as Map<String, dynamic>;
        final timestamp = (data['createdAt'] as Timestamp?)?.toDate();
        final formattedDate = timestamp != null
            ? DateFormat('yyyy-MM-dd').format(timestamp)
            : 'N/A';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;

        sheet.appendRow([
          TextCellValue(formattedDate),
          TextCellValue(data['item'] ?? 'N/A'),
          TextCellValue(data['category'] ?? 'N/A'),
          DoubleCellValue(amount), // เอา const ออก
        ]);
        totalAmount += amount;
      }

      // --- เพิ่มแถวสรุปรวม (ลบ const ออก) ---
      sheet.appendRow([]); // เว้นบรรทัด
      sheet.appendRow([
        TextCellValue(''),
        TextCellValue(''),
        TextCellValue('ยอดรวม'),
        DoubleCellValue(totalAmount),
      ]);

      // --- บันทึกและสั่งดาวน์โหลดไฟล์ ---
      final fileName = 'expenses_${year}_$month.xlsx';
      final fileBytes = excel.save(fileName: fileName);

      if (fileBytes != null) {
        final blob = html.Blob([
          fileBytes
        ], 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        final url = html.Url.createObjectUrlFromBlob(blob);
        final anchor = html.AnchorElement(href: url)
          ..setAttribute("download", fileName)
          ..click();
        html.Url.revokeObjectUrl(url);
      }
    } catch (e) {
      // ใช้ kDebugMode เพื่อให้ print ทำงานเฉพาะตอนพัฒนา
      if (kDebugMode) {
        print('Error exporting to Excel: $e');
      }
    }
  }
}
