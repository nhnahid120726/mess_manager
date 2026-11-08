import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/constants/app_colors.dart';
import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/main_layout.dart';
import 'services/notification_service.dart';

/// ============================================================================
/// 🚀 অ্যাপ মেইন এন্ট্রি পয়েন্ট (Main Entry Point)
/// ============================================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // ১. ফায়ারবেস সার্ভিস কোর ইনিশিয়ালাইজেশন
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // ২. ডেট ফরম্যাটিং ইনিশিয়ালাইজেশন (বাংলা সহ সব লোকাল ডেটার জন্য)
  await initializeDateFormatting();
  
  // ৩. পুশ নোটিফিকেশন সার্ভিস ইনিশিয়ালাইজেশন
  await NotificationService().initialize();
  
  runApp(const MessApp());
}

/// ============================================================================
/// 🎨 রুট উইজেট (MessApp) - থিম ও টাইপোগ্রাফি
/// ============================================================================
class MessApp extends StatelessWidget {
  const MessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mess Manager & Personal Wallet',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.primary),
        fontFamily: 'NotoSansBengali',
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

/// ============================================================================
/// 🔐 অথেন্টিকেশন র‍্যাপার (AuthWrapper)
/// ============================================================================
/// - ফায়ারবেস অথেন্টিকেশন স্টেট ট্র্যাক করে সেশন কন্ট্রোল করে।
/// - ইউজারের সেশন অ্যাক্টিভ থাকলে সরাসরি `MainLayout()` লোড করবে।
/// - ইউজার লগআউট থাকলে `LoginScreen()` দেখাবে।
class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // লোডিং স্টেট
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // ইউজার লগইন থাকলে সরাসরি মেইন লেআউট লোড
        if (snapshot.hasData && snapshot.data != null) {
          return const MainLayout();
        }

        // ইউজার লগআউট থাকলে লগইন স্ক্রিন লোড
        return const LoginScreen();
      },
    );
  }
}
