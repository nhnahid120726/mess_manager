import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/financial_service.dart';
import '../services/auth_service.dart';
import '../models/deposit_model.dart';
import '../models/expense_model.dart';
import 'add_deposit_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen>
    with
        AutomaticKeepAliveClientMixin<AccountsScreen>,
        TickerProviderStateMixin {
  final FinancialService _financialService = FinancialService();
  final AuthService _authService = AuthService();

  bool _isAdmin = false;

  // ── Animations ──
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  late AnimationController _counterCtrl;
  late Animation<double> _counterAnim;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  late AnimationController _shimmerCtrl;

  double _targetTotal = 0;
  int _targetConfirmed = 0;
  double _displayTotal = 0;
  int _displayConfirmed = 0;

  // ── Navy Palette ──
  static const Color _navyDeep = Color(0xFF0F172A);
  static const Color _navyMid = Color(0xFF1E3A8A);
  static const Color _navyLight = Color(0xFF2563EB);
  static const Color _navyAccent = Color(0xFF3B82F6);
  static const Color _pageBg = Color(0xFFF0F4F8);

  // ── Card Themes ──
  static const List<_CardAccent> _accents = [
    _CardAccent(
      stripe: Color(0xFF8B5CF6),
      icon: Color(0xFF8B5CF6),
      bg: Color(0xFFEDE9FE),
    ),
    _CardAccent(
      stripe: Color(0xFF06B6D4),
      icon: Color(0xFF06B6D4),
      bg: Color(0xFFCFFAFE),
    ),
    _CardAccent(
      stripe: Color(0xFFEC4899),
      icon: Color(0xFFEC4899),
      bg: Color(0xFFFCE7F3),
    ),
    _CardAccent(
      stripe: Color(0xFF2563EB),
      icon: Color(0xFF2563EB),
      bg: Color(0xFFDBEAFE),
    ),
  ];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _headerFade = CurvedAnimation(
      parent: _headerCtrl,
      curve: Curves.easeOutCubic,
    );
    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -0.4),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _counterCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _counterAnim = CurvedAnimation(
      parent: _counterCtrl,
      curve: Curves.easeOutCubic,
    );
    _counterAnim.addListener(() {
      if (mounted) {
        setState(() {
          _displayTotal = _counterAnim.value * _targetTotal;
          _displayConfirmed = (_counterAnim.value * _targetConfirmed).round();
        });
      }
    });

    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _pulseAnim = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _shimmerCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _headerCtrl.forward();
    _pulseCtrl.repeat(reverse: true);
    _shimmerCtrl.repeat();

    _checkAdminStatus();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _counterCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _animateCounters(double total, int confirmed) {
    if (_targetTotal != total || _targetConfirmed != confirmed) {
      _targetTotal = total;
      _targetConfirmed = confirmed;
      _counterCtrl.reset();
      _counterCtrl.forward();
    }
  }

  Future<void> _checkAdminStatus() async {
    final user = _authService.currentUser;
    if (user != null && user.email != null) {
      try {
        final DocumentSnapshot doc = await FirebaseFirestore.instance
            .collection('members')
            .doc(user.email)
            .get();

        if (doc.exists && mounted) {
          setState(() {
            _isAdmin = doc['role'] == 'admin';
          });
        }
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        bottom: false,
        child: StreamBuilder<List<DepositModel>>(
          stream: _financialService.getMonthlyDeposits(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                !snapshot.hasData) {
              return Column(
                children: [
                  _buildFixedHeader(0, 0, []),
                  Expanded(child: _buildShimmerList()),
                ],
              );
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  _buildFixedHeader(0, 0, []),
                  Expanded(child: _buildErrorState(snapshot.error)),
                ],
              );
            }

            final deposits = snapshot.data ?? [];
            final double total = deposits.fold(
              0.0,
              (acc, item) => acc + item.amountInTaka,
            );
            final int confirmedCount = deposits
                .where((e) => e.status == 'confirmed')
                .length;

            _animateCounters(total, confirmedCount);

            return Column(
              children: [
                _buildFixedHeader(total, confirmedCount, deposits),
                Expanded(
                  child: RefreshIndicator(
                    color: _navyLight,
                    backgroundColor: Colors.white,
                    onRefresh: () async {
                      setState(() {});
                      await Future.delayed(const Duration(milliseconds: 600));
                    },
                    child: deposits.isEmpty
                        ? ListView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.55,
                                child: _buildEmptyState(),
                              ),
                            ],
                          )
                        : ListView.builder(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                            itemCount: deposits.length,
                            itemBuilder: (context, index) {
                              return _buildDepositCard(deposits[index], index);
                            },
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  FIXED HEADER
  // ═══════════════════════════════════════════
  Widget _buildFixedHeader(double total, int confirmed, [List<DepositModel>? deposits]) {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 22),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_navyDeep, _navyMid, _navyLight],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x331E3A8A),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title Row ──
              Row(
                children: [
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.25),
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _navyAccent.withValues(
                                  alpha: 0.3 * _pulseAnim.value,
                                ),
                                blurRadius: 12 * _pulseAnim.value,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'মেস অ্যাকাউন্ট',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'সদস্যদের টাকা জমার হিসাব',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Month badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          size: 12,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM').format(DateTime.now()),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  _TapScaleButton(
                    onTap: () {
                      Navigator.push(
                        context,
                        PageRouteBuilder(
                          pageBuilder: (_, _, _) =>
                              AddDepositScreen(isAdmin: _isAdmin),
                          transitionsBuilder: (_, anim, _, child) {
                            return SlideTransition(
                              position: Tween<Offset>(
                                begin: const Offset(0, 1),
                                end: Offset.zero,
                              ).animate(
                                CurvedAnimation(
                                  parent: anim,
                                  curve: Curves.easeOutCubic,
                                ),
                              ),
                              child: FadeTransition(
                                opacity: anim,
                                child: child,
                              ),
                            );
                          },
                          transitionDuration:
                          const Duration(milliseconds: 400),
                        ),
                      );
                    },
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Analytics / Breakdown Button
                  _TapScaleButton(
                    onTap: () => _showMessAnalyticsSheet(context, deposits ?? []),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: const Icon(
                        Icons.pie_chart_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ── Summary Cards ──
              Row(
                children: [
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.payments_rounded,
                      title: 'মোট জমা',
                      value: '৳${_displayTotal.toStringAsFixed(0)}',
                      accentColor: const Color(0xFF10B981),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _buildSummaryCard(
                      icon: Icons.verified_rounded,
                      title: 'গৃহীত',
                      value: '$_displayConfirmed টি',
                      accentColor: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard({
    required IconData icon,
    required String title,
    required String value,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(11),
              border: Border.all(
                color: accentColor.withValues(alpha: 0.4),
                width: 1,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  MESS ANALYTICS & BREAKDOWN BOTTOM SHEET
  // ═══════════════════════════════════════════
  void _showMessAnalyticsSheet(BuildContext context, List<DepositModel> deposits) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StreamBuilder<List<ExpenseModel>>(
        stream: _financialService.getMonthlyExpenses(),
        builder: (context, snapshot) {
          final expenses = snapshot.data ?? [];

          double totalDeposits = deposits
              .where((d) => d.status == 'confirmed')
              .fold(0.0, (acc, d) => acc + d.amountInTaka);
          double pendingDeposits = deposits
              .where((d) => d.status == 'pending')
              .fold(0.0, (acc, d) => acc + d.amountInTaka);

          double totalExpense = expenses.fold(0.0, (acc, e) => acc + e.totalAmountInTaka);
          double messFundExpense = expenses
              .where((e) => e.paymentSource == 'mess_fund')
              .fold(0.0, (acc, e) => acc + e.totalAmountInTaka);
          double personalExpense = expenses
              .where((e) => e.paymentSource == 'personal')
              .fold(0.0, (acc, e) => acc + e.totalAmountInTaka);

          double netBalance = totalDeposits - messFundExpense;
          double expensePercentage = totalDeposits > 0 ? (totalExpense / totalDeposits * 100) : 0.0;
          if (expensePercentage > 100) expensePercentage = 100.0;

          return Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(28),
                topRight: Radius.circular(28),
              ),
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        '📊 মেস হিসাব ও খরচ বিশ্লেষণ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          color: _navyDeep,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Expense vs Deposit Ratio Bar
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'জমার তুলনায় খরচের হার',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey),
                            ),
                            Text(
                              '${expensePercentage.toStringAsFixed(1)}%',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: _navyLight),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: LinearProgressIndicator(
                            value: expensePercentage / 100,
                            minHeight: 12,
                            backgroundColor: Colors.grey.shade200,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              expensePercentage > 85 ? Colors.red : const Color(0xFF10B981),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // Metrics Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsMetricCard(
                          title: 'মোট জমা (Confirmed)',
                          amount: '৳${totalDeposits.toStringAsFixed(0)}',
                          color: const Color(0xFF10B981),
                          icon: Icons.account_balance_wallet_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsMetricCard(
                          title: 'মোট বাজার খরচ',
                          amount: '৳${totalExpense.toStringAsFixed(0)}',
                          color: const Color(0xFFEF4444),
                          icon: Icons.shopping_cart_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _buildAnalyticsMetricCard(
                          title: 'মেস ক্যাশ ব্যালেন্স',
                          amount: '৳${netBalance.toStringAsFixed(0)}',
                          color: const Color(0xFF2563EB),
                          icon: Icons.savings_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildAnalyticsMetricCard(
                          title: 'পেন্ডিং জমা',
                          amount: '৳${pendingDeposits.toStringAsFixed(0)}',
                          color: const Color(0xFFF59E0B),
                          icon: Icons.hourglass_top_rounded,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // Source Breakdown
                  const Text(
                    'খরচের উৎস (Payment Sources)',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: _navyDeep),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('মেস ফান্ড থেকে', style: TextStyle(fontSize: 11, color: Colors.blue, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('৳${messFundExpense.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _navyDeep)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFDF4FF),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: const Color(0xFFF5D0FE)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('ব্যক্তিগত পকেট থেকে', style: TextStyle(fontSize: 11, color: Colors.purple, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('৳${personalExpense.toStringAsFixed(0)}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: _navyDeep)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAnalyticsMetricCard({required String title, required String amount, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(title, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey.shade700), maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(amount, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color)),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  DEPOSIT CARD
  // ═══════════════════════════════════════════
  Widget _buildDepositCard(DepositModel deposit, int index) {
    final bool isConfirmed = deposit.status == 'confirmed';
    final String memberName = deposit.memberEmail.split('@').first;

    final accent = _accents[index % _accents.length];
    final statusColor = isConfirmed
        ? const Color(0xFF059669)
        : const Color(0xFFF59E0B);
    final statusBg = isConfirmed
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFFEF3C7);
    final statusBorder = isConfirmed
        ? const Color(0xFFA7F3D0)
        : const Color(0xFFFDE68A);

    final delay = index * 70;

    return AnimatedBuilder(
      animation: _headerCtrl,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(
          ((_headerCtrl.value * 900 - delay) / 500).clamp(0.0, 1.0),
        );
        return Transform.translate(
          offset: Offset(0, 30 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: _TapScaleButton(
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: accent.stripe.withValues(alpha: 0.08),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: IntrinsicHeight(
              child: Row(
                children: [
                  // ── Left Accent Stripe ──
                  Container(
                    width: 5,
                    decoration: BoxDecoration(color: accent.stripe),
                  ),

                  // ── Card Content ──
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        children: [
                          // ── Top Row: Avatar + Name + Amount ──
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Glowing Avatar
                              AnimatedBuilder(
                                animation: _pulseAnim,
                                builder: (context, child) {
                                  return Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          accent.icon,
                                          accent.icon.withValues(alpha: 0.7),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                      boxShadow: [
                                        BoxShadow(
                                          color: accent.icon.withValues(
                                            alpha: 0.25 * _pulseAnim.value,
                                          ),
                                          blurRadius: 10 * _pulseAnim.value,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Text(
                                        memberName.isNotEmpty
                                            ? memberName[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),

                              const SizedBox(width: 12),

                              // Name + Date
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      memberName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: _navyDeep,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: -0.2,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.schedule_rounded,
                                          size: 11,
                                          color: Colors.grey.shade500,
                                        ),
                                        const SizedBox(width: 4),
                                        Flexible(
                                          child: Text(
                                            _formatTimeAgo(deposit.createdAt),
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
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

                              // Amount Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD1FAE5),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: const Color(0xFFA7F3D0),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.arrow_downward_rounded,
                                      size: 13,
                                      color: Color(0xFF059669),
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      '৳${deposit.amountInTaka.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        color: Color(0xFF059669),
                                        fontSize: 15,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: -0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // ── Payment Method ──
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: accent.bg,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Icon(
                                    Icons.credit_card_rounded,
                                    color: accent.icon,
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'পেমেন্ট মাধ্যম',
                                  style: TextStyle(
                                    color: _navyDeep.withValues(alpha: 0.6),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                Flexible(
                                  child: Text(
                                    deposit.paymentMethod,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    textAlign: TextAlign.end,
                                    style: TextStyle(
                                      color: accent.icon,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 10),

                          // ── Status Row ──
                          Row(
                            children: [
                              Icon(
                                isConfirmed
                                    ? Icons.check_circle_rounded
                                    : Icons.schedule_rounded,
                                size: 14,
                                color: statusColor,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  isConfirmed
                                      ? 'পেমেন্ট সফলভাবে গৃহীত'
                                      : 'পেমেন্ট যাচাইয়ের অপেক্ষায়',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: statusColor,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: statusBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: statusBorder,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: BoxDecoration(
                                        color: statusColor,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      isConfirmed ? 'গৃহীত' : 'অপেক্ষমাণ',
                                      style: TextStyle(
                                        color: statusColor,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
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
    );
  }

  String _formatTimeAgo(DateTime date) {
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'এইমাত্র';
    if (diff.inMinutes < 60) return '${diff.inMinutes} মিনিট আগে';
    if (diff.inHours < 24) return '${diff.inHours} ঘণ্টা আগে';
    if (diff.inDays < 7) return '${diff.inDays} দিন আগে';
    return DateFormat('dd MMM yyyy').format(date);
  }

  // ═══════════════════════════════════════════
  //  SHIMMER LOADING
  // ═══════════════════════════════════════════
  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
      itemCount: 4,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _shimmerCtrl,
          builder: (context, child) {
            final opacity =
                0.3 +
                0.3 * math.sin(_shimmerCtrl.value * 2 * math.pi + index * 0.5);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200.withValues(
                            alpha: opacity,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 120,
                              height: 14,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200.withValues(
                                  alpha: opacity,
                                ),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              width: 80,
                              height: 10,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200.withValues(
                                  alpha: opacity,
                                ),
                                borderRadius: BorderRadius.circular(5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 70,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200.withValues(
                            alpha: opacity,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200.withValues(alpha: opacity),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  //  ERROR STATE
  // ═══════════════════════════════════════════
  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFECACA)),
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
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: const Icon(
                        Icons.cloud_off_rounded,
                        color: Color(0xFFDC2626),
                        size: 30,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              const Text(
                'হিসাব লোড করা যায়নি',
                style: TextStyle(
                  color: _navyDeep,
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
                  color: Colors.grey.shade600,
                  fontSize: 12,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════════════════════
  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _navyLight.withValues(alpha: 0.12),
                          _navyLight.withValues(alpha: 0.04),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _navyLight.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _navyLight.withValues(
                            alpha: 0.1 * _pulseAnim.value,
                          ),
                          blurRadius: 20 * _pulseAnim.value,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      color: _navyLight.withValues(alpha: 0.7),
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'কোনো জমা পাওয়া যায়নি',
              style: TextStyle(
                color: _navyDeep,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'সদস্যদের নতুন টাকা জমা হলে\nএখানে সুন্দরভাবে দেখা যাবে।',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _TapScaleButton(
              onTap: () {
                Navigator.push(
                  context,
                  PageRouteBuilder(
                    pageBuilder: (_, _, _) =>
                        AddDepositScreen(isAdmin: _isAdmin),
                    transitionsBuilder: (_, anim, _, child) => SlideTransition(
                      position:
                          Tween<Offset>(
                            begin: const Offset(0, 1),
                            end: Offset.zero,
                          ).animate(
                            CurvedAnimation(
                              parent: anim,
                              curve: Curves.easeOutCubic,
                            ),
                          ),
                      child: child,
                    ),
                    transitionDuration: const Duration(milliseconds: 400),
                  ),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_navyDeep, _navyMid],
                  ),
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: _navyLight.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.add_rounded,
                      size: 18,
                      color: Colors.white,
                    ),
                    SizedBox(width: 6),
                    Text(
                      'টাকা জমা দিন',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════

class _CardAccent {
  final Color stripe;
  final Color icon;
  final Color bg;

  const _CardAccent({
    required this.stripe,
    required this.icon,
    required this.bg,
  });
}

class _TapScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TapScaleButton({required this.child, required this.onTap});

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    );
    _scale = Tween<double>(
      begin: 1.0,
      end: 0.97,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    Listenable? animation,
    Listenable? listenable,
    required this.builder,
    this.child,
  }) : super(
         listenable: animation ?? listenable ?? const AlwaysStoppedAnimation(0),
       );

  Animation<double> get animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}
