import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/expense_model.dart';
import '../models/deposit_model.dart'; 
import '../models/member_model.dart';
import 'package:intl/intl.dart';

class FinancialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new Market Expense
  Future<bool> addMarketExpense({
    required List<String> products,
    required double totalAmountInTaka,
    required String purchasedByEmail,
    required String paidByEmail,
    required String paymentSource, // 'mess_fund' or 'personal'
    required List<String> sharedBetweenEmails, // New Field
  }) async {
    try {
      DateTime now = DateTime.now();
      String date = DateFormat('yyyy-MM-dd').format(now);
      String monthId = DateFormat('yyyy-MM').format(now);
      
      int amountInPaisa = (totalAmountInTaka * 100).round();
      DocumentReference docRef = _firestore.collection('expenses').doc();

      ExpenseModel expense = ExpenseModel(
        id: docRef.id,
        date: date,
        monthId: monthId,
        products: products,
        totalAmountInPaisa: amountInPaisa,
        purchasedByEmail: purchasedByEmail,
        paidByEmail: paidByEmail,
        paymentSource: paymentSource,
        sharedBetweenEmails: sharedBetweenEmails,
        createdAt: now,
      );

      await docRef.set(expense.toMap());
      return true;
    } catch (e) {
      debugPrint("Error adding expense: $e");
      return false;
    }
  }

  // Update an existing Market Expense (Admin Only)
  Future<bool> updateMarketExpense({
    required String expenseId,
    required List<String> products,
    required double totalAmountInTaka,
    required String purchasedByEmail,
    required String paidByEmail,
    required String paymentSource,
    required List<String> sharedBetweenEmails,
  }) async {
    try {
      int amountInPaisa = (totalAmountInTaka * 100).round();
      
      await _firestore.collection('expenses').doc(expenseId).update({
        'products': products,
        'totalAmountInPaisa': amountInPaisa,
        'purchasedByEmail': purchasedByEmail,
        'paidByEmail': paidByEmail,
        'paymentSource': paymentSource,
        'sharedBetweenEmails': sharedBetweenEmails,
      });
      return true;
    } catch (e) {
      debugPrint("Error updating expense: $e");
      return false;
    }
  }

  // Get Stream of Expenses for current month
  Stream<List<ExpenseModel>> getMonthlyExpenses() {
    String currentMonthId = DateFormat('yyyy-MM').format(DateTime.now());
    
    return _firestore
        .collection('expenses')
        .where('monthId', isEqualTo: currentMonthId)
        // .orderBy('createdAt', descending: true) // Removed to bypass Firebase Index requirement
        .snapshots()
        .map((snapshot) {
      
      // 1. Convert Firestore documents to ExpenseModel List
      List<ExpenseModel> expenses = snapshot.docs
          .map((doc) => ExpenseModel.fromMap(doc.data(), doc.id))
          .toList();
      
      // 2. Sort the list locally in Dart (newest first)
      expenses.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return expenses;
    });
  }

  // ==========================================
  // DEPOSIT LOGIC
  // ==========================================

  // Add a new Deposit
  Future<bool> addDeposit({
    required String memberEmail,
    required double amountInTaka,
    required String paymentMethod,
    required String addedByEmail,
    required bool isAdmin,
  }) async {
    try {
      DateTime now = DateTime.now();
      String monthId = DateFormat('yyyy-MM').format(now);
      
      int amountInPaisa = (amountInTaka * 100).round();
      DocumentReference docRef = _firestore.collection('deposits').doc();

      // If an Admin adds it, it's auto-confirmed. If a member adds it, it's pending.
      String initialStatus = isAdmin ? 'confirmed' : 'pending';
      String confirmedBy = isAdmin ? addedByEmail : '';

      DepositModel deposit = DepositModel(
        id: docRef.id,
        monthId: monthId,
        memberEmail: memberEmail,
        amountInPaisa: amountInPaisa,
        paymentMethod: paymentMethod,
        status: initialStatus,
        confirmedByAdminEmail: confirmedBy,
        createdAt: now,
      );

      await docRef.set(deposit.toMap());
      return true;
    } catch (e) {
      debugPrint("Error adding deposit: $e");
      return false;
    }
  }

  // Get Stream of Deposits for current month
  Stream<List<DepositModel>> getMonthlyDeposits() {
    String currentMonthId = DateFormat('yyyy-MM').format(DateTime.now());
    
    return _firestore
        .collection('deposits')
        .where('monthId', isEqualTo: currentMonthId)
        .snapshots()
        .map((snapshot) {
      
      List<DepositModel> deposits = snapshot.docs
          .map((doc) => DepositModel.fromMap(doc.data(), doc.id))
          .where((deposit) => deposit.status != 'rejected') // 🚀 বাতিল করা জমাগুলো লিস্ট থেকে বাদ দেওয়া হলো
          .toList();
      
      // Sort locally in Dart (newest first) to bypass Firebase Index requirement
      deposits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      
      return deposits;
    });
  }

  // Get only pending deposits for Admin Panel
  Stream<List<DepositModel>> getPendingDeposits() {
    return _firestore
        .collection('deposits')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      
      List<DepositModel> deposits = snapshot.docs
          .map((doc) => DepositModel.fromMap(doc.data(), doc.id))
          .toList();
      
      deposits.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return deposits;
    });
  }

  // Admin confirms a pending deposit
  Future<bool> confirmDeposit(String depositId, String adminEmail) async {
    try {
      await _firestore.collection('deposits').doc(depositId).update({
        'status': 'confirmed',
        'confirmedByAdminEmail': adminEmail,
      });
      return true;
    } catch (e) {
      debugPrint("Error confirming deposit: $e");
      return false;
    }
  }

  // Admin rejects/cancels a pending deposit
  Future<bool> rejectDeposit(String depositId, String adminEmail) async {
    try {
      await _firestore.collection('deposits').doc(depositId).update({
        'status': 'rejected',
        'confirmedByAdminEmail': adminEmail, // Tracking who rejected it
      });
      return true;
    } catch (e) {
      debugPrint("Error rejecting deposit: $e");
      return false;
    }
  }

  // ==========================================
  // CORE FINANCIAL CALCULATION ENGINE
  // ==========================================

  // Update Meal Count
  Future<void> updateMealCount(String memberEmail, int mealCount) async {
    String monthId = DateFormat('yyyy-MM').format(DateTime.now());
    await _firestore.collection('monthly_meals').doc(monthId).set({
      memberEmail: mealCount
    }, SetOptions(merge: true));
  }

  // Get real-time Financial Summary for the dashboard
  Stream<Map<String, dynamic>> getFinancialSummary(String currentUserEmail) {
    String currentMonthId = DateFormat('yyyy-MM').format(DateTime.now());

    Stream<QuerySnapshot> expensesStream = _firestore.collection('expenses').where('monthId', isEqualTo: currentMonthId).snapshots();

    return expensesStream.asyncMap((expenseSnapshot) async {
      QuerySnapshot depositSnapshot = await _firestore.collection('deposits').where('monthId', isEqualTo: currentMonthId).get();

      List<ExpenseModel> expenses = expenseSnapshot.docs.map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      List<DepositModel> deposits = depositSnapshot.docs.map((doc) => DepositModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

      String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
      int totalExpensePaisa = 0;
      int todayExpensePaisa = 0;
      int expensesFromMessFundPaisa = 0;
      int totalConfirmedDepositsPaisa = 0;
      int myTotalDepositsPaisa = 0;
      int myPersonalAdvancesPaisa = 0;
      double myAllocatedSharePaisa = 0.0;
      double myTodayAllocatedSharePaisa = 0.0;

      for (var expense in expenses) {
        totalExpensePaisa += expense.totalAmountInPaisa;

        List<String> shared = expense.sharedBetweenEmails;
        double expenseSharePaisa = 0.0;
        if (shared.isEmpty) {
          expenseSharePaisa = expense.totalAmountInPaisa / 8;
        } else if (shared.contains(currentUserEmail)) {
          expenseSharePaisa = expense.totalAmountInPaisa / shared.length;
        }

        myAllocatedSharePaisa += expenseSharePaisa;

        if (expense.date == todayDate) {
          todayExpensePaisa += expense.totalAmountInPaisa;
          myTodayAllocatedSharePaisa += expenseSharePaisa;
        }

        if (expense.paymentSource == 'mess_fund') {
          expensesFromMessFundPaisa += expense.totalAmountInPaisa;
        } else if (expense.paymentSource == 'personal' && expense.paidByEmail == currentUserEmail) {
          myPersonalAdvancesPaisa += expense.totalAmountInPaisa;
        }
      }

      for (var deposit in deposits) {
        if (deposit.status == 'confirmed') {
          totalConfirmedDepositsPaisa += deposit.amountInPaisa;
          if (deposit.memberEmail == currentUserEmail) {
            myTotalDepositsPaisa += deposit.amountInPaisa;
          }
        }
      }

      int messCashBalancePaisa = totalConfirmedDepositsPaisa - expensesFromMessFundPaisa;
      int myNetBalancePaisa = (myTotalDepositsPaisa + myPersonalAdvancesPaisa) - myAllocatedSharePaisa.round();

      return {
        'totalExpense': totalExpensePaisa / 100,
        'messCashBalance': messCashBalancePaisa / 100,
        'myNetBalance': myNetBalancePaisa / 100,
        'myAllocatedExpense': myAllocatedSharePaisa / 100,
        'todayExpense': todayExpensePaisa / 100,
        'myTodayAllocatedExpense': myTodayAllocatedSharePaisa / 100,
      };
    });
  }

  // Get balances for ALL members
  Future<List<Map<String, dynamic>>> getAllMembersBalances() async {
    String currentMonthId = DateFormat('yyyy-MM').format(DateTime.now());

    try {
      QuerySnapshot membersSnapshot = await _firestore.collection('members').get();
      List<MemberModel> allMembers = membersSnapshot.docs
          .map((doc) => MemberModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((member) => member.role != 'wallet_only')
          .toList();

      QuerySnapshot expenseSnapshot = await _firestore.collection('expenses').where('monthId', isEqualTo: currentMonthId).get();
      QuerySnapshot depositSnapshot = await _firestore.collection('deposits').where('monthId', isEqualTo: currentMonthId).get();

      List<ExpenseModel> expenses = expenseSnapshot.docs.map((doc) => ExpenseModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();
      List<DepositModel> deposits = depositSnapshot.docs.map((doc) => DepositModel.fromMap(doc.data() as Map<String, dynamic>, doc.id)).toList();

      List<Map<String, dynamic>> memberBalances = [];

      for (var member in allMembers) {
        int myDepositsPaisa = 0;
        int myPersonalAdvancesPaisa = 0;
        double allocatedSharePaisa = 0.0;

        for (var deposit in deposits) {
          if (deposit.status == 'confirmed' && deposit.memberEmail == member.email) {
            myDepositsPaisa += deposit.amountInPaisa;
          }
        }

        for (var expense in expenses) {
          if (expense.paymentSource == 'personal' && expense.paidByEmail == member.email) {
            myPersonalAdvancesPaisa += expense.totalAmountInPaisa;
          }
          
          List<String> shared = expense.sharedBetweenEmails;
          if (shared.isEmpty) {
             allocatedSharePaisa += expense.totalAmountInPaisa / 8;
          } else if (shared.contains(member.email)) {
             allocatedSharePaisa += expense.totalAmountInPaisa / shared.length;
          }
        }

        int netBalancePaisa = (myDepositsPaisa + myPersonalAdvancesPaisa) - allocatedSharePaisa.round();

        memberBalances.add({
          'name': member.name,
          'email': member.email,
          'role': member.role,
          'netBalance': netBalancePaisa / 100,
        });
      }

      memberBalances.sort((a, b) => a['name'].compareTo(b['name']));
      return memberBalances;
    } catch (e) {
      debugPrint("Error calculating all balances: $e");
      return [];
    }
  }
}
