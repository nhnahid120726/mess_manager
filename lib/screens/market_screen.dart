import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/financial_service.dart';
import '../services/auth_service.dart';
import '../models/expense_model.dart';
import 'add_expense_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MarketScreen extends StatefulWidget {
  const MarketScreen({super.key});

  @override
  State<MarketScreen> createState() => _MarketScreenState();
}

class _MarketScreenState extends State<MarketScreen> {
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
        title: const Text('বাজারের হিসাব', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        backgroundColor: Colors.white,
        foregroundColor: dark,
        elevation: 0,
        centerTitle: false,
      ),
      body: StreamBuilder<List<ExpenseModel>>(
        stream: _financialService.getMonthlyExpenses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primary));
          }
          
          if (snapshot.hasError) {
             return Center(
               child: Padding(
                 padding: const EdgeInsets.all(16.0),
                 child: Text('Error loading data: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
               ),
             );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return _buildEmptyState();
          }

          final expenses = snapshot.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100), // extra padding for bottom nav
            itemCount: expenses.length,
            itemBuilder: (context, index) {
              final expense = expenses[index];
              final bool isMessFund = expense.paymentSource == 'mess_fund';
              
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
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: _isAdmin ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddExpenseScreen(existingExpense: expense),
                        ),
                      );
                    } : null,
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // Icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isMessFund ? const Color(0xFFEFFFF7) : const Color(0xFFF3F7FF),
                          borderRadius: BorderRadius.circular(15),
                        ),
                        child: Icon(
                          isMessFund ? Icons.shopping_basket_rounded : Icons.person_rounded, 
                          color: isMessFund ? const Color(0xFF0BB77A) : primary,
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
                              expense.products.join(', '),
                              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: dark),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${DateFormat('MMM dd, yyyy').format(expense.createdAt)} • কিনেছেন: ${expense.purchasedByEmail.split('@')[0]}',
                              style: const TextStyle(color: muted, fontSize: 12, fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 8),
                            // Shared by X people indicator
                            Row(
                              children: [
                                const Icon(Icons.people_alt_rounded, size: 12, color: muted),
                                const SizedBox(width: 4),
                                Text(
                                  expense.sharedBetweenEmails.isEmpty 
                                    ? 'সবার মাঝে ভাগ হবে' 
                                    : '${expense.sharedBetweenEmails.length} জনের মাঝে ভাগ হবে',
                                  style: const TextStyle(fontSize: 10, color: muted, fontWeight: FontWeight.bold),
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
                            '৳ ${expense.totalAmountInTaka.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: dark),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: isMessFund ? const Color(0xFFEFFFF7) : const Color(0xFFF3F7FF),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              isMessFund ? 'মেস ফান্ড' : 'নিজস্ব টাকা',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: isMessFund ? const Color(0xFF0BB77A) : primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ]
                  ),
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
        child: _isAdmin
            ? FloatingActionButton.extended(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AddExpenseScreen()),
                  );
                },
                backgroundColor: primary,
                foregroundColor: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                icon: const Icon(Icons.add_rounded),
                label: const Text('বাজার যোগ করুন', style: TextStyle(fontWeight: FontWeight.w800)),
              )
            : null,
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
            child: const Icon(Icons.shopping_basket_outlined, size: 40, color: muted),
          ),
          const SizedBox(height: 24),
          const Text(
            'কোনো বাজারের হিসাব নেই',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: dark),
          ),
          const SizedBox(height: 8),
          const Text(
            'এই মাসে এখনও কোনো বাজারের\nখরচ যোগ করা হয়নি।',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: muted, height: 1.5),
          ),
        ],
      ),
    );
  }
}
