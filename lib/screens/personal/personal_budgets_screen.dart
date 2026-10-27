import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/personal_budget_model.dart';
import '../../models/personal_transaction_model.dart';
import '../../services/personal_finance_service.dart';
import 'add_edit_budget_screen.dart';

class PersonalBudgetsScreen extends StatefulWidget {
  const PersonalBudgetsScreen({super.key});

  @override
  State<PersonalBudgetsScreen> createState() => _PersonalBudgetsScreenState();
}

class _PersonalBudgetsScreenState extends State<PersonalBudgetsScreen> {
  final PersonalFinanceService _financeService = PersonalFinanceService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('মাসিক ক্যাটাগরি বাজেট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<PersonalBudgetModel>>(
        stream: _financeService.getBudgets(),
        builder: (context, budgetSnap) {
          if (budgetSnap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          final budgets = budgetSnap.data ?? [];

          return StreamBuilder<List<PersonalTransactionModel>>(
            stream: _financeService.getTransactions(),
            builder: (context, txSnap) {
              final txs = txSnap.data ?? [];
              final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (budgets.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(30),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Column(
                          children: [
                            Icon(Icons.pie_chart_outline_rounded, size: 50, color: AppColors.textSecondary),
                            SizedBox(height: 12),
                            Text('এই মাসে কোনো বাজেট সেট করা নেই', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            SizedBox(height: 6),
                            Text('অহেতুক খরচ কমাতে নিচের বাটন চেপে বাজেট সেট করুন।', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          ],
                        ),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: budgets.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final budget = budgets[index];

                          double spent = 0.0;
                          for (var tx in txs) {
                            if (tx.type == 'expense' &&
                                tx.categoryId == budget.categoryId &&
                                DateFormat('yyyy-MM').format(tx.transactionDate) == currentMonth) {
                              spent += tx.amountInTaka;
                            }
                          }

                          double budgetAmount = budget.budgetAmountInTaka;
                          double progress = budgetAmount > 0 ? (spent / budgetAmount) : 0.0;
                          if (progress > 1.0) progress = 1.0;

                          Color progressColor = AppColors.success;
                          if (spent >= budgetAmount) {
                            progressColor = AppColors.danger;
                          } else if (spent >= budgetAmount * 0.8) {
                            progressColor = Colors.orange;
                          }

                          return Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
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
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      budget.categoryName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                    ),
                                    Text(
                                      '৳${spent.toStringAsFixed(0)} / ৳${budgetAmount.toStringAsFixed(0)}',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: progressColor),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 10,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(progressColor),
                                  ),
                                ),
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      spent >= budgetAmount
                                          ? 'বাজেট পার হয়ে গেছে ৳${(spent - budgetAmount).toStringAsFixed(0)}!'
                                          : 'অবশিষ্ট: ৳${(budgetAmount - spent).toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: spent >= budgetAmount ? AppColors.danger : AppColors.textSecondary,
                                      ),
                                    ),
                                    Text(
                                      '${(progress * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: progressColor),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const AddEditBudgetScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('বাজেট সেট করুন', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
