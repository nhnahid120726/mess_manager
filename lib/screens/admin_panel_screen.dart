import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
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

  // Modern Colors
  static const Color primary = Color(0xFF087F8C);
  static const Color dark = Color(0xFF173B55);
  static const Color muted = Color(0xFF7186A5);
  static const Color pageBg = Color(0xFFF3F7FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('অ্যাডমিন কন্ট্রোল প্যানেল', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 20)),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFFFF4058),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<List<DepositModel>>(
        stream: _financialService.getPendingDeposits(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4058)));
          }

          if (snapshot.hasError) {
             return const Center(child: Text('ডেটা লোড করতে সমস্যা হয়েছে।', style: TextStyle(color: Colors.red)));
          }

          final pendingDeposits = snapshot.data ?? [];

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==========================================
              // 1. MANAGE MEALS BUTTON (Modernized)
              // ==========================================
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ManageMealsScreen()),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.3), blurRadius: 15, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
                              child: const Icon(Icons.restaurant_menu_rounded, color: Colors.white, size: 24),
                            ),
                            const SizedBox(width: 16),
                            const Text(
                              'সদস্যদের মিল হিসাব করুন',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                        const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),

              // ==========================================
              // 2. PENDING DEPOSITS LIST
              // ==========================================
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
                child: Row(
                  children: [
                    const Text('অপেক্ষমাণ জমার রিকোয়েস্ট', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: dark)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(color: const Color(0xFFFF4058).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text(
                        '${pendingDeposits.length}',
                        style: const TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF4058)),
                      ),
                    ),
                  ],
                ),
              ),

              if (pendingDeposits.isEmpty)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(color: const Color(0xFF0BB77A).withOpacity(0.1), shape: BoxShape.circle),
                          child: const Icon(Icons.check_circle_rounded, size: 64, color: Color(0xFF0BB77A)),
                        ),
                        const SizedBox(height: 24),
                        const Text('সব ঠিকঠাক!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: dark)),
                        const SizedBox(height: 8),
                        const Text('কোনো রিকোয়েস্ট অপেক্ষমাণ নেই।', style: TextStyle(color: muted, fontSize: 14)),
                      ],
                    ),
                  ),
                )
              else
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 30),
                    itemCount: pendingDeposits.length,
                    itemBuilder: (context, index) {
                      final deposit = pendingDeposits[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFF59E0B).withOpacity(0.3), width: 1.5),
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 15, offset: const Offset(0, 8))],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: const BoxDecoration(color: Color(0xFFFFF7E5), shape: BoxShape.circle),
                                  child: const Icon(Icons.pending_actions_rounded, color: Color(0xFFF59E0B)),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(deposit.memberEmail.split('@')[0], style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: dark)),
                                      const SizedBox(height: 4),
                                      Text(
                                        'তারিখ: ${DateFormat('dd MMM, yyyy • hh:mm a').format(deposit.createdAt)} \nমাধ্যম: ${deposit.paymentMethod}',
                                        style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                Text('৳ ${deposit.amountInTaka.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 20, color: primary)),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Action Buttons (Cancel & Confirm)
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => _handleReject(deposit.id),
                                    icon: const Icon(Icons.close_rounded, size: 18),
                                    label: const Text('বাতিল', style: TextStyle(fontWeight: FontWeight.w800)),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFFF4058),
                                      side: const BorderSide(color: Color(0xFFFFD4DC), width: 2),
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: ElevatedButton.icon(
                                    onPressed: () => _handleConfirm(deposit.id),
                                    icon: const Icon(Icons.check_rounded, size: 18),
                                    label: const Text('কনফার্ম', style: TextStyle(fontWeight: FontWeight.w800)),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF0BB77A),
                                      foregroundColor: Colors.white,
                                      elevation: 0,
                                      padding: const EdgeInsets.symmetric(vertical: 14),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    ),
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _handleConfirm(String depositId) async {
    String currentEmail = _authService.currentUser?.email ?? 'admin';
    bool success = await _financialService.confirmDeposit(depositId, currentEmail);
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('ডিপোজিট কনফার্ম করা হয়েছে!'), 
        backgroundColor: Color(0xFF0BB77A),
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _handleReject(String depositId) async {
    // Show a confirmation dialog before cancelling
    bool? confirmCancel = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('ডিপোজিট বাতিল করবেন?', style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFFFF4058))),
        content: const Text('আপনি কি নিশ্চিত যে এই জমার রিকোয়েস্টটি বাতিল করতে চান?', style: TextStyle(color: Color(0xFF7186A5))),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('না, রেখে দিন', style: TextStyle(color: Color(0xFF7186A5), fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4058),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))
            ),
            child: const Text('হ্যাঁ, বাতিল করুন', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmCancel == true) {
      String currentEmail = _authService.currentUser?.email ?? 'admin';
      bool success = await _financialService.rejectDeposit(depositId, currentEmail);
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('জমার রিকোয়েস্টটি বাতিল করা হয়েছে।'), 
          backgroundColor: Color(0xFFFF4058),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }
}
