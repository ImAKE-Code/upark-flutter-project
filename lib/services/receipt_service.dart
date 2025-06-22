import 'dart:math';
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:barcode/barcode.dart' as bc;
import '../config/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReceiptService {
  static Future<Uint8List> generateReceipt(
      Map<String, dynamic> bookingData) async {
    final pdf = pw.Document();

    final fontTheme = pw.ThemeData.withFont(
      base: pw.Font.ttf(await rootBundle.load("assets/fonts/THSarabunNew.ttf")),
      bold: pw.Font.ttf(
          await rootBundle.load("assets/fonts/THSarabunNew-Bold.ttf")),
      italic: pw.Font.ttf(
          await rootBundle.load("assets/fonts/THSarabunNew-Italic.ttf")),
      boldItalic: pw.Font.ttf(
          await rootBundle.load("assets/fonts/THSarabunNew-BoldItalic.ttf")),
    );

    final logoImage = pw.MemoryImage(
        (await rootBundle.load('assets/images/logo.png')).buffer.asUint8List());
    final stampImage = pw.MemoryImage(
        (await rootBundle.load('assets/images/company_stamp.png'))
            .buffer
            .asUint8List());

    // --- ดึงข้อมูลและคำนวณ ---
    final double grandTotal =
        (bookingData['totalCost'] as num? ?? 0).toDouble();
    final double discount =
        (bookingData['discountAmount'] as num? ?? 0).toDouble();
    final totalAfterDiscount = grandTotal - discount;
    final double subTotal = totalAfterDiscount / 1.07;
    final double vatAmount = totalAfterDiscount - subTotal;

    final String bookingId = bookingData['id'] ?? 'N/A';
    final issueDate = bookingData['createdAt'] as Timestamp? ?? Timestamp.now();
    final String formattedIssueDate =
        DateFormat('d MMMM yyyy', 'th_TH').format(issueDate.toDate());
    final documentStatus = "ต้นฉบับ (ชำระเงินแล้ว)";

    final String customerName = bookingData['taxName'] ?? '';
    final String customerAddress = bookingData['taxAddress'] ?? '';
    final String customerTaxId = bookingData['taxId'] ?? '';
    final String plateNumber = bookingData['plateNumber'] ?? 'N/A';
    final String province = bookingData['province'] ?? '';
    final int totalDays = bookingData['totalDays'] ?? 0;
    final int remainingHours = bookingData['remainingHours'] ?? 0;
    final double dailyRate = (bookingData['dailyRate'] as num? ?? 0).toDouble();
    final double hourlyRate =
        (bookingData['hourlyRate'] as num? ?? 0).toDouble();
    final double shuttleBasePrice =
        (bookingData['shuttleBasePrice'] as num? ?? 0).toDouble();
    final double shuttlePerPersonPrice =
        (bookingData['shuttlePerPersonPrice'] as num? ?? 0).toDouble();
    final String shuttleType = bookingData['shuttleType'] ?? 'NONE';
    final int passengerCount = bookingData['passengerCount'] ?? 0;

    pdf.addPage(
      pw.Page(
        theme: fontTheme,
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          final List<List<String>> lineItems = [];
          int itemNumber = 1;
          if (totalDays > 0) {
            lineItems.add([
              (itemNumber++).toString(),
              'ค่าบริการที่จอดรถ - รายวัน',
              totalDays.toString(),
              dailyRate.toStringAsFixed(2),
              (totalDays * dailyRate).toStringAsFixed(2)
            ]);
          }
          if (remainingHours > 0) {
            lineItems.add([
              (itemNumber++).toString(),
              'ค่าบริการที่จอดรถ - รายชั่วโมง',
              remainingHours.toString(),
              hourlyRate.toStringAsFixed(2),
              (remainingHours * hourlyRate).toStringAsFixed(2)
            ]);
          }
          // --- Logic ใหม่สำหรับแจกแจงค่าบริการรถรับส่ง ---
          if (shuttleType != 'NONE') {
            int tripCount = (shuttleType == 'ROUND_TRIP') ? 2 : 1;
            String tripDescription = '';
            switch (shuttleType) {
              case 'ONEWAY_DEPART':
                tripDescription = ' (เฉพาะขาไป)';
                break;
              case 'ONEWAY_RETURN':
                tripDescription = ' (เฉพาะขากลับ)';
                break;
              case 'ROUND_TRIP':
                tripDescription = ' (ไป-กลับ)';
                break;
            }

            // เพิ่มค่าบริการพื้นฐาน
            if (shuttleBasePrice > 0) {
              lineItems.add([
                (itemNumber++).toString(),
                'ค่าบริการรถรับส่งพื้นฐาน$tripDescription',
                tripCount.toString(),
                shuttleBasePrice.toStringAsFixed(2),
                (shuttleBasePrice * tripCount).toStringAsFixed(2)
              ]);
            }

            // เพิ่มค่าบริการผู้โดยสารเพิ่มเติม
            if (passengerCount > 1 && shuttlePerPersonPrice > 0) {
              final additionalPassengers = passengerCount - 1;
              lineItems.add([
                (itemNumber++).toString(),
                'ค่าบริการผู้โดยสารเพิ่มเติม$tripDescription',
                (additionalPassengers * tripCount)
                    .toString(), // จำนวนคน x จำนวนเที่ยว
                shuttlePerPersonPrice.toStringAsFixed(2),
                (additionalPassengers * tripCount * shuttlePerPersonPrice)
                    .toStringAsFixed(2)
              ]);
            }
          }
          // ---------------------------------------------

          return pw.Column(
            children: [
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(AppConstants.companyName,
                              style: pw.TextStyle(
                                  fontWeight: pw.FontWeight.bold,
                                  fontSize: 18)),
                          pw.Text('ที่อยู่: ${AppConstants.companyAddress}',
                              style: const pw.TextStyle(fontSize: 12)),
                          pw.Text(
                              'เลขประจำตัวผู้เสียภาษี: ${AppConstants.companyTaxId}',
                              style: const pw.TextStyle(fontSize: 12)),
                        ]),
                    pw.SizedBox(
                        height: 80, width: 80, child: pw.Image(logoImage)),
                  ]),
              pw.SizedBox(height: 12),
              pw.Center(
                  child: pw.Column(children: [
                pw.Text('ใบกำกับภาษี / ใบเสร็จรับเงิน',
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 20)),
                pw.Text(documentStatus,
                    style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold, fontSize: 14)),
              ])),
              pw.SizedBox(height: 12),
              pw.Container(
                decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.black, width: 0.5)),
                padding: const pw.EdgeInsets.all(8),
                child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Expanded(
                          flex: 2,
                          child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text('ข้อมูลลูกค้า:',
                                    style: pw.TextStyle(
                                        fontWeight: pw.FontWeight.bold)),
                                pw.Text(customerName.isNotEmpty
                                    ? customerName
                                    : '-'),
                                pw.Text(
                                    'ที่อยู่: ${customerAddress.isNotEmpty ? customerAddress : '-'}',
                                    maxLines: 2),
                                pw.Text(
                                    'เลขประจำตัวผู้เสียภาษี: ${customerTaxId.isNotEmpty ? customerTaxId : '-'}'),
                              ])),
                      pw.SizedBox(width: 20),
                      pw.Expanded(
                          flex: 1,
                          child: pw.Column(
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.Text(
                                    'เลขที่: ${bookingId.substring(0, 10)}'),
                                pw.Text('วันที่: $formattedIssueDate'),
                              ])),
                    ]),
              ),
              pw.SizedBox(height: 12),
              pw.TableHelper.fromTextArray(
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                headerDecoration:
                    const pw.BoxDecoration(color: PdfColors.grey200),
                headers: [
                  'ลำดับ',
                  'รายการ',
                  'จำนวน',
                  'หน่วยละ',
                  'จำนวนเงิน (บาท)'
                ],
                cellAlignments: {
                  0: pw.Alignment.center,
                  2: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight
                },
                data: lineItems,
              ),
              pw.SizedBox(height: 20),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                pw.Container(
                    width: 280,
                    child: pw.Column(children: [
                      _buildSummaryRow('รวมเป็นเงิน',
                          (totalAfterDiscount + discount).toStringAsFixed(2)),
                      _buildSummaryRow(
                          'หัก ส่วนลด', discount.toStringAsFixed(2)),
                      _buildSummaryRow(
                          'ยอดคงเหลือ', totalAfterDiscount.toStringAsFixed(2)),
                      _buildSummaryRow(
                          'มูลค่าก่อนภาษี', subTotal.toStringAsFixed(2)),
                      _buildSummaryRow(
                          'ภาษีมูลค่าเพิ่ม 7%', vatAmount.toStringAsFixed(2)),
                    ]))
              ]),
              pw.Divider(thickness: 1.5),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.end, children: [
                pw.Container(
                    width: 280,
                    padding: const pw.EdgeInsets.all(4),
                    decoration:
                        const pw.BoxDecoration(color: PdfColors.grey200),
                    child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text('ยอดรวมสุทธิ',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                          pw.Text('฿${grandTotal.toStringAsFixed(2)}',
                              style:
                                  pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                        ]))
              ]),
              pw.Spacer(),
              pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Column(mainAxisSize: pw.MainAxisSize.min, children: [
                      pw.BarcodeWidget(
                          barcode: bc.Barcode.qrCode(),
                          data: bookingId,
                          width: 60,
                          height: 60),
                      pw.SizedBox(height: 4),
                      pw.Text('Scan for details'),
                    ]),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                        child: _buildSignatureBox(
                            'ผู้ใช้บริการ', formattedIssueDate,
                            stamp: null)),
                    pw.SizedBox(width: 20),
                    pw.Expanded(
                        child: _buildSignatureBox(
                            'ผู้รับเงิน/อนุมัติ', formattedIssueDate,
                            stamp: stampImage)),
                  ]),
            ],
          );
        },
      ),
    );
    return pdf.save();
  }

  static pw.Widget _buildSummaryRow(String title, String value,
      {bool isBold = false}) {
    final style = isBold ? pw.TextStyle(fontWeight: pw.FontWeight.bold) : null;
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2.0),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(title, style: style),
          pw.Text('$value บาท', style: style),
        ],
      ),
    );
  }

  static pw.Widget _buildSignatureBox(String title, String date,
      {pw.MemoryImage? stamp}) {
    return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.SizedBox(
              height: 80,
              width: 180,
              child: pw.Stack(alignment: pw.Alignment.center, children: [
                pw.Positioned(
                    left: 0,
                    right: 0,
                    bottom: 25,
                    child: pw.Text(
                        'ลงชื่อ: ............................................')),
                if (stamp != null)
                  pw.Transform(
                    transform: Matrix4.rotationZ(-pi / 15.0),
                    origin: const PdfPoint(10, 10),
                    child: pw.Image(stamp,
                        height: 4.1 * PdfPageFormat.cm,
                        width: 2.4 * PdfPageFormat.cm,
                        fit: pw.BoxFit.contain),
                  ),
              ])),
          pw.SizedBox(height: 4),
          pw.Text('($title)'),
          pw.SizedBox(height: 4),
          pw.Text(date.isNotEmpty
              ? 'วันที่: $date'
              : 'วันที่: ......./......./.........'),
        ]);
  }
}
