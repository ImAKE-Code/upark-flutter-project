// ---- lib/src/pages/admin_booking_list_page.dart (ฉบับแก้ไข Pagination เป็นแบบปุ่ม และเพิ่ม Filter) ----

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'admin_booking_details_page.dart'; // import หน้า detail ที่ถูกต้อง

class AdminBookingListPage extends StatefulWidget {
  const AdminBookingListPage({super.key});

  @override
  State<AdminBookingListPage> createState() => _AdminBookingListPageState();
}

class _AdminBookingListPageState extends State<AdminBookingListPage> {
  final int _pageSize = 15; // กำหนดจำนวนรายการต่อหน้า
  DocumentSnapshot?
      _nextPageStartingDocument; // เก็บเอกสารสุดท้ายของหน้าปัจจุบัน ใช้สำหรับเริ่มต้นหน้าถัดไป
  List<DocumentSnapshot> _bookings =
      []; // List สำหรับเก็บข้อมูลการจองทั้งหมดที่โหลดมาแล้ว
  bool _isLoadingPage = false; // สถานะกำลังโหลดข้อมูล (ทั้งหน้าแรกและหน้าถัดไป)
  bool _hasMore = true; // มีข้อมูลให้โหลดอีกหรือไม่
  bool _isAdmin = false; // สถานะ Admin

  // เพิ่ม State Variables สำหรับ Filter
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

  // ไม่ต้องใช้ ScrollController แล้ว
  // final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkAdminStatusAndLoadBookings(); // ตรวจสอบสิทธิ์และโหลดข้อมูลเริ่มต้น

    // ลบ _scrollController.addListener ออกไป
    // _scrollController.addListener(() { ... });

    // Listener สำหรับ Auth State Changes (เหมือนเดิม)
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) {
        user.getIdTokenResult(true).then((idTokenResult) {
          if (mounted) {
            final newIsAdminStatus = idTokenResult.claims?['admin'] == true;
            if (_isAdmin != newIsAdminStatus) {
              setState(() {
                _isAdmin = newIsAdminStatus;
                if (_isAdmin) {
                  _resetAndFetchBookings(); // รีโหลดเมื่อสถานะ Admin เปลี่ยนเป็น true
                } else {
                  _bookings.clear();
                  _hasMore = false;
                }
              });
            }
          }
        });
      } else {
        if (mounted) {
          setState(() {
            _isAdmin = false;
            _bookings.clear();
            _hasMore = false;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    // _scrollController.dispose(); // ไม่ต้อง dispose แล้ว
    super.dispose();
  }

  // ฟังก์ชันสำหรับตรวจสอบสถานะ Admin ตั้งแต่แรกและโหลดข้อมูล
  Future<void> _checkAdminStatusAndLoadBookings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && !user.isAnonymous) {
      final idTokenResult = await user.getIdTokenResult(true);
      if (mounted) {
        setState(() {
          _isAdmin = idTokenResult.claims?['admin'] == true;
        });
        if (_isAdmin) {
          _resetAndFetchBookings(); // เรียก _resetAndFetchBookings เพื่อโหลดข้อมูลเริ่มต้นพร้อมฟิลเตอร์
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isAdmin = false;
        });
      }
    }
  }

  // ฟังก์ชันหลักสำหรับ Fetch ข้อมูล (รับพารามิเตอร์เพื่อระบุว่าเป็นการโหลดหน้าถัดไปหรือไม่)
  Future<void> _fetchBookings({bool loadNextPage = false}) async {
    if (!_isAdmin) return;
    // ป้องกันการเรียกซ้ำซ้อน
    if (_isLoadingPage && !loadNextPage) return; // ถ้ากำลังโหลดหน้าแรกอยู่แล้ว

    // ถ้าไม่ใช่การโหลดหน้าถัดไป และข้อมูลไม่หมด แต่มีการโหลดอยู่แล้ว
    if (loadNextPage &&
        (_isLoadingPage || !_hasMore || _nextPageStartingDocument == null)) {
      return;
    }

    setState(() {
      _isLoadingPage = true;
      if (!loadNextPage) {
        // ถ้าไม่ใช่การโหลดหน้าถัดไป (คือการโหลดครั้งแรกหรือรีเซ็ต)
        _bookings = []; // ล้างข้อมูลเก่า
        _nextPageStartingDocument = null; // รีเซ็ต cursor
        _hasMore = true; // สมมติว่ามีข้อมูลให้โหลด
      }
    });

    try {
      final DateTime startDate = DateTime(_selectedYear, _selectedMonth, 1);
      final DateTime endDate = (_selectedMonth == 12)
          ? DateTime(_selectedYear + 1, 1, 1)
          : DateTime(_selectedYear, _selectedMonth + 1, 1);

      Query query = FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .where('createdAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('createdAt', isLessThan: Timestamp.fromDate(endDate));

      if (loadNextPage && _nextPageStartingDocument != null) {
        query = query.startAfterDocument(_nextPageStartingDocument!);
      }

      query = query.limit(_pageSize);

      final snapshot = await query.get();

      if (mounted) {
        setState(() {
          _bookings.addAll(snapshot.docs);
          if (snapshot.docs.length < _pageSize) {
            _hasMore = false;
          } else {
            _nextPageStartingDocument = snapshot.docs.last;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('เกิดข้อผิดพลาดในการโหลดข้อมูล: ${e.toString()}'),
            backgroundColor: Colors.red));
      }
      setState(() {
        _hasMore = false; // หยุดการโหลดเมื่อเกิดข้อผิดพลาด
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingPage = false;
        });
      }
    }
  }

  // ฟังก์ชันรีเซ็ตและโหลดข้อมูลใหม่ทั้งหมด (สำหรับ Filter หรือ Refresh)
  void _resetAndFetchBookings() {
    if (!_isAdmin) return;
    _bookings.clear();
    _nextPageStartingDocument = null;
    _hasMore = true;
    _isLoadingPage = false; // รีเซ็ตสถานะการโหลดก่อนเรียก fetch
    _fetchBookings(loadNextPage: false); // โหลดหน้าแรก
  }

  Future<void> _updateBookingStatus(String docId, String newStatus) async {
    if (!_isAdmin) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('คุณไม่มีสิทธิ์ในการอัปเดตสถานะการจอง'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    try {
      await FirebaseFirestore.instance
          .collection('bookings')
          .doc(docId)
          .update({'bookingStatus': newStatus});

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('อัปเดตสถานะเป็น $newStatus สำเร็จ'),
            backgroundColor: Colors.green,
          ),
        );
      }
      // หากต้องการให้รายการที่อัปเดตหายไปจาก list ชั่วคราว หรือรีเฟรช
      // เนื่องจากเราใช้ Future.get() และโหลดเป็นหน้าๆ การอัปเดตสถานะจะไม่ได้รีเฟรช UI ทันที
      // หากจำเป็นต้องรีเฟรช ให้พิจารณา _resetAndFetchBookings() หรือลบรายการออกจาก _bookings List
      // _resetAndFetchBookings(); // หากต้องการรีเฟรชทั้งหน้าหลังจากอัปเดตสถานะ
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาดในการอัปเดต: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isAdmin) {
      return _buildPermissionDeniedState();
    }

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
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
                      if (value != null) {
                        setState(() {
                          _selectedYear = value;
                          _resetAndFetchBookings(); // โหลดใหม่เมื่อเปลี่ยนปี
                        });
                      }
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
                      if (value != null) {
                        setState(() {
                          _selectedMonth = value;
                          _resetAndFetchBookings(); // โหลดใหม่เมื่อเปลี่ยนเดือน
                        });
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: _bookings.isEmpty &&
                    _isLoadingPage // แสดง CircularProgressIndicator ขณะโหลดเริ่มต้น (ถ้า _bookings ว่างและกำลังโหลด)
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () async {
                      _resetAndFetchBookings();
                      // Optional: เพิ่ม delay เพื่อให้เห็น animation ของ RefreshIndicator ชัดเจน
                      await Future.delayed(const Duration(milliseconds: 500));
                    },
                    child: (_bookings.isEmpty &&
                            !_isLoadingPage &&
                            !_hasMore) // ถ้าโหลดเสร็จแล้วแต่ไม่มีข้อมูล (รวมถึงกรณีที่ filter แล้วไม่มี)
                        ? const Center(
                            child: Text(
                              'ไม่พบข้อมูลการจองในเดือน/ปีที่เลือก',
                              style:
                                  TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          )
                        : ListView.builder(
                            // ไม่ต้องใช้ controller แล้ว
                            // controller: _scrollController,
                            itemCount: _bookings.length +
                                (_hasMore
                                    ? 1
                                    : 0), // เพิ่ม 1 สำหรับปุ่ม "โหลดเพิ่มเติม"
                            itemBuilder: (context, index) {
                              if (index == _bookings.length) {
                                return Padding(
                                  padding: const EdgeInsets.all(8.0),
                                  child: Center(
                                    child: _isLoadingPage
                                        ? const CircularProgressIndicator()
                                        : ElevatedButton(
                                            // ปุ่ม "โหลดเพิ่มเติม"
                                            onPressed: () => _fetchBookings(
                                                loadNextPage: true),
                                            child: const Text('โหลดเพิ่มเติม'),
                                          ),
                                  ),
                                );
                              }

                              final bookingDoc = _bookings[index];
                              final bookingData =
                                  bookingDoc.data() as Map<String, dynamic>;

                              final String plateNumber =
                                  bookingData['plateNumber'] ?? 'N/A';
                              final String status =
                                  bookingData['bookingStatus'] ?? 'N/A';
                              final Timestamp createdAt =
                                  bookingData['createdAt'] ?? Timestamp.now();
                              final String formattedDate =
                                  DateFormat('d MMM y, HH:mm', 'th_TH')
                                      .format(createdAt.toDate());
                              final bool needsShuttle =
                                  bookingData['needsShuttle'] ?? false;
                              final int passengerCount =
                                  bookingData['passengerCount'] ?? 0;

                              String subtitleText =
                                  'วันที่จอง: $formattedDate\nสถานะ: $status';
                              if (needsShuttle) {
                                subtitleText +=
                                    '\nผู้โดยสาร: $passengerCount คน';
                              }

                              return Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 8.0, vertical: 4.0),
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: _getStatusColor(status),
                                    child: Icon(_getStatusIcon(status),
                                        color: Colors.white, size: 20),
                                  ),
                                  title: Text('ทะเบียน: $plateNumber'),
                                  subtitle: Text(subtitleText),
                                  trailing: (status == 'PENDING_VERIFICATION')
                                      ? SizedBox(
                                          width: 100,
                                          child: Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(
                                                    Icons.check_circle,
                                                    color: Colors.green),
                                                tooltip: 'อนุมัติ',
                                                onPressed: _isLoadingPage
                                                    ? null
                                                    : () =>
                                                        _updateBookingStatus(
                                                            bookingDoc.id,
                                                            'CONFIRMED'),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.cancel,
                                                    color: Colors.red),
                                                tooltip: 'ปฏิเสธ',
                                                onPressed: _isLoadingPage
                                                    ? null
                                                    : () =>
                                                        _updateBookingStatus(
                                                            bookingDoc.id,
                                                            'REJECTED'),
                                              ),
                                            ],
                                          ),
                                        )
                                      : const Icon(Icons.chevron_right),
                                  isThreeLine: true,
                                  onTap: () {
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                            builder: (context) =>
                                                AdminBookingDetailsPage(
                                                    bookingId: bookingDoc.id)));
                                  },
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Colors.green;
      case 'PENDING_VERIFICATION':
        return Colors.orange;
      case 'PENDING_PAYMENT':
        return Colors.blueGrey;
      case 'REJECTED':
        return Colors.red;
      case 'COMPLETED':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'CONFIRMED':
        return Icons.check_circle;
      case 'PENDING_VERIFICATION':
        return Icons.hourglass_top;
      case 'PENDING_PAYMENT':
        return Icons.payment;
      case 'REJECTED':
        return Icons.cancel;
      case 'COMPLETED':
        return Icons.directions_car_filled;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildPermissionDeniedState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outline, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          const Text(
            'คุณไม่มีสิทธิ์เข้าถึงหน้านี้',
            style: TextStyle(
                color: Colors.red, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'กรุณาตรวจสอบสิทธิ์ Admin ของคุณ',
            style: TextStyle(color: Colors.grey[600], fontSize: 16),
          ),
        ],
      ),
    );
  }
}
