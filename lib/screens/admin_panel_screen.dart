import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/constants/app_colors.dart';
import '../services/financial_service.dart';
import '../services/auth_service.dart';
import '../models/deposit_model.dart';
import 'manage_meals_screen.dart';

class AdminPanelScreen extends StatefulWidget {
  const AdminPanelScreen({super.key});

  @override
  State<AdminPanelScreen> createState() => _AdminPanelScreenState();
}

class _AdminPanelScreenState extends State<AdminPanelScreen> {
  final FinancialService _financialService = FinancialService();
  final AuthService _authService = AuthService();

  static const Color _primary = AppColors.primary;
  static const Color _primaryDark = AppColors.primaryDark;
  static const Color _dark = AppColors.textPrimary;
  static const Color _muted = AppColors.textSecondary;
  static const Color _pageBg = AppColors.background;
  static const Color _border = AppColors.border;
  static const Color _success = AppColors.success;
  static const Color _danger = AppColors.danger;
  static const Color _warning = Color(0xFFF59E0B);

  final Set<String> _processingDeposits = <String>{};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: _dark,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'অ্যাডমিন প্যানেল',
              style: TextStyle(
                color: _dark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'মেসের হিসাব ও জমা পরিচালনা করুন',
              style: TextStyle(
                color: _muted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: _border),
        ),
      ),
      body: StreamBuilder<List<DepositModel>>(
        stream: _financialService.getPendingDeposits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const _LoadingState();
          }

          if (snapshot.hasError) {
            return _ErrorState(
              onRetry: () => setState(() {}),
            );
          }

          final pendingDeposits = snapshot.data ?? <DepositModel>[];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: _buildManageMealsCard(context),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF4DE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.pending_actions_rounded,
                        color: _warning,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'অপেক্ষমাণ জমা',
                            style: TextStyle(
                              color: _dark,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'সদস্যদের জমার অনুরোধ যাচাই করুন',
                            style: TextStyle(color: _muted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFE9ED),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${pendingDeposits.length}',
                        style: const TextStyle(
                          color: _danger,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (pendingDeposits.isEmpty)
                const Expanded(child: _EmptyState())
              else
                Expanded(
                  child: ListView.separated(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
                    itemCount: pendingDeposits.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 14),
                    itemBuilder: (context, index) {
                      final deposit = pendingDeposits[index];
                      return _buildDepositCard(deposit);
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildManageMealsCard(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ManageMealsScreen(),
            ),
          );
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_primary, _primaryDark],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: _primary.withValues(alpha: 0.20),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'সদস্যদের মিল হিসাব',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'মিল পরিচালনা ও হিসাব দেখতে ট্যাপ করুন',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11.5,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDepositCard(DepositModel deposit) {
    final bool isProcessing = _processingDeposits.contains(deposit.id);
    final String memberName = deposit.memberEmail.split('@').first;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _dark.withValues(alpha: 0.035),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F7F5),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  color: _primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      memberName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _dark,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      deposit.memberEmail,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  const Text(
                    'জমার পরিমাণ',
                    style: TextStyle(color: _muted, fontSize: 10.5),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '৳ ${deposit.amountInTaka.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: _primary,
                      fontSize: 19,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF7F9FC),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 17, color: _muted),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    DateFormat('dd MMM yyyy • hh:mm a').format(deposit.createdAt),
                    style: const TextStyle(
                      color: _dark,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF3DB),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    deposit.paymentMethod,
                    style: const TextStyle(
                      color: Color(0xFFB77908),
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isProcessing ? null : () => _handleReject(deposit.id),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('বাতিল করুন'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _danger,
                    disabledForegroundColor: _muted,
                    side: const BorderSide(color: Color(0xFFFFD8DF)),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: isProcessing ? null : () => _handleConfirm(deposit.id),
                  icon: isProcessing
                      ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.check_rounded, size: 18),
                  label: Text(isProcessing ? 'প্রক্রিয়াধীন' : 'কনফার্ম'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _success,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: const Color(0xFF9CCFC0),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(13),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleConfirm(String depositId) async {
    if (_processingDeposits.contains(depositId)) return;

    setState(() => _processingDeposits.add(depositId));
    try {
      final String currentEmail = _authService.currentUser?.email ?? 'admin';
      final bool success = await _financialService.confirmDeposit(
        depositId,
        currentEmail,
      );

      if (!mounted) return;
      _showSnackBar(
        success ? 'ডিপোজিট কনফার্ম করা হয়েছে!' : 'ডিপোজিট কনফার্ম করা যায়নি। আবার চেষ্টা করুন।',
        success: success,
      );
    } catch (_) {
      if (mounted) {
        _showSnackBar('একটি সমস্যা হয়েছে। আবার চেষ্টা করুন।', success: false);
      }
    } finally {
      if (mounted) setState(() => _processingDeposits.remove(depositId));
    }
  }

  Future<void> _handleReject(String depositId) async {
    final bool? confirmCancel = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        icon: Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: const Color(0xFFFFE9ED),
            borderRadius: BorderRadius.circular(17),
          ),
          child: const Icon(Icons.delete_outline_rounded, color: _danger, size: 27),
        ),
        title: const Text(
          'ডিপোজিট বাতিল করবেন?',
          textAlign: TextAlign.center,
          style: TextStyle(color: _dark, fontWeight: FontWeight.w900, fontSize: 18),
        ),
        content: const Text(
          'আপনি কি নিশ্চিত যে এই জমার রিকোয়েস্টটি বাতিল করতে চান?',
          textAlign: TextAlign.center,
          style: TextStyle(color: _muted, height: 1.5, fontSize: 13),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text(
              'না, রেখে দিন',
              style: TextStyle(color: _muted, fontWeight: FontWeight.w700),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('হ্যাঁ, বাতিল করুন'),
          ),
        ],
      ),
    );

    if (confirmCancel != true || !mounted) return;
    if (_processingDeposits.contains(depositId)) return;

    setState(() => _processingDeposits.add(depositId));
    try {
      final String currentEmail = _authService.currentUser?.email ?? 'admin';
      final bool success = await _financialService.rejectDeposit(
        depositId,
        currentEmail,
      );

      if (!mounted) return;
      _showSnackBar(
        success ? 'জমার রিকোয়েস্টটি বাতিল করা হয়েছে।' : 'রিকোয়েস্ট বাতিল করা যায়নি। আবার চেষ্টা করুন।',
        success: success,
      );
    } catch (_) {
      if (mounted) {
        _showSnackBar('একটি সমস্যা হয়েছে। আবার চেষ্টা করুন।', success: false);
      }
    } finally {
      if (mounted) setState(() => _processingDeposits.remove(depositId));
    }
  }

  void _showSnackBar(String message, {required bool success}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: success ? _success : _danger,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
          margin: const EdgeInsets.all(14),
        ),
      );
  }
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 42,
            height: 42,
            child: CircularProgressIndicator(
              color: _AdminPanelScreenState._primary,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 18),
          Text(
            'জমার তথ্য লোড হচ্ছে...',
            style: TextStyle(
              color: _AdminPanelScreenState._dark,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 94,
              height: 94,
              decoration: BoxDecoration(
                color: const Color(0xFFE4F7EF),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Icon(
                Icons.task_alt_rounded,
                color: _AdminPanelScreenState._success,
                size: 48,
              ),
            ),
            const SizedBox(height: 22),
            const Text(
              'সব ঠিকঠাক!',
              style: TextStyle(
                color: _AdminPanelScreenState._dark,
                fontSize: 21,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'এই মুহূর্তে কোনো জমার রিকোয়েস্ট অপেক্ষমাণ নেই।',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _AdminPanelScreenState._muted,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final VoidCallback onRetry;

  const _ErrorState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 82,
              height: 82,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE9ED),
                borderRadius: BorderRadius.circular(26),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: _AdminPanelScreenState._danger,
                size: 38,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'ডেটা লোড করা যায়নি',
              style: TextStyle(
                color: _AdminPanelScreenState._dark,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'ইন্টারনেট সংযোগ বা Firebase সেটিংস পরীক্ষা করে আবার চেষ্টা করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _AdminPanelScreenState._muted,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('আবার চেষ্টা করুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _AdminPanelScreenState._primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
