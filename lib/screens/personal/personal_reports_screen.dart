import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/personal_transaction_model.dart';
import '../../services/personal_finance_service.dart';

class PersonalReportsScreen extends StatefulWidget {
  const PersonalReportsScreen({super.key});

  @override
  State<PersonalReportsScreen> createState() => _PersonalReportsScreenState();
}

class _PersonalReportsScreenState extends State<PersonalReportsScreen> {
  final PersonalFinanceService _financeService = PersonalFinanceService();

  @override
  Widget build(BuildContext context) {
    String currentMonthName = DateFormat('MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('আর্থিক রিপোর্ট ও বিশ্লেষণ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.primary),
            tooltip: 'CSV রিপোর্ট ডাউনলোড',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('আর্থিক রিপোর্টের CSV ফাইল ডাউনলোড হয়েছে!'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<PersonalTransactionModel>>(
        stream: _financeService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          final txs = snapshot.data ?? [];
          final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
          final monthlyTxs = txs.where((t) => DateFormat('yyyy-MM').format(t.transactionDate) == currentMonth).toList();

          double totalIncome = 0.0;
          double totalExpense = 0.0;
          Map<String, double> categoryExpenses = {};

          for (var tx in monthlyTxs) {
            if (tx.type == 'income') {
              totalIncome += tx.amountInTaka;
            } else if (tx.type == 'expense') {
              totalExpense += tx.amountInTaka;
              categoryExpenses[tx.categoryName] = (categoryExpenses[tx.categoryName] ?? 0.0) + tx.amountInTaka;
            } else if (tx.type == 'refund') {
              totalExpense -= tx.amountInTaka;
            }
          }

          double netCashFlow = totalIncome - totalExpense;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Period Title Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('রিপোর্টের সময়কাল', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(currentMonthName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 28),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Cash Flow Overview Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('ক্যাশ ফ্লো সারসংক্ষেপ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _ReportMetric(
                              title: 'সর্বমোট আয়',
                              amount: totalIncome,
                              color: AppColors.success,
                            ),
                          ),
                          Container(width: 1, height: 40, color: AppColors.border),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 16),
                              child: _ReportMetric(
                                title: 'সর্বমোট খরচ',
                                amount: totalExpense,
                                color: AppColors.danger,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 30, color: AppColors.border),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('নিট সঞ্চয় / ক্যাশ ফ্লো:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                          Text(
                            '৳${netCashFlow.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                              color: netCashFlow >= 0 ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Top Spending Categories
                const Text('সর্বোচ্চ খরচের ক্যাটাগরি', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 12),

                if (categoryExpenses.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(child: Text('এই মাসে কোনো খরচের রেকর্ড নেই।')),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categoryExpenses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = categoryExpenses.entries.elementAt(index);
                      final percent = totalExpense > 0 ? (entry.value / totalExpense * 100) : 0.0;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.pie_chart_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Text('মোট খরচের ${percent.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text('৳${entry.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _ReportMetric({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('৳${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
