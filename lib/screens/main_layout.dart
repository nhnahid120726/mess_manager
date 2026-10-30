import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';
import 'market_screen.dart';
import 'accounts_screen.dart';
import 'members_screen.dart';
import 'profile_screen.dart';
import 'personal/personal_dashboard_screen.dart';
import 'personal/personal_transactions_screen.dart';
import 'personal/add_personal_transaction_screen.dart';
import 'personal/personal_accounts_screen.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  final AuthService _authService = AuthService();

  int _messIndex = 0;
  int _personalIndex = 0;
  bool _isPersonalModule = false; // Default to Mess Manager for mess members
  bool _isWalletOnlyUser = false;
  bool _isLoadingRole = true;

  late final PageController _messPageController = PageController(initialPage: _messIndex);
  late final PageController _personalPageController = PageController(initialPage: _personalIndex);

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  Future<void> _checkUserRole() async {
    final String role = await _authService.getCurrentUserRole();
    if (mounted) {
      setState(() {
        if (role == 'wallet_only') {
          _isWalletOnlyUser = true;
          _isPersonalModule = true; // Force Personal Wallet for 9th+ user
        }
        _isLoadingRole = false;
      });
    }
  }

  @override
  void dispose() {
    _messPageController.dispose();
    _personalPageController.dispose();
    super.dispose();
  }

  void _toggleModule() {
    if (_isWalletOnlyUser) return; // Wallet-only users cannot switch to Mess Manager
    setState(() {
      _isPersonalModule = !_isPersonalModule;
    });
  }

  List<Widget> get _messScreens => [
    HomeScreen(onToggleModule: _isWalletOnlyUser ? null : _toggleModule),
    const MarketScreen(),
    const AccountsScreen(),
    const MembersScreen(),
    const ProfileScreen(),
  ];

  List<Widget> get _personalScreens => [
    PersonalDashboardScreen(onToggleModule: _isWalletOnlyUser ? null : _toggleModule),
    const PersonalTransactionsScreen(),
    const AddPersonalTransactionScreen(),
    const PersonalAccountsScreen(),
    const ProfileScreen(),
  ];

  int get _currentIndex => _isPersonalModule ? _personalIndex : _messIndex;
  PageController get _activeController => _isPersonalModule ? _personalPageController : _messPageController;

  void _onTabSelected(int index) {
    if (_currentIndex == index) return;

    setState(() {
      if (_isPersonalModule) {
        _personalIndex = index;
      } else {
        _messIndex = index;
      }
    });

    _activeController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      if (_isPersonalModule) {
        _personalIndex = index;
      } else {
        _messIndex = index;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const Color primary = AppColors.primary;

    if (_isLoadingRole) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }

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
          controller: _activeController,
          onPageChanged: _onPageChanged,
          physics: const BouncingScrollPhysics(),
          children: _isPersonalModule ? _personalScreens : _messScreens,
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
                destinations: _isPersonalModule
                    ? const [
                        NavigationDestination(
                          icon: Icon(Icons.dashboard_outlined, color: Color(0xFF969BB2)),
                          selectedIcon: Icon(Icons.dashboard_rounded, color: primary),
                          label: 'হোম',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.receipt_long_outlined, color: Color(0xFF969BB2)),
                          selectedIcon: Icon(Icons.receipt_long_rounded, color: primary),
                          label: 'লেনদেন',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.add_circle_outline_rounded, color: Color(0xFF969BB2)),
                          selectedIcon: Icon(Icons.add_circle_rounded, color: primary),
                          label: 'যোগ করুন',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.account_balance_wallet_outlined, color: Color(0xFF969BB2)),
                          selectedIcon: Icon(Icons.account_balance_wallet_rounded, color: primary),
                          label: 'ওয়ালেট',
                        ),
                        NavigationDestination(
                          icon: Icon(Icons.person_outline_rounded, color: Color(0xFF969BB2)),
                          selectedIcon: Icon(Icons.person_rounded, color: primary),
                          label: 'প্রোফাইল',
                        ),
                      ]
                    : const [
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
