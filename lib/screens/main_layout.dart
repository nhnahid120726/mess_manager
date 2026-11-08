import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import 'home_screen.dart';
import 'market_screen.dart';
import 'accounts_screen.dart';
import 'members_screen.dart';
import 'profile_screen.dart';

/// ============================================================================
/// 📱 মেইন লেআউট স্ক্রিন (MainLayout) — Pure Mess Manager Edition
/// ============================================================================
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;
  late final PageController _pageController = PageController(initialPage: _currentIndex);

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  /// 🏠 মেস ম্যানেজার স্ক্রিনসমূহের লিস্ট
  List<Widget> get _screens => const [
    HomeScreen(),
    MarketScreen(),
    AccountsScreen(),
    MembersScreen(),
    ProfileScreen(),
  ];

  /// 🔘 বটম ন্যাভিগেশন বারের ট্যাপ হ্যান্ডলার
  void _onTabSelected(int index) {
    if (_currentIndex == index) return;

    setState(() {
      _currentIndex = index;
    });

    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// 👈👉 ডানে-বামে সোয়াইপ করলে বটম বার সিঙ্ক করার মেথড
  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = AppColors.primary;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;

        if (_currentIndex != 0) {
          _onTabSelected(0);
        } else {
          _showExitDialog(context);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: PageView(
          controller: _pageController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
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
                color: Colors.black.withValues(alpha: 0.04),
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
                indicatorColor: primary.withValues(alpha: 0.15),
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
                onDestinationSelected: _onTabSelected,
                destinations: const [
                  NavigationDestination(
                    icon: Icon(Icons.dashboard_outlined, color: Color(0xFF969BB2)),
                    selectedIcon: Icon(Icons.dashboard_rounded, color: primary),
                    label: 'ড্যাশবোর্ড',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.shopping_cart_outlined, color: Color(0xFF969BB2)),
                    selectedIcon: Icon(Icons.shopping_cart_rounded, color: primary),
                    label: 'বাজার',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF969BB2)),
                    selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: primary),
                    label: 'জমা',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.people_outline_rounded, color: Color(0xFF969BB2)),
                    selectedIcon: Icon(Icons.people_rounded, color: primary),
                    label: 'সদস্য',
                  ),
                  NavigationDestination(
                    icon: Icon(Icons.person_outline_rounded, color: Color(0xFF969BB2)),
                    selectedIcon: Icon(Icons.person_rounded, color: primary),
                    label: 'প্রোফাইল',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// 🚪 অ্যাপ বন্ধ করার নিশ্চয়তা ডায়ালগ
  void _showExitDialog(BuildContext context) async {
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
            'আপনি কি অ্যাপ থেকে বের হতে চান?',
            style: TextStyle(fontSize: 15, color: Color(0xFF7186A5)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
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

    if (shouldExit == true) {
      SystemNavigator.pop();
    }
  }
}
