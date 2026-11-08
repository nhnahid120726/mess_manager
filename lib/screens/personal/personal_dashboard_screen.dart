import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/personal_transaction_model.dart';
import '../../services/personal_finance_service.dart';
import 'add_personal_transaction_screen.dart';
import 'personal_accounts_screen.dart';
import 'personal_transactions_screen.dart';
import 'personal_budgets_screen.dart';
import 'savings_goals_screen.dart';
import 'debts_screen.dart';
import 'recurring_bills_screen.dart';

class PersonalDashboardScreen extends StatefulWidget {
  final VoidCallback? onToggleModule;

  const PersonalDashboardScreen({super.key, this.onToggleModule});

  @override
  State<PersonalDashboardScreen> createState() =>
      _PersonalDashboardScreenState();
}

class _PersonalDashboardScreenState extends State<PersonalDashboardScreen>
    with AutomaticKeepAliveClientMixin<PersonalDashboardScreen> {
  final PersonalFinanceService _financeService = PersonalFinanceService();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final topInset = MediaQuery.paddingOf(context).top;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async {
          setState(() {});
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Card
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(18, topInset + 10, 18, 30),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF101A3A),
                      Color(0xFF1E3A8A),
                      Color(0xFF2563EB),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(30),
                    bottomRight: Radius.circular(30),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.18),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            if (Navigator.canPop(context)) ...[
                              IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_rounded,
                                  color: Colors.white,
                                ),
                                onPressed: () => Navigator.pop(context),
                              ),
                              const SizedBox(width: 8),
                            ],
                            const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ব্যক্তিগত ওয়ালেট',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'আপনার অর্থের স্মার্ট হিসাব',
                                  style: TextStyle(
                                    color: Color(0xFFDCE7FF),
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        InkWell(
                          onTap: widget.onToggleModule,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 11,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.14),
                              borderRadius: BorderRadius.circular(15),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.22),
                              ),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.groups_rounded,
                                  color: Colors.white,
                                  size: 17,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'মেস ম্যানেজার',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Financial Summary Stream
              StreamBuilder<Map<String, dynamic>>(
                stream: _financeService.getFinancialSummary(),
                builder: (context, snapshot) {
                  final summary =
                      snapshot.data ??
                      {
                        'totalBalance': 0.0,
                        'monthlyIncome': 0.0,
                        'monthlyExpenses': 0.0,
                        'netCashFlow': 0.0,
                        'outstandingDebt': 0.0,
                      };

                  final double totalBalance = summary['totalBalance'] ?? 0.0;
                  final double monthlyIncome = summary['monthlyIncome'] ?? 0.0;
                  final double monthlyExpenses =
                      summary['monthlyExpenses'] ?? 0.0;

                  return Transform.translate(
                    offset: const Offset(0, -18),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Column(
                        children: [
                          // Main Balance Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(26),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(
                                    alpha: 0.2,
                                  ),
                                  blurRadius: 20,
                                  offset: const Offset(0, 9),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(9),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(
                                          alpha: 0.16,
                                        ),
                                        borderRadius: BorderRadius.circular(13),
                                      ),
                                      child: const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        color: Colors.white,
                                        size: 19,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    const Expanded(
                                      child: Text(
                                        'মোট ক্যাশ ব্যালেন্স',
                                        style: TextStyle(
                                          color: Color(0xFFDCE7FF),
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    const Icon(
                                      Icons.visibility_outlined,
                                      color: Color(0xFFBFDBFE),
                                      size: 19,
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 13),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '৳ ${totalBalance.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 34,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: -0.8,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _SummarySubCard(
                                        title: 'মোট আয়',
                                        amount: monthlyIncome,
                                        icon: Icons.arrow_downward_rounded,
                                        color: const Color(0xFF10B981),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _SummarySubCard(
                                        title: 'মোট খরচ',
                                        amount: monthlyExpenses,
                                        icon: Icons.arrow_upward_rounded,
                                        color: const Color(0xFFFB7185),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'দ্রুত কাজ',
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          LayoutBuilder(
                            builder: (context, constraints) {
                              final itemWidth = (constraints.maxWidth - 20) / 3;
                              return Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  SizedBox(
                                    width: itemWidth,
                                    child: _QuickActionButton(
                                      icon: Icons.add_circle_outline_rounded,
                                      label: 'আয় যোগ',
                                      color: AppColors.success,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AddPersonalTransactionScreen(
                                                initialType: 'income',
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _QuickActionButton(
                                      icon: Icons.remove_circle_outline_rounded,
                                      label: 'খরচ যোগ',
                                      color: AppColors.danger,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const AddPersonalTransactionScreen(
                                                initialType: 'expense',
                                              ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _QuickActionButton(
                                      icon:
                                          Icons.account_balance_wallet_rounded,
                                      label: 'ওয়ালেট',
                                      color: AppColors.accent,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PersonalAccountsScreen(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _QuickActionButton(
                                      icon: Icons.pie_chart_rounded,
                                      label: 'বাজেট',
                                      color: Colors.purple,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const PersonalBudgetsScreen(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _QuickActionButton(
                                      icon: Icons.savings_rounded,
                                      label: 'সঞ্চয়',
                                      color: AppColors.success,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const SavingsGoalsScreen(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _QuickActionButton(
                                      icon: Icons.handshake_rounded,
                                      label: 'দেনা-পাওনা',
                                      color: AppColors.danger,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const DebtsScreen(),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: itemWidth,
                                    child: _QuickActionButton(
                                      icon: Icons.receipt_long_rounded,
                                      label: 'বিল',
                                      color: Colors.orange,
                                      onTap: () => Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const RecurringBillsScreen(),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 10),

              // Category Expense Breakdown Chart
              StreamBuilder<List<PersonalTransactionModel>>(
                stream: _financeService.getTransactions(),
                builder: (context, snapshot) {
                  final txs = snapshot.data ?? [];
                  final currentMonth = DateFormat('yyyy-MM')
                      .format(DateTime.now());
                  final expenses = txs
                      .where(
                        (t) =>
                            t.type == 'expense' &&
                            DateFormat('yyyy-MM').format(t.transactionDate) ==
                                currentMonth,
                      )
                      .toList();

                  if (expenses.isEmpty) return const SizedBox.shrink();

                  Map<String, double> categoryTotals = {};
                  for (var e in expenses) {
                    categoryTotals[e.categoryName] =
                        (categoryTotals[e.categoryName] ?? 0) + e.amountInTaka;
                  }

                  List<PieChartSectionData> sections = [];
                  final colors = [
                    AppColors.danger,
                    AppColors.accent,
                    AppColors.success,
                    Colors.purple,
                    Colors.orange,
                    Colors.teal,
                  ];
                  int i = 0;
                  categoryTotals.forEach((cat, total) {
                    sections.add(
                      PieChartSectionData(
                        color: colors[i % colors.length],
                        value: total,
                        title: '৳${total.toStringAsFixed(0)}',
                        radius: 35,
                        titleStyle: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    );
                    i++;
                  });

                  final categoryEntries = categoryTotals.entries.toList();

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(23),
                        border: Border.all(color: const Color(0xFFE9EEF6)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF172554)
                                .withValues(alpha: 0.035),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'এই মাসের খরচ',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 3),
                          const Text(
                            'ক্যাটাগরি অনুযায়ী বিভাজন',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 170,
                            child: PieChart(
                              PieChartData(
                                sections: sections,
                                centerSpaceRadius: 48,
                                sectionsSpace: 3,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 14,
                            runSpacing: 10,
                            children: List.generate(categoryEntries.length, (
                              index,
                            ) {
                              final entry = categoryEntries[index];
                              return SizedBox(
                                width:
                                    (MediaQuery.sizeOf(context).width - 72) / 2,
                                child: Row(
                                  children: [
                                    Container(
                                      width: 9,
                                      height: 9,
                                      decoration: BoxDecoration(
                                        color: colors[index % colors.length],
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        entry.key,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: AppColors.textSecondary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      '৳${entry.value.toStringAsFixed(0)}',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              // Recent Transactions Header
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 14, 10),
                child: Row(
                  children: [
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'সাম্প্রতিক লেনদেন',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 17,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'আপনার সর্বশেষ আয় ও খরচ',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const PersonalTransactionsScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.arrow_forward_rounded, size: 15),
                      label: const Text('সব দেখুন'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        textStyle: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Recent Personal Transactions Stream
              StreamBuilder<List<PersonalTransactionModel>>(
                stream: _financeService.getTransactions(),
                builder: (context, snapshot) {
                  final txs = (snapshot.data ?? []).take(5).toList();

                  if (txs.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE9EEF6)),
                      ),
                      child: const Column(
                        children: [
                          Icon(
                            Icons.receipt_long_rounded,
                            color: Color(0xFFB7C4D8),
                            size: 38,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'এখনও কোনো লেনদেন নেই',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'আয় বা খরচ যোগ করলে এখানে দেখা যাবে',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: txs.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 10),
                      itemBuilder: (context, index) {
                        final tx = txs[index];
                        final isIncome = tx.type == 'income';
                        final isTransfer = tx.type == 'transfer';
                        final isPositive =
                            isIncome ||
                            tx.type == 'refund' ||
                            tx.type == 'debt_received' ||
                            tx.type == 'savings_withdrawal';
                        final transactionColor = isTransfer
                            ? AppColors.accent
                            : isPositive
                            ? AppColors.success
                            : AppColors.danger;
                        final transactionIcon = isTransfer
                            ? Icons.swap_horiz_rounded
                            : isPositive
                            ? Icons.arrow_downward_rounded
                            : Icons.arrow_upward_rounded;
                        final amountPrefix = isTransfer
                            ? ''
                            : isPositive
                            ? '+'
                            : '-';

                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 13,
                            vertical: 13,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFE9EEF6)),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF172554)
                                    .withValues(alpha: 0.025),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: transactionColor.withValues(
                                    alpha: 0.11,
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  transactionIcon,
                                  color: transactionColor,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 11),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      tx.description,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      '${tx.categoryName}  •  ${DateFormat('dd MMM yyyy').format(tx.transactionDate)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  '$amountPrefix৳${tx.amountInTaka.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 13,
                                    color: transactionColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummarySubCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const _SummarySubCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFFDCE7FF),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              '৳${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 13),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE9EEF6)),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF172554).withValues(alpha: 0.025),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 10.5,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
