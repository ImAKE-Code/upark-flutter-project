// ---- lib/src/pages/auth_gate.dart (ฉบับสมบูรณ์) ----
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:suvarnabhumi_parking_app/src/pages/landing_page.dart';
import 'package:suvarnabhumi_parking_app/src/pages/login_page.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!snapshot.hasData) {
          // ถ้าไม่มีข้อมูล user เลย ให้ไปหน้า Login
          // เราจะทำการ login anomymously ที่หน้า login แทน
          return const LoginPage(performAnonymousSignIn: true);
        }

        final user = snapshot.data!;

        if (user.isAnonymous) {
          return const LandingPage();
        }

        // ถ้าเป็นสมาชิกแล้ว (ไม่ใช่ anonymous)
        // TODO: อนาคตจะไปหน้า My Bookings
        return const LandingPage();
      },
    );
  }
}