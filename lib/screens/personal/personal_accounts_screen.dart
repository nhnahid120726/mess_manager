import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/personal_account_model.dart';
import '../../services/personal_finance_service.dart';
import 'add_edit_account_screen.dart';
import 'transfer_money_screen.dart';

class PersonalAccountsScreen extends StatefulWidget {
  const PersonalAccountsScreen({super.key});

  @override
  State<PersonalAccountsScreen> createState() => _PersonalAccountsScreenState();
}

class _PersonalAccountsScreenState extends State<PersonalAccountsScreen> with AutomaticKeepAliveClientMixin<PersonalAccountsScreen> {
  final PersonalFinanceService _financeService = PersonalFinanceService();

  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.maps_home_work_rounded, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('ওয়ালেট ও অ্যাকাউন্ট', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
          ],
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: StreamBuilder<List<PersonalAccountModel>>(
        stream: _financeService.getAccounts(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          final accounts = snapshot.data ?? [];
          double totalBalance = accounts.fold(0.0, (sum, item) => sum + item.currentBalanceInTaka);

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Total Balance Across Active Wallets Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.primaryDark, AppColors.primary],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.25),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'সর্বমোট ক্যাশ জমা',
                        style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '৳ ${totalBalance.toStringAsFixed(2)}',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => const AddEditAccountScreen()),
                                );
                              },
                              icon: const Icon(Icons.add_rounded, size: 18),
                              label: const Text('ওয়ালেট যোগ'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white.withValues(alpha: 0.2),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: accounts.length < 2 ? null : () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => TransferMoneyScreen(accounts: accounts)),
                                );
                              },
                              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                              label: const Text('ট্রান্সফার'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                const Text('সক্রিয় ওয়ালেটসমূহ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 12),

                if (accounts.isEmpty)
                  const Center(child: Padding(padding: EdgeInsets.all(30), child: Text('কোনো ওয়ালেট পাওয়া যায়নি।')))
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: accounts.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final acc = accounts[index];
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
                                color: Color(int.parse(acc.colorHex)).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                _getIconData(acc.iconName),
                                color: Color(int.parse(acc.colorHex)),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    acc.name,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    acc.accountNumber ?? acc.type.toUpperCase(),
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '৳ ${acc.currentBalanceInTaka.toStringAsFixed(2)}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.textPrimary),
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary),
                                      onPressed: () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(builder: (context) => AddEditAccountScreen(account: acc)),
                                        );
                                      },
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18, color: AppColors.danger),
                                      onPressed: () async {
                                        bool? confirm = await showDialog<bool>(
                                          context: context,
                                          builder: (dialogCtx) => AlertDialog(
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                            title: const Text('ওয়ালেট মুছে ফেলবেন?', style: TextStyle(fontWeight: FontWeight.bold)),
                                            content: Text('আপনি কি নিশ্চিত যে "${acc.name}" ওয়ালেটটি মুছে ফেলতে চান?'),
                                            actions: [
                                              TextButton(
                                                onPressed: () => Navigator.pop(dialogCtx, false),
                                                child: const Text('না, রাখুন'),
                                              ),
                                              ElevatedButton(
                                                onPressed: () => Navigator.pop(dialogCtx, true),
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: AppColors.danger,
                                                  foregroundColor: Colors.white,
                                                  elevation: 0,
                                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                                ),
                                                child: const Text('হ্যাঁ, মুছুন'),
                                              ),
                                            ],
                                          ),
                                        );

                                        if (confirm == true) {
                                          bool success = await _financeService.deleteAccount(acc.id);
                                          if (context.mounted && success) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(
                                                content: Text('ওয়ালেট সফলভাবে মুছে ফেলা হয়েছে!'),
                                                backgroundColor: AppColors.success,
                                              ),
                                            );
                                          }
                                        }
                                      },
                                    ),
                                  ],
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
      ),
    );
  }

  IconData _getIconData(String name) {
    switch (name) {
      case 'account_balance': return Icons.account_balance_rounded;
      case 'savings': return Icons.savings_rounded;
      case 'smartphone': return Icons.smartphone_rounded;
      default: return Icons.account_balance_wallet_rounded;
    }
  }
}
