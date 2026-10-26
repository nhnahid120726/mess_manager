import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_colors.dart';
import '../services/financial_service.dart';
import '../services/auth_service.dart';
import '../models/deposit_model.dart';
import 'add_deposit_screen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final FinancialService _financialService = FinancialService();
  final AuthService _authService = AuthService();

  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
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
      } catch (e) {
        // Ignored
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      appBar: _buildAppBar(),

      body: StreamBuilder<List<DepositModel>>(
        stream: _financialService.getMonthlyDeposits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingState();
          }

          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error);
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final deposits = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              final double horizontalPadding = constraints.maxWidth >= 700
                  ? 32
                  : 16;

              return ListView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  18,
                  horizontalPadding,
                  120,
                ),
                itemCount: deposits.length,
                itemBuilder: (context, index) {
                  return _buildDepositCard(context, deposits[index]);
                },
              );
            },
          );
        },
      ),

      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      floatingActionButton: _buildFloatingButton(),
    );
  }

  // ─────────────────────────────────────────────
  // AppBar
  // ─────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      elevation: 0,
      centerTitle: false,

      titleSpacing: 20,

      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'টাকা জমার হিসাব',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 2),

          const Text(
            'সদস্যদের মাসিক জমার তালিকা',
            style: TextStyle(
              color: AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),

      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Container(height: 1, color: AppColors.border),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Deposit Card
  // ─────────────────────────────────────────────

  Widget _buildDepositCard(BuildContext context, DepositModel deposit) {
    final bool isConfirmed = deposit.status == 'confirmed';

    final Color statusColor = isConfirmed ? AppColors.success : const Color(0xFFF59E0B);

    final Color statusBg = isConfirmed ? const Color(0xFFEAFBF4) : const Color(0xFFFFF7E6);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: AppColors.border, width: 1),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),

      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ─────────────────────────────
                // Status Icon
                // ─────────────────────────────

                Container(
                  width: 54,
                  height: 54,

                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(17),
                  ),

                  child: Icon(
                    isConfirmed
                        ? Icons.check_circle_rounded
                        : Icons.hourglass_top_rounded,
                    color: statusColor,
                    size: 27,
                  ),
                ),

                const SizedBox(width: 14),

                // ─────────────────────────────
                // Member Information
                // ─────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        deposit.memberEmail.split('@')[0],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),

                      const SizedBox(height: 5),

                      Row(
                        children: [
                          const Icon(
                            Icons.calendar_today_rounded,
                            size: 12,
                            color: AppColors.textSecondary,
                          ),

                          const SizedBox(width: 5),

                          Flexible(
                            child: Text(
                              DateFormat('MMM dd, yyyy')
                                  .format(deposit.createdAt),

                              overflow: TextOverflow.ellipsis,

                              style: const TextStyle(
                                color: AppColors.textSecondary,
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

                const SizedBox(width: 12),

                // ─────────────────────────────
                // Amount
                // ─────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '৳ ${deposit.amountInTaka.toStringAsFixed(0)}',

                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),

                    const SizedBox(height: 6),

                    _buildStatusBadge(isConfirmed, statusColor),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ─────────────────────────────
            // Divider
            // ─────────────────────────────
            Container(height: 1, color: const Color(0xFFF0F3F7)),

            const SizedBox(height: 12),

            // ─────────────────────────────
            // Payment Method
            // ─────────────────────────────
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),

                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F7FA),
                    borderRadius: BorderRadius.circular(8),
                  ),

                  child: const Icon(
                    Icons.credit_card_rounded,
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(width: 8),

                const Text(
                  'পেমেন্ট মাধ্যম',
                  style: TextStyle(
                    color: AppColors.textSecondary,
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

                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Status Badge
  // ─────────────────────────────────────────────

  Widget _buildStatusBadge(bool isConfirmed, Color statusColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),

      decoration: BoxDecoration(
        color: isConfirmed ? const Color(0xFFEAFBF4) : const Color(0xFFFFF7E6),

        borderRadius: BorderRadius.circular(8),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,

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
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Floating Action Button
  // ─────────────────────────────────────────────

  Widget _buildFloatingButton() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 80, right: 4),

      child: FloatingActionButton.extended(
        heroTag: 'add_deposit_fab',

        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddDepositScreen(isAdmin: _isAdmin),
            ),
          );
        },

        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,

        elevation: 5,

        extendedPadding: const EdgeInsets.symmetric(horizontal: 18),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(17)),

        icon: const Icon(Icons.add_rounded, size: 23),

        label: const Text(
          'টাকা জমা দিন',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Loading State
  // ─────────────────────────────────────────────

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,

            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),

            child: const Padding(
              padding: EdgeInsets.all(20),
              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'হিসাব লোড হচ্ছে...',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Error State
  // ─────────────────────────────────────────────

  Widget _buildErrorState(Object? error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(22),

          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFFFE0E0)),
          ),

          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 58,
                height: 58,

                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0F0),
                  borderRadius: BorderRadius.circular(16),
                ),

                child: const Icon(
                  Icons.error_outline_rounded,
                  color: Colors.redAccent,
                  size: 28,
                ),
              ),

              const SizedBox(height: 16),

              const Text(
                'হিসাব লোড করা যায়নি',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 6),

              Text(
                '$error',
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,

                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // Empty State
  // ─────────────────────────────────────────────

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 30),

        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,

          children: [
            Container(
              width: 105,
              height: 105,

              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,

                border: Border.all(color: AppColors.border),

                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),

              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 42,
                color: AppColors.primary,
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'কোনো জমা নেই',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),

            const SizedBox(height: 9),

            const Text(
              'সদস্যদের জমার হিসাব\nএখানে দেখা যাবে।',
              textAlign: TextAlign.center,

              style: TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 22),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),

              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),

              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.info_outline_rounded, size: 15, color: AppColors.textSecondary),

                  SizedBox(width: 7),

                  Text(
                    'নতুন জমা যোগ করলে এখানে দেখা যাবে',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
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
