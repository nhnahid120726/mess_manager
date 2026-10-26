import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/financial_service.dart';
import '../services/auth_service.dart';
import '../models/deposit_model.dart';
import 'add_deposit_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final FinancialService _financialService = FinancialService();
  final AuthService _authService = AuthService();
  bool _isAdmin = false;
  bool _isLoadingRole = true;

  static const Color primary = Color(0xFF087F8C);
  static const Color dark = Color(0xFF173B55);
  static const Color muted = Color(0xFF7186A5);
  static const Color pageBg = Color(0xFFF3F7FF);

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  void _checkAdminStatus() async {
    final user = _authService.currentUser;
    if (user != null && user.email != null) {
      try {
        DocumentSnapshot doc = await FirebaseFirestore.instance.collection('members').doc(user.email).get();
        if (doc.exists && mounted) {
          setState(() {
            _isAdmin = doc['role'] == 'admin';
            _isLoadingRole = false;
          });
        } else {
           if (mounted) setState(() => _isLoadingRole = false);
        }
      } catch (e) {
        if (mounted) setState(() => _isLoadingRole = false);
      }
    } else {
       if (mounted) setState(() => _isLoadingRole = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('টাকা জমার হিসাব', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        backgroundColor: Colors.white,
        foregroundColor: dark,
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<List<DepositModel>>(
        stream: _financialService.getMonthlyDeposits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primary));
          }
          if (snapshot.hasError) {
             return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final deposits = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            itemCount: deposits.length,
            itemBuilder: (context, index) {
              final deposit = deposits[index];
              final bool isConfirmed = deposit.status == 'confirmed';
              
              return Container(
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isConfirmed ? const Color(0xFFEFFFF7) : const Color(0xFFFFF7E5),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          isConfirmed ? Icons.check_circle_rounded : Icons.hourglass_top_rounded, 
                          color: isConfirmed ? const Color(0xFF0BB77A) : const Color(0xFFF59E0B),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      // Details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              deposit.memberEmail.split('@')[0],
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: dark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('MMM dd, yyyy').format(deposit.createdAt)}',
                              style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            // Payment Method
                            Row(
                              children: [
                                const Icon(Icons.credit_card_rounded, size: 12, color: muted),
                                const SizedBox(width: 4),
                                Text(
                                  deposit.paymentMethod,
                                  style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.bold),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Amount
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '৳ ${deposit.amountInTaka.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: primary),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: isConfirmed ? const Color(0xFF0BB77A) : const Color(0xFFF59E0B),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              deposit.status == 'confirmed' ? 'গৃহীত' : 'অপেক্ষমাণ',
                              style: const TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Lift FAB above bottom nav bar
        child: FloatingActionButton.extended(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddDepositScreen(isAdmin: _isAdmin)),
            );
          },
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          icon: const Icon(Icons.add_rounded),
          label: const Text('টাকা জমা দিন', style: TextStyle(fontWeight: FontWeight.w800)),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            ),
            child: const Icon(Icons.account_balance_wallet_outlined, size: 40, color: muted),
          ),
          const SizedBox(height: 24),
          const Text(
            'কোনো জমা নেই',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: dark),
          ),
          const SizedBox(height: 8),
          const Text(
            'সদস্যদের জমার হিসাব\nএখানে দেখা যাবে।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
