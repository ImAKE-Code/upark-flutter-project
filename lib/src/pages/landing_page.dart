// ---- lib/src/pages/landing_page.dart (ฉบับแก้ไข UI AppBar Final) ----
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'admin_main_page.dart';
import 'booking_page.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> {
  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      setState(() {});
    } catch (e) {
      debugPrint("Error during logout: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final bool isLoggedIn = user != null && !user.isAnonymous;
    final bool isAdmin = user?.email == "im_ake_@hotmail.com";

    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.black),
        title: Row(
          children: [
            Icon(Icons.directions_car,
                color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
            const Text('UPark Parking', style: TextStyle(color: Colors.black)),
          ],
        ),
        actions: [
          // --- UI สำหรับหน้าจอ Desktop/Web ขนาดใหญ่ ---
          if (MediaQuery.of(context).size.width > 760) ...[
            TextButton(onPressed: () {}, child: const Text('หน้าแรก')),
            TextButton(onPressed: () {}, child: const Text('เกี่ยวกับเรา')),
            TextButton(onPressed: () {}, child: const Text('ติดต่อเรา')),
            const SizedBox(width: 16),

            // --- ส่วนของปุ่มที่จะเปลี่ยนไปตามสถานะ Login ---
            if (isLoggedIn) ...[
              // ถ้า Login แล้ว
              TextButton.icon(
                icon: const Icon(Icons.history),
                label: const Text('ประวัติการจอง'),
                onPressed: () => Navigator.pushNamed(context, '/my-bookings'),
              ),
              const SizedBox(width: 8),
              TextButton.icon(
                icon: const Icon(Icons.logout),
                label: const Text('ออกจากระบบ'),
                onPressed: _logout,
                style: TextButton.styleFrom(foregroundColor: Colors.red[700]),
              ),
            ] else ...[
              // ถ้ายังไม่ได้ Login
              TextButton(
                onPressed: () => Navigator.pushNamed(context, '/login'),
                child: const Text('เข้าสู่ระบบ'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/register'),
                style: ElevatedButton.styleFrom(
                  // ปรับแก้ padding และ elevation ให้ดูสมส่วนขึ้น
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
                  elevation: 2,
                ),
                child: const Text('สมัครสมาชิก'),
              ),
            ]
          ],

          const SizedBox(width: 16),
          // --- ปุ่ม Admin จะแสดงเมื่อเป็น Admin เท่านั้น ---
          if (isAdmin)
            IconButton(
              icon: const Icon(Icons.admin_panel_settings),
              tooltip: 'Admin Panel',
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => const AdminMainPage()));
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: MediaQuery.of(context).size.width <= 760
          ? _buildMobileDrawer(context, isLoggedIn, isAdmin, _logout)
          : null,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeroSection(context),
            _buildFeaturesSection(context),
            _buildHowItWorksSection(context),
            _buildGallerySection(),
            _buildReviewsSection(),
            _buildFaqSection(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }
}

//======================================================================
//  Helper Functions and Widgets
//======================================================================

// --- 3. อัปเดต Drawer ให้รับค่า isAdmin ---
Drawer _buildMobileDrawer(BuildContext context, bool isLoggedIn, bool isAdmin,
    Future<void> Function() logout) {
  return Drawer(
    child: ListView(
      padding: EdgeInsets.zero,
      children: <Widget>[
        DrawerHeader(
          decoration:
              BoxDecoration(color: Theme.of(context).colorScheme.primary),
          child: const Text('เมนู',
              style: TextStyle(color: Colors.black, fontSize: 24)),
        ),
        ListTile(
            title: const Text('หน้าแรก'),
            onTap: () {
              Navigator.pop(context);
            }),
        ListTile(
            title: const Text('เกี่ยวกับเรา'),
            onTap: () {
              Navigator.pop(context);
            }),
        ListTile(
            title: const Text('ติดต่อเรา'),
            onTap: () {
              Navigator.pop(context);
            }),
        const Divider(),
        if (isLoggedIn) ...[
          ListTile(
            leading: const Icon(Icons.history),
            title: const Text('ประวัติการจอง'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/my-bookings');
            },
          ),
        ] else ...[
          ListTile(
            leading: const Icon(Icons.login),
            title: const Text('เข้าสู่ระบบ'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/login');
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_add),
            title: const Text('สมัครสมาชิก'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/register');
            },
          ),
        ],
        const Divider(),
        if (isAdmin)
          ListTile(
            leading: const Icon(Icons.admin_panel_settings),
            title: const Text('Admin Panel'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AdminMainPage()));
            },
          ),
        if (isLoggedIn)
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title:
                const Text('ออกจากระบบ', style: TextStyle(color: Colors.red)),
            onTap: () {
              Navigator.pop(context);
              logout();
            },
          ),
      ],
    ),
  );
}

Widget _buildHeroSection(BuildContext context) {
  return SizedBox(
    height: 500,
    child: Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/images/hero_background.jpg', fit: BoxFit.cover),
        Container(color: Colors.black54),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('UPark Parking',
                  style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              const SizedBox(height: 16),
              const Text('บริการที่จอดรถสนามบินสุวรรณภูมิ พร้อมรถรับส่ง 24 ชม.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, color: Colors.white)),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const BookingPage()));
                },
                style: ElevatedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30)),
                ),
                child: const Text('จองที่จอดรถเลย',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildFeaturesSection(BuildContext context) {
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
    color: Colors.grey[100],
    child: const Wrap(
      spacing: 16.0,
      runSpacing: 48.0,
      alignment: WrapAlignment.center,
      children: [
        _FeatureItem(
            icon: Icons.security,
            title: 'ปลอดภัย 24 ชม.',
            description: 'มั่นใจด้วยระบบ CCTV และเจ้าหน้าที่ดูแลตลอดเวลา'),
        _FeatureItem(
            icon: Icons.airport_shuttle,
            title: 'บริการรับ-ส่ง',
            description: 'รถรับส่งส่วนตัวสู่สนามบิน สะดวกสบาย ไม่ต้องรอ'),
        _FeatureItem(
            icon: Icons.online_prediction,
            title: 'จองออนไลน์ง่ายๆ',
            description: 'จองและชำระเงินผ่านเว็บไซต์ได้ทันที'),
      ],
    ),
  );
}

Widget _buildHowItWorksSection(BuildContext context) {
  return Container(
      padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
      color: Colors.white,
      child: const Column(children: [
        Text('ขั้นตอนการใช้บริการง่ายๆ',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        SizedBox(height: 48),
        Wrap(
            spacing: 16.0,
            runSpacing: 48.0,
            alignment: WrapAlignment.center,
            children: [
              _HowItWorksStep(
                  number: '1',
                  title: 'จองออนไลน์',
                  description:
                      'เลือกวันเวลาที่ต้องการจอง และชำระเงินผ่านเว็บไซต์ของเรา',
                  icon: Icons.web),
              _HowItWorksStep(
                  number: '2',
                  title: 'นำรถมาจอด',
                  description:
                      'ขับรถมาจอดที่ UPark ตามวันและเวลาที่ท่านได้ทำการจองไว้',
                  icon: Icons.local_parking),
              _HowItWorksStep(
                  number: '3',
                  title: 'เดินทางสู่สนามบิน',
                  description:
                      'ขึ้นรถรับส่งส่วนตัวของเรา เพื่อเดินทางไปยังอาคารผู้โดยสาร',
                  icon: Icons.flight_takeoff)
            ])
      ]));
}

Widget _buildGallerySection() {
  final List<String> galleryImages = [
    'assets/images/gallery_1.jpg',
    'assets/images/gallery_2.jpg',
    'assets/images/gallery_3.jpg',
    'assets/images/gallery_4.jpg'
  ];
  return Container(
      padding: const EdgeInsets.symmetric(vertical: 48.0),
      color: Colors.grey[100],
      child: Column(children: [
        const Text('บรรยากาศของเรา',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        const SizedBox(height: 32),
        SizedBox(
            height: 250,
            child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: galleryImages.length,
                itemBuilder: (context, index) {
                  return Container(
                      width: 350,
                      margin: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Image.asset(galleryImages[index],
                              fit: BoxFit.cover)));
                }))
      ]));
}

Widget _buildReviewsSection() {
  final List<Map<String, dynamic>> reviews = [
    {
      'name': 'สมชาย ใจดี',
      'rating': 5,
      'review':
          'บริการดีมากครับ รถรับส่งตรงเวลา ที่จอดปลอดภัย ไว้จะมาใช้บริการอีกแน่นอนครับ'
    },
    {
      'name': 'กานดา รักไทย',
      'rating': 5,
      'review':
          'สะดวกสบายมากค่ะ จองง่าย ไปถึงก็มีที่จอดเลย พนักงานบริการดี ประทับใจค่ะ'
    },
    {
      'name': 'Peter J.',
      'rating': 4,
      'review':
          'Good service. The location is quite near the airport. The shuttle was on time.'
    },
  ];
  return Container(
    padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
    color: Colors.white,
    child: Column(
      children: [
        const Text('เสียงตอบรับจากลูกค้า',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        const SizedBox(height: 32),
        Wrap(
          spacing: 24,
          runSpacing: 24,
          alignment: WrapAlignment.center,
          children: reviews.map((reviewData) {
            return _ReviewCard(
              name: reviewData['name'],
              rating: reviewData['rating'],
              review: reviewData['review'],
            );
          }).toList(),
        )
      ],
    ),
  );
}

Widget _buildFaqSection(BuildContext context) {
  return Container(
      padding: const EdgeInsets.symmetric(vertical: 48.0, horizontal: 16.0),
      color: Colors.grey[100],
      child: Column(children: [
        const Text('คำถามที่พบบ่อย',
            style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.black)),
        const SizedBox(height: 32),
        StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('faqs')
                .orderBy('order')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const CircularProgressIndicator();
              final faqs = snapshot.data!.docs;
              return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: faqs.length,
                  itemBuilder: (context, index) {
                    final faqData = faqs[index].data() as Map<String, dynamic>;
                    return Card(
                        color: Colors.white,
                        elevation: 1,
                        margin: const EdgeInsets.symmetric(vertical: 8.0),
                        child: ExpansionTile(
                            iconColor: Theme.of(context).colorScheme.primary,
                            collapsedIconColor: Colors.black,
                            title: Text(faqData['question'] ?? 'ไม่มีคำถาม',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black)),
                            children: <Widget>[
                              Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(faqData['answer'] ?? 'ไม่มีคำตอบ',
                                      style:
                                          TextStyle(color: Colors.grey[700])))
                            ]));
                  });
            })
      ]));
}

Widget _buildFooter(BuildContext context) {
  return Container(
      padding: const EdgeInsets.all(32.0),
      color: const Color(0xFF212121),
      child: Column(children: [
        Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('UPark Parking',
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.primary)),
                    const SizedBox(height: 8),
                    Text(
                        'บริการที่จอดรถสนามบินสุวรรณภูมิรายวัน พร้อมบริการรับส่งตลอด 24 ชั่วโมง ปลอดภัย มั่นใจ เดินทางสะดวก',
                        style: TextStyle(color: Colors.grey[400]))
                  ])),
              const SizedBox(width: 32),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('ลิงก์ด่วน',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('หน้าแรก', style: TextStyle(color: Colors.grey[400])),
                    const SizedBox(height: 4),
                    Text('จองที่จอดรถ',
                        style: TextStyle(color: Colors.grey[400])),
                    const SizedBox(height: 4),
                    Text('คำถามที่พบบ่อย',
                        style: TextStyle(color: Colors.grey[400]))
                  ])),
              const SizedBox(width: 32),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('ติดต่อเรา',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
                    const SizedBox(height: 8),
                    Text('ที่อยู่: บางโฉลง, สมุทรปราการ',
                        style: TextStyle(color: Colors.grey[400])),
                    const SizedBox(height: 4),
                    Text('โทร: 08x-xxxx-xxxx',
                        style: TextStyle(color: Colors.grey[400])),
                    const SizedBox(height: 4),
                    Text('อีเมล: contact@upark.com',
                        style: TextStyle(color: Colors.grey[400]))
                  ]))
            ]),
        const SizedBox(height: 32),
        Divider(color: Colors.grey[800]),
        const SizedBox(height: 16),
        Text('© 2025 UPark Parking. All Rights Reserved.',
            style: TextStyle(color: Colors.grey[600], fontSize: 12))
      ]));
}

class _FeatureItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  const _FeatureItem(
      {required this.icon, required this.title, required this.description});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 300,
        child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(children: [
              Icon(icon,
                  size: 48, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(height: 16),
              Text(title,
                  style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  textAlign: TextAlign.center)
            ])));
  }
}

class _HowItWorksStep extends StatelessWidget {
  final String number;
  final String title;
  final String description;
  final IconData icon;
  const _HowItWorksStep(
      {required this.number,
      required this.title,
      required this.description,
      required this.icon});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        width: 300,
        child: Column(children: [
          CircleAvatar(
              radius: 30,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(number,
                  style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121)))),
          const SizedBox(height: 24),
          Icon(icon, size: 48, color: Colors.black),
          const SizedBox(height: 16),
          Text(title,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black)),
          const SizedBox(height: 8),
          Text(description,
              style: TextStyle(color: Colors.grey[700]),
              textAlign: TextAlign.center)
        ]));
  }
}

class _ReviewCard extends StatelessWidget {
  final String name;
  final int rating;
  final String review;
  const _ReviewCard(
      {required this.name, required this.rating, required this.review});
  @override
  Widget build(BuildContext context) {
    return Card(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Container(
            width: 350,
            padding: const EdgeInsets.all(24.0),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                const CircleAvatar(
                    radius: 24,
                    backgroundImage:
                        AssetImage('assets/images/avatar_placeholder.png')),
                const SizedBox(width: 16),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black)),
                  Row(
                      children: List.generate(5, (index) {
                    return Icon(index < rating ? Icons.star : Icons.star_border,
                        color: const Color(0xFFFFC107), size: 20);
                  }))
                ])
              ]),
              const SizedBox(height: 16),
              Text('"$review"',
                  style: TextStyle(
                      fontStyle: FontStyle.italic, color: Colors.grey[700]))
            ])));
  }
}
