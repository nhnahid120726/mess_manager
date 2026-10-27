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
  State<PersonalDashboardScreen> createState() => _PersonalDashboardScreenState();
}

class _PersonalDashboardScreenState extends State<PersonalDashboardScreen> with AutomaticKeepAliveClientMixin<PersonalDashboardScreen> {
  final PersonalFinanceService _financeService = PersonalFinanceService();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
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
              padding: const EdgeInsets.fromLTRB(20, 50, 20, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primaryDark, AppColors.primary],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
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
                              icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const SizedBox(width: 8),
                          ],
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'ব্যক্তিগত ওয়ালেট',
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'আয় ও খরচের সঠিক হিসাব',
                                style: TextStyle(color: Colors.white70, fontSize: 11),
                              ),
                            ],
                          ),
                        ],
                      ),
                      InkWell(
                        onTap: widget.onToggleModule,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.groups_rounded, color: Colors.white, size: 16),
                              SizedBox(width: 5),
                              Text(
                                'মেস ম্যানেজার',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11.5,
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
                final summary = snapshot.data ?? {
                  'totalBalance': 0.0,
                  'monthlyIncome': 0.0,
                  'monthlyExpenses': 0.0,
                  'netCashFlow': 0.0,
                  'outstandingDebt': 0.0,
                };

                final double totalBalance = summary['totalBalance'] ?? 0.0;
                final double monthlyIncome = summary['monthlyIncome'] ?? 0.0;
                final double monthlyExpenses = summary['monthlyExpenses'] ?? 0.0;

                return Transform.translate(
                  offset: const Offset(0, -25),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Main Balance Card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(22),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: AppColors.border),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('মোট ক্যাশ ব্যালেন্স', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text(
                                '৳ ${totalBalance.toStringAsFixed(2)}',
                                style: const TextStyle(color: AppColors.textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 20),
                              Row(
                                children: [
                                  Expanded(
                                    child: _SummarySubCard(
                                      title: 'মোট আয়',
                                      amount: monthlyIncome,
                                      icon: Icons.arrow_downward_rounded,
                                      color: AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _SummarySubCard(
                                      title: 'মোট খরচ',
                                      amount: monthlyExpenses,
                                      icon: Icons.arrow_upward_rounded,
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        // Quick Actions
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.add_circle_outline_rounded,
                                label: 'আয় যোগ',
                                color: AppColors.success,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddPersonalTransactionScreen(initialType: 'income')),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.remove_circle_outline_rounded,
                                label: 'খরচ যোগ',
                                color: AppColors.danger,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const AddPersonalTransactionScreen(initialType: 'expense')),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.account_balance_wallet_rounded,
                                label: 'ওয়ালেট',
                                color: AppColors.accent,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const PersonalAccountsScreen()),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Financial Planning Tools
                        Row(
                          children: [
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.pie_chart_rounded,
                                label: 'বাজেট',
                                color: Colors.purple,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const PersonalBudgetsScreen()),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.savings_rounded,
                                label: 'সঞ্চয়',
                                color: AppColors.success,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const SavingsGoalsScreen()),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.handshake_rounded,
                                label: 'দেনা-পাওনা',
                                color: AppColors.danger,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const DebtsScreen()),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _QuickActionButton(
                                icon: Icons.receipt_long_rounded,
                                label: 'বিল',
                                color: Colors.orange,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const RecurringBillsScreen()),
                                  );
                                },
                              ),
                            ),
                          ],
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
                final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
                final expenses = txs.where((t) => t.type == 'expense' && DateFormat('yyyy-MM').format(t.transactionDate) == currentMonth).toList();

                if (expenses.isEmpty) return const SizedBox.shrink();

                Map<String, double> categoryTotals = {};
                for (var e in expenses) {
                  categoryTotals[e.categoryName] = (categoryTotals[e.categoryName] ?? 0) + e.amountInTaka;
                }

                List<PieChartSectionData> sections = [];
                final colors = [
                  AppColors.danger, AppColors.accent, AppColors.success, Colors.purple, Colors.orange, Colors.teal
                ];
                int i = 0;
                categoryTotals.forEach((cat, total) {
                  sections.add(
                    PieChartSectionData(
                      color: colors[i % colors.length],
                      value: total,
                      title: '৳${total.toStringAsFixed(0)}',
                      radius: 35,
                      titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  );
                  i++;
                });

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ক্যাটাগরি অনুযায়ী খরচের চিত্র', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                        const SizedBox(height: 20),
                        SizedBox(
                          height: 180,
                          child: PieChart(
                            PieChartData(
                              sections: sections,
                              centerSpaceRadius: 40,
                              sectionsSpace: 2,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Recent Transactions Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('সাম্প্রতিক লেনদেন', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PersonalTransactionsScreen()),
                      );
                    },
                    child: const Text('সব দেখুন', style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold)),
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
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(child: Text('এখনও কোনো ব্যক্তিগত লেনদেন হয়নি।')),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: txs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = txs[index];
                      final isIncome = tx.type == 'income';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: isIncome ? AppColors.success.withValues(alpha: 0.15) : AppColors.danger.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: isIncome ? AppColors.success : AppColors.danger,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(tx.description, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                                  Text(DateFormat('dd MMM yyyy').format(tx.transactionDate), style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text(
                              '${isIncome ? '+' : '-'}৳${tx.amountInTaka.toStringAsFixed(0)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isIncome ? AppColors.success : AppColors.danger),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(title, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            child: Text('৳${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
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
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.textPrimary)),
          ],
        ),
      ),
    );
  }
}
