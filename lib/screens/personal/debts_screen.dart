import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/debt_model.dart';
import '../../services/personal_finance_service.dart';
import 'add_edit_debt_screen.dart';

class DebtsScreen extends StatefulWidget {
  const DebtsScreen({super.key});

  @override
  State<DebtsScreen> createState() => _DebtsScreenState();
}

class _DebtsScreenState extends State<DebtsScreen> {
  final PersonalFinanceService _financeService = PersonalFinanceService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('দেনা ও পাওনা (Debts & Loans)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<DebtModel>>(
        stream: _financeService.getDebts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          final debts = snapshot.data ?? [];

          if (debts.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: const Icon(Icons.handshake_outlined, size: 50, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 16),
                    const Text('কোনো দেনা বা পাওনার হিসাব নেই', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    const Text('কাউকে ধার দিলে বা কারো থেকে ধার নিলে সেই হিসাব সহজে ট্র্যাক করুন।', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: debts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final debt = debts[index];
              final isBorrowed = debt.type == 'borrowed';

              return Container(
                padding: const EdgeInsets.all(16),
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
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: isBorrowed ? AppColors.danger.withValues(alpha: 0.15) : AppColors.success.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Icon(
                        isBorrowed ? Icons.call_received_rounded : Icons.call_made_rounded,
                        color: isBorrowed ? AppColors.danger : AppColors.success,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            debt.contactName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isBorrowed ? 'আপনি পাবেন না (দেনা/Liability)' : 'আপনি পাবেন (পাওনা/Receivable)',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isBorrowed ? AppColors.danger : AppColors.success),
                          ),
                          if (debt.dueDate != null) ...[
                            const SizedBox(height: 2),
                            Text('পরিশোধের শেষ তারিখ: ${DateFormat('dd MMM yyyy').format(debt.dueDate!)}', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                          ],
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '৳${debt.remainingInTaka.toStringAsFixed(0)}',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: isBorrowed ? AppColors.danger : AppColors.success),
                        ),
                        Text(
                          'পরিশোধিত: ৳${debt.repaidInTaka.toStringAsFixed(0)}',
                          style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
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
            MaterialPageRoute(builder: (context) => const AddEditDebtScreen()),
          );
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('হিসাব যোগ করুন', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}
