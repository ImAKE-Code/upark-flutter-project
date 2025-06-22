// ---- lib/main.dart (ฉบับแก้ไข) ----
import 'package:flutter/material.dart';
import 'package:suvarnabhumi_parking_app/src/pages/auth_gate.dart';
import 'package:suvarnabhumi_parking_app/src/pages/landing_page.dart';
import 'package:suvarnabhumi_parking_app/src/pages/login_page.dart';
import 'package:suvarnabhumi_parking_app/src/pages/register_page.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:suvarnabhumi_parking_app/src/pages/my_bookings_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('th_TH');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // await ReceiptService.init(); // <-- เออบรรทัดนี้ออกไปก่อน

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'UPark Parking',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF212121),
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFFC107),
          primary: const Color(0xFFFFC107),
          secondary: const Color(0xFF212121),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 1,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                textStyle: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold))),
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthGate(),
        '/landing': (context) => const LandingPage(),
        '/login': (context) => const LoginPage(),
        '/register': (context) => const RegisterPage(),
        '/my-bookings': (context) => const MyBookingsPage(),
      },
    );
  }
}
