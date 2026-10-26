import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // SystemNavigator এর জন্য

import 'home_screen.dart';
import 'market_screen.dart';
import 'accounts_screen.dart';
import 'members_screen.dart';
import 'profile_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  // List of screens for the bottom navigation bar
  final List<Widget> _screens = [
    const HomeScreen(),
    const MarketScreen(),
    const AccountsScreen(),
    const MembersScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    const Color primary = Color(0xFF087F8C);

    return PopScope(
      canPop: false,
      // Android-এর ডিফল্ট ব্যাক বাটন সরাসরি অ্যাপ বন্ধ করা ঠেকাবে
      onPopInvoked: (bool didPop) async {
        if (didPop) return;

        if (_currentIndex != 0) {
          // ১. যদি অন্য ট্যাবে থাকি, তাহলে ব্যাক বাটন চাপলে Home ট্যাবে ফিরে আসবে
          setState(() {
            _currentIndex = 0;
          });
        } else {
          // ২. যদি Home ট্যাবেই থাকি, তাহলে Exit Confirmation ডায়ালগ দেখাবে
          final bool? shouldExit = await showDialog<bool>(
            context: context,
            builder: (context) {
              return AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                title: const Row(
                  children: [
                    Icon(Icons.exit_to_app_rounded, color: Color(0xFFFF4058)),
                    SizedBox(width: 10),
                    Text(
                      'অ্যাপ বন্ধ করবেন?',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 20,
                      ),
                    ),
                  ],
                ),
                content: const Text(
                  'আপনি কি মেস ম্যানেজার অ্যাপ থেকে বের হতে চান?',
                  style: TextStyle(fontSize: 15, color: Color(0xFF7186A5)),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    // ডায়ালগ বন্ধ করবে
                    child: const Text(
                      'না',
                      style: TextStyle(
                        color: Color(0xFF7186A5),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(true),
                    // অ্যাপ বন্ধের সিগন্যাল দেবে
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF4058),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: const Text(
                      'হ্যাঁ',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            },
          );

          // ৩. যদি ইউজার 'হ্যাঁ' সিলেক্ট করে, তবে SystemNavigator ব্যবহার করে অ্যাপ বন্ধ হবে
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
        }
      },
      child: Scaffold(
        extendBody: true, 
        // 🚀 OPTIMIZATION: IndexedStack ব্যবহার করা হয়েছে। 
        // এর ফলে পেজ পরিবর্তন করার সময় বারবার ফায়ারবেস থেকে ডেটা লোড হবে না।
        // একবার লোড হওয়া পেজগুলো মেমরিতে ক্যাশ (Cache) হয়ে থাকবে, ফলে পেজ সুইচিং হবে চোখের পলকে!
        body: IndexedStack(
          index: _currentIndex,
          children: _screens,
        ),
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
            child: NavigationBarTheme(
              data: NavigationBarThemeData(
                backgroundColor: Colors.white,
                indicatorColor: primary.withOpacity(0.15),
                labelTextStyle: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: primary,
                    );
                  }
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF969BB2),
                  );
                }),
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                height: 75,
                elevation: 0,
                labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
                onDestinationSelected: (index) {
                  setState(() {
                    _currentIndex = index;
                  });
                },
                destinations: [
                  NavigationDestination(
                    icon: const Icon(
                      Icons.dashboard_outlined,
                      color: Color(0xFF969BB2),
                    ),
                    selectedIcon: const Icon(
                      Icons.dashboard_rounded,
                      color: primary,
                    ),
                    label: 'ড্যাশবোর্ড',
                  ),
                  NavigationDestination(
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: Color(0xFF969BB2),
                    ),
                    selectedIcon: const Icon(
                      Icons.shopping_cart_rounded,
                      color: primary,
                    ),
                    label: 'বাজার',
                  ),
                  NavigationDestination(
                    icon: const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: Color(0xFF969BB2),
                    ),
                    selectedIcon: const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: primary,
                    ),
                    label: 'জমা',
                  ),
                  NavigationDestination(
                    icon: const Icon(
                      Icons.people_outline_rounded,
                      color: Color(0xFF969BB2),
                    ),
                    selectedIcon: const Icon(
                      Icons.people_rounded,
                      color: primary,
                    ),
                    label: 'সদস্য',
                  ),
                  NavigationDestination(
                    icon: const Icon(
                      Icons.person_outline_rounded,
                      color: Color(0xFF969BB2),
                    ),
                    selectedIcon: const Icon(
                      Icons.person_rounded,
                      color: primary,
                    ),
                    label: 'প্রোফাইল',
                  ),
                ],
              ),
            ),
          ),
        ),
      ), // Close Scaffold
    ); // Close PopScope
  }
}
