import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_colors.dart';
import '../services/financial_service.dart';
import '../services/auth_service.dart';
import '../models/expense_model.dart';
import 'add_expense_screen.dart';

/// ============================================================================
/// 🛒 মেসের বাজারের হিসাব স্ক্রিন (MarketScreen) — Premium Edition
/// ============================================================================
class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen>
    with AutomaticKeepAliveClientMixin<MarketScreen>, TickerProviderStateMixin {
  final FinancialService _financialService = FinancialService();
  final AuthService _authService = AuthService();
  bool _isAdmin = false;

  // HomeScreen-এর সাথে ম্যাচিং কালার প্যালেট (Navy Blue)
  static const Color navyDeep = Color(0xFF0F172A);
  static const Color navyMid = Color(0xFF1E3A8A);
  static const Color navyLight = Color(0xFF2563EB);
  static const Color navyAccent = Color(0xFF3B82F6);

  static const Color dark = AppColors.textPrimary;
  static const Color muted = AppColors.textSecondary;
  static const Color pageBg = AppColors.background;

  late AnimationController _headerAnimController;
  late AnimationController _fabAnimController;
  late Animation<double> _headerFadeAnim;
  late Animation<double> _fabScaleAnim;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _checkAdminStatus();
  }

  void _setupAnimations() {
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _headerFadeAnim = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );

    _fabAnimController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fabScaleAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _fabAnimController, curve: Curves.easeOutBack),
    );

    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _fabAnimController.forward();
    });
  }

  void _checkAdminStatus() async {
    final user = _authService.currentUser;
    if (user != null && user.email != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('members')
            .doc(user.email)
            .get();
        if (doc.exists && mounted) {
          setState(() => _isAdmin = doc['role'] == 'admin');
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _fabAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: pageBg,
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _financialService.getMonthlyExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return _buildLoadingState();
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }

          final expenses = snapshot.data ?? [];

          return Column(
            children: [
              // ১. ফিক্সড হেডার — স্ক্রল করলেও থাকবে
              FadeTransition(
                opacity: _headerFadeAnim,
                child: _FixedHeader(
                  expenses: expenses,
                  onBack: () => Navigator.pop(context),
                  onAdd: _navigateToAdd,
                ),
              ),

              // ২. স্ক্রলযোগ্য লিস্ট
              Expanded(
                child: expenses.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                  color: navyLight,
                  backgroundColor: Colors.white,
                  strokeWidth: 2.5,
                  onRefresh: () async {
                    setState(() {});
                    await Future.delayed(
                        const Duration(milliseconds: 300));
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 140),
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    itemCount: expenses.length,
                    itemBuilder: (context, index) {
                      return _AnimatedExpenseCard(
                        expense: expenses[index],
                        index: index,
                        isAdmin: _isAdmin,
                        onTap: _isAdmin
                            ? () => _navigateToEdit(expenses[index])
                            : null,
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnim,
        child: _PulsingFab(onTap: () => _navigateToAdd()),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _navigateToEdit(ExpenseModel expense) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) =>
            AddExpenseScreen(existingExpense: expense),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.08),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                parent: anim,
                curve: Curves.easeOutCubic,
              )),
              child: child,
            ),
          );
        },
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );
  }

  void _navigateToAdd() {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const AddExpenseScreen(),
        transitionsBuilder: (_, anim, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  // ============================================================
  // ⏳ LOADING
  // ============================================================
  Widget _buildLoadingState() {
    return Column(
      children: [
        _buildStaticHeaderShell(),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _PulsingLogo(),
                const SizedBox(height: 20),
                const Text(
                  'বাজারের হিসাব লোড হচ্ছে...',
                  style: TextStyle(
                    color: dark,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'একটু অপেক্ষা করুন',
                  style: TextStyle(
                    color: muted.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStaticHeaderShell() {
    final topInset = MediaQuery.paddingOf(context).top;
    return Container(
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [navyDeep, navyMid, navyLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: const SizedBox(height: 100),
    );
  }

  // ============================================================
  // ⚠️ ERROR
  // ============================================================
  Widget _buildErrorState(Object? error) {
    return Column(
      children: [
        _buildStaticHeaderShell(),
        Expanded(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutBack,
                builder: (_, val, child) =>
                    Transform.scale(scale: val, child: child),
                child: Container(
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(26),
                    border: Border.all(color: const Color(0xFFFFDADA)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: 0.06),
                        blurRadius: 25,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 68,
                        height: 68,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFEEEE), Color(0xFFFEE2E2)],
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(Icons.cloud_off_rounded,
                            color: Color(0xFFE74C3C), size: 30),
                      ),
                      const SizedBox(height: 18),
                      const Text(
                        'বাজারের হিসাব লোড করা যায়নি',
                        style: TextStyle(
                          color: dark,
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$error',
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: muted.withValues(alpha: 0.8),
                          fontSize: 12,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _TapScaleButton(
                        onTap: () => setState(() {}),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [navyMid, navyLight]),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.refresh_rounded,
                                  color: Colors.white, size: 18),
                              SizedBox(width: 6),
                              Text(
                                'আবার চেষ্টা করুন',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================================
  // 📭 EMPTY
  // ============================================================
  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (_, val, child) =>
                  Transform.scale(scale: val, child: child),
              child: _FloatingEmptyIcon(),
            ),
            const SizedBox(height: 28),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 600),
              builder: (_, val, child) {
                return Opacity(
                  opacity: val,
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1 - val)),
                    child: child,
                  ),
                );
              },
              child: Column(
                children: [
                  const Text(
                    'কোনো বাজারের হিসাব নেই',
                    style: TextStyle(
                      color: dark,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'এই মাসে এখনও কোনো বাজারের\nখরচ যোগ করা হয়নি।',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: muted.withValues(alpha: 0.8),
                      fontSize: 13,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 26),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutBack,
              builder: (_, val, child) =>
                  Transform.scale(scale: val, child: child),
              child: _TapScaleButton(
                onTap: () => _navigateToAdd(),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                  decoration: BoxDecoration(
                    gradient:
                    const LinearGradient(colors: [navyMid, navyLight]),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: navyLight.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.add_circle_outline_rounded,
                          size: 19, color: Colors.white),
                      SizedBox(width: 8),
                      Text(
                        'নতুন বাজার যোগ করুন',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 🧩 ফিক্সড হেডার (স্ক্রল হবে না, সর্বদা উপরে ফিক্সড থাকবে)
// ============================================================================

class _FixedHeader extends StatelessWidget {
  final List<ExpenseModel> expenses;
  final VoidCallback onBack;
  final VoidCallback onAdd;

  const _FixedHeader({
    required this.expenses,
    required this.onBack,
    required this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;
    final double total = expenses.fold(
      0.0,
          (acc, item) => acc + item.totalAmountInTaka,
    );
    final currentMonth = DateFormat('MMMM yyyy', 'bn').format(DateTime.now());

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _MarketScreenState.navyDeep,
            _MarketScreenState.navyMid,
            _MarketScreenState.navyLight,
          ],
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
        boxShadow: [
          BoxShadow(
            color: _MarketScreenState.navyMid.withValues(alpha: 0.35),
            blurRadius: 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ডেকোরেটিভ সার্কেলস (HomeScreen-এর মতো)
          Positioned(
            right: -25,
            top: -10,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: 50,
            bottom: -5,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // টপ বার — ব্যাক বাটন + টাইটেল + ব্যাজ
              Row(
                children: [
                  _GlassIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: onBack,
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.08)),
                    ),
                    child: const Icon(Icons.shopping_basket_rounded,
                        color: Colors.white, size: 23),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'বাজারের হিসাব',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: const BoxDecoration(
                                  color: Color(0xFF4ADE80),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 5),
                              Text(
                                currentMonth,
                                style: const TextStyle(
                                  color: Color(0xFFCBD5E1),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _GlassIconButton(
                    icon: Icons.add_rounded,
                    onTap: onAdd,
                  ),
                ],
              ),

              const SizedBox(height: 22),

              // সাব-কার্ডস — মোট খরচ ও মোট সংখ্যা
              Row(
                children: [
                  Expanded(
                    child: _HeaderSubCard(
                      icon: Icons.account_balance_wallet_rounded,
                      title: 'মোট বাজার খরচ',
                      value: total,
                      isAmount: true,
                      chipColor: const Color(0xFF4ADE80),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _HeaderSubCard(
                      icon: Icons.receipt_long_rounded,
                      title: 'মোট বাজার সংখ্যা',
                      value: expenses.length.toDouble(),
                      isAmount: false,
                      chipColor: const Color(0xFF60A5FA),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 🧊 গ্লাস আইকন বাটন (HomeScreen-এর ম্যাচিং)
// ============================================================================

class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _p = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) {
        setState(() => _p = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedScale(
        scale: _p ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: _p ? 0.22 : 0.12),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Icon(widget.icon, color: Colors.white, size: 18),
        ),
      ),
    );
  }
}

// ============================================================================
// 📊 হেডার সাব-কার্ড (অ্যানিমেটেড কাউন্টার)
// ============================================================================

class _HeaderSubCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final double value;
  final bool isAmount;
  final Color chipColor;

  const _HeaderSubCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.isAmount,
    required this.chipColor,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (_, animVal, child) {
        return Transform.translate(
          offset: Offset(0, 15 * (1 - animVal)),
          child: Opacity(opacity: animVal.clamp(0, 1), child: child),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.08),
                ]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: chipColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: value),
                    duration: const Duration(milliseconds: 1300),
                    curve: Curves.easeOutCubic,
                    builder: (_, val, __) {
                      return FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          isAmount
                              ? '৳ ${val.toStringAsFixed(2)}'
                              : '${val.toInt()} টি',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.3,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 📦 অ্যানিমেটেড এক্সপেন্স কার্ড (HomeScreen-এর কালার ম্যাচিং)
// ============================================================================

class _AnimatedExpenseCard extends StatefulWidget {
  final ExpenseModel expense;
  final int index;
  final bool isAdmin;
  final VoidCallback? onTap;

  const _AnimatedExpenseCard({
    required this.expense,
    required this.index,
    required this.isAdmin,
    this.onTap,
  });

  @override
  State<_AnimatedExpenseCard> createState() => _AnimatedExpenseCardState();
}

class _AnimatedExpenseCardState extends State<_AnimatedExpenseCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _pressed = false;

  // HomeScreen ম্যাচিং কালার থিম
  static const List<_CardTheme> _themes = [
    _CardTheme(
      iconColor: Color(0xFF8B5CF6),
      bgColor: Color(0xFFEDE9FE),
      bgGradient: [Color(0xFFEDE9FE), Color(0xFFF5F3FF)],
      icon: Icons.shopping_basket_rounded,
    ),
    _CardTheme(
      iconColor: Color(0xFFF59E0B),
      bgColor: Color(0xFFFEF3C7),
      bgGradient: [Color(0xFFFEF3C7), Color(0xFFFFFBEB)],
      icon: Icons.local_grocery_store_rounded,
    ),
    _CardTheme(
      iconColor: Color(0xFF06B6D4),
      bgColor: Color(0xFFCFFAFE),
      bgGradient: [Color(0xFFCFFAFE), Color(0xFFECFEFF)],
      icon: Icons.storefront_rounded,
    ),
    _CardTheme(
      iconColor: Color(0xFF10B981),
      bgColor: Color(0xFFD1FAE5),
      bgGradient: [Color(0xFFD1FAE5), Color(0xFFECFDF5)],
      icon: Icons.store_rounded,
    ),
    _CardTheme(
      iconColor: Color(0xFFEC4899),
      bgColor: Color(0xFFFCE7F3),
      bgGradient: [Color(0xFFFCE7F3), Color(0xFFFDF2F8)],
      icon: Icons.shopping_cart_rounded,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      duration: const Duration(milliseconds: 450),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOut,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryController,
      curve: Curves.easeOutCubic,
    ));

    Future.delayed(Duration(milliseconds: 60 * widget.index), () {
      if (mounted) _entryController.forward();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final expense = widget.expense;
    final bool isMessFund = expense.paymentSource == 'mess_fund';
    final String purchaser = expense.purchasedByEmail.split('@')[0];
    final theme = _themes[widget.index % _themes.length];

    // সময় ফরম্যাট
    final diff = DateTime.now().difference(expense.createdAt);
    String timeAgo;
    if (diff.inMinutes < 1) {
      timeAgo = 'এইমাত্র';
    } else if (diff.inMinutes < 60) {
      timeAgo = '${diff.inMinutes} মিনিট আগে';
    } else if (diff.inHours < 24) {
      timeAgo = '${diff.inHours} ঘণ্টা আগে';
    } else if (diff.inDays < 7) {
      timeAgo = '${diff.inDays} দিন আগে';
    } else {
      timeAgo = DateFormat('dd MMM yyyy').format(expense.createdAt);
    }

    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GestureDetector(
            onTapDown:
            widget.onTap != null ? (_) => setState(() => _pressed = true) : null,
            onTapUp: widget.onTap != null
                ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
                : null,
            onTapCancel: widget.onTap != null
                ? () => setState(() => _pressed = false)
                : null,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeInOut,
              transform: Matrix4.identity()..scale(_pressed ? 0.98 : 1.0),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: _pressed
                      ? theme.iconColor.withValues(alpha: 0.3)
                      : const Color(0xFFE9EEF6),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F172A)
                        .withValues(alpha: _pressed ? 0.07 : 0.04),
                    blurRadius: _pressed ? 14 : 20,
                    offset: Offset(0, _pressed ? 4 : 8),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        // আইকন বক্স (HomeScreen ম্যাচিং)
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: theme.bgGradient,
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: theme.iconColor.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(theme.icon,
                              color: theme.iconColor, size: 23),
                        ),
                        const SizedBox(width: 14),

                        // তথ্য
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.products.join(', '),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 15,
                                  color: AppColors.textPrimary,
                                  letterSpacing: -0.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              Row(
                                children: [
                                  Icon(Icons.access_time_rounded,
                                      size: 11,
                                      color: AppColors.textSecondary
                                          .withValues(alpha: 0.7)),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '$timeAgo • $purchaser',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: AppColors.textSecondary
                                            .withValues(alpha: 0.8),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // অ্যামাউন্ট + ব্যাজ
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // অ্যামাউন্ট ব্যাজ (HomeScreen ম্যাচিং — লাল ব্যাকগ্রাউন্ড)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: const Color(0xFFFECACA)
                                      .withValues(alpha: 0.6),
                                ),
                              ),
                              child: Text(
                                '-৳${expense.totalAmountInTaka.toStringAsFixed(0)}',
                                style: const TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 14,
                                  letterSpacing: -0.3,
                                ),
                              ),
                            ),
                            const SizedBox(height: 6),
                            // সোর্স ব্যাজ
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isMessFund
                                    ? const Color(0xFFD1FAE5)
                                    : const Color(0xFFDBEAFE),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 4,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: isMessFund
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF2563EB),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isMessFund ? 'মেস ফান্ড' : 'নিজস্ব',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: isMessFund
                                          ? const Color(0xFF059669)
                                          : const Color(0xFF2563EB),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // শেয়ার ডিস্ট্রিবিউশন সেকশন (HomeScreen ম্যাচিং)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(6),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 4,
                                ),
                              ],
                            ),
                            child: const Icon(Icons.people_alt_rounded,
                                size: 13, color: Color(0xFF64748B)),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              expense.sharedBetweenEmails.isEmpty
                                  ? 'মেসের সবার মাঝে ভাগ হবে'
                                  : '${expense.sharedBetweenEmails.length} জন সদস্যের মাঝে ভাগ হবে',
                              style: const TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          if (widget.isAdmin)
                            Container(
                              padding: const EdgeInsets.all(3),
                              decoration: BoxDecoration(
                                color: theme.bgColor.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Icon(Icons.edit_rounded,
                                  size: 12, color: theme.iconColor),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// কার্ড থিম ডেটা ক্লাস
// ============================================================================

class _CardTheme {
  final Color iconColor;
  final Color bgColor;
  final List<Color> bgGradient;
  final IconData icon;

  const _CardTheme({
    required this.iconColor,
    required this.bgColor,
    required this.bgGradient,
    required this.icon,
  });
}

// ============================================================================
// 💫 পালসিং FAB বাটন (HomeScreen ম্যাচিং কালার)
// ============================================================================

class _PulsingFab extends StatefulWidget {
  final VoidCallback onTap;
  const _PulsingFab({required this.onTap});

  @override
  State<_PulsingFab> createState() => _PulsingFabState();
}

class _PulsingFabState extends State<_PulsingFab>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 18, right: 18),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) {
          setState(() => _pressed = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _pressed = false),
        child: AnimatedScale(
          scale: _pressed ? 0.95 : 1.0,
          duration: const Duration(milliseconds: 120),
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (_, child) {
              return Container(
                width: double.infinity,
                height: 58,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      _MarketScreenState.navyDeep,
                      _MarketScreenState.navyMid,
                      _MarketScreenState.navyLight,
                    ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _MarketScreenState.navyMid.withValues(
                        alpha: 0.3 + _pulseController.value * 0.2,
                      ),
                      blurRadius: 18 + _pulseController.value * 10,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: child,
              );
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded,
                    color: Colors.white, size: 24),
                SizedBox(width: 10),
                Text(
                  'নতুন বাজার যোগ করুন',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ☁️ পালসিং লোগো
// ============================================================================

class _PulsingLogo extends StatefulWidget {
  @override
  State<_PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<_PulsingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        return Transform.scale(
          scale: 0.85 + (_c.value * 0.15),
          child: child,
        );
      },
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              _MarketScreenState.navyDeep,
              _MarketScreenState.navyMid,
              _MarketScreenState.navyLight,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _MarketScreenState.navyMid.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(Icons.shopping_basket_rounded,
            color: Colors.white, size: 30),
      ),
    );
  }
}

// ============================================================================
// 🎈 ফ্লোটিং খালি স্টেট আইকন
// ============================================================================

class _FloatingEmptyIcon extends StatefulWidget {
  @override
  State<_FloatingEmptyIcon> createState() => _FloatingEmptyIconState();
}

class _FloatingEmptyIconState extends State<_FloatingEmptyIcon>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        return Transform.translate(
          offset: Offset(0, -8 * _c.value),
          child: child,
        );
      },
      child: Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDBEAFE), Color(0xFFEFF6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: _MarketScreenState.navyLight.withValues(alpha: 0.15),
              blurRadius: 25,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Icon(
          Icons.shopping_basket_rounded,
          color: _MarketScreenState.navyLight,
          size: 50,
        ),
      ),
    );
  }
}

// ============================================================================
// 🔘 ট্যাপ স্কেল বাটন (রিইউজেবল)
// ============================================================================

class _TapScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;

  const _TapScaleButton({required this.onTap, required this.child});

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton> {
  bool _p = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) {
        setState(() => _p = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedScale(
        scale: _p ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

// ============================================================================
// AnimatedBuilder হেল্পার
// ============================================================================

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}