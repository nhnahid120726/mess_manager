import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../models/personal_transaction_model.dart';
import '../../services/personal_finance_service.dart';
import 'add_personal_transaction_screen.dart';

class PersonalTransactionsScreen extends StatefulWidget {
  const PersonalTransactionsScreen({super.key});

  @override
  State<PersonalTransactionsScreen> createState() => _PersonalTransactionsScreenState();
}

class _PersonalTransactionsScreenState extends State<PersonalTransactionsScreen> with AutomaticKeepAliveClientMixin<PersonalTransactionsScreen> {
  final PersonalFinanceService _financeService = PersonalFinanceService();
  String _searchQuery = '';
  String _selectedFilter = 'all'; // 'all', 'income', 'expense', 'transfer'

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('লেনদেনের ইতিহাস', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<PersonalTransactionModel>>(
        stream: _financeService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          final allTxs = snapshot.data ?? [];
          final filteredTxs = allTxs.where((tx) {
            final matchesFilter = _selectedFilter == 'all' || tx.type == _selectedFilter;
            final matchesSearch = _searchQuery.isEmpty ||
                tx.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
                tx.categoryName.toLowerCase().contains(_searchQuery.toLowerCase());
            return matchesFilter && matchesSearch;
          }).toList();

          return Column(
            children: [
              // Search & Filter Header
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                color: AppColors.surface,
                child: Column(
                  children: [
                    TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'লেনদেন খুঁজুন...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _filterChip('all', 'সব (All)'),
                        const SizedBox(width: 8),
                        _filterChip('expense', 'খরচ'),
                        const SizedBox(width: 8),
                        _filterChip('income', 'আয়'),
                        const SizedBox(width: 8),
                        _filterChip('transfer', 'ট্রান্সফার'),
                      ],
                    ),
                  ],
                ),
              ),

              // Transaction List
              Expanded(
                child: filteredTxs.isEmpty
                    ? const Center(child: Text('কোনো লেনদেন পাওয়া যায়নি।'))
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: () async {
                          setState(() {});
                        },
                        child: ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                          itemCount: filteredTxs.length,
                        itemBuilder: (context, index) {
                          final tx = filteredTxs[index];
                          final isIncome = tx.type == 'income';
                          final isTransfer = tx.type == 'transfer';

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppColors.border),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.02),
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
                                    color: isTransfer
                                        ? AppColors.accent.withValues(alpha: 0.15)
                                        : isIncome
                                            ? AppColors.success.withValues(alpha: 0.15)
                                            : AppColors.danger.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Icon(
                                    isTransfer
                                        ? Icons.swap_horiz_rounded
                                        : isIncome
                                            ? Icons.arrow_downward_rounded
                                            : Icons.arrow_upward_rounded,
                                    color: isTransfer
                                        ? AppColors.accent
                                        : isIncome
                                            ? AppColors.success
                                            : AppColors.danger,
                                    size: 24,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.description,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${tx.categoryName} • ${DateFormat('MMM dd, yyyy').format(tx.transactionDate)}',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${isIncome ? '+' : isTransfer ? '' : '-'}৳${tx.amountInTaka.toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: isTransfer
                                            ? AppColors.accent
                                            : isIncome
                                                ? AppColors.success
                                                : AppColors.danger,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.textSecondary),
                                      onPressed: () async {
                                        bool confirm = await showDialog(
                                              context: context,
                                              builder: (ctx) => AlertDialog(
                                                title: const Text('লেনদেন মুছে ফেলবেন?'),
                                                content: const Text('এর ফলে আপনার ওয়ালেট ব্যালেন্স থেকে হিসাব সমন্বয় করা হবে।'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('বাতিল')),
                                                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('মুছুন')),
                                                ],
                                              ),
                                            ) ??
                                            false;

                                        if (confirm) {
                                          await _financeService.deleteTransaction(tx);
                                        }
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              ),
            ],
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddPersonalTransactionScreen()),
            );
          },
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add_rounded),
          label: const Text('লেনদেন যোগ', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _selectedFilter == value;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(color: selected ? Colors.white : AppColors.textPrimary, fontWeight: FontWeight.bold),
      onSelected: (_) => setState(() => _selectedFilter = value),
    );
  }
}
