import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../models/personal_account_model.dart';
import '../models/personal_transaction_model.dart';
import '../models/personal_budget_model.dart';
import '../models/savings_goal_model.dart';
import '../models/debt_model.dart';

class PersonalFinanceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? get currentEmail => _auth.currentUser?.email;
  String? get currentUid => _auth.currentUser?.uid;

  // Collection Reference Helper - Uses personal_records/{userEmail}/... matching your Firestore Rules & Database!
  CollectionReference? _userSubCollection(String collectionName) {
    if (currentEmail == null) return null;
    return _firestore.collection('personal_records').doc(currentEmail!).collection(collectionName);
  }

  // ==========================================
  // 1. ACCOUNTS & WALLETS
  // ==========================================

  Stream<List<PersonalAccountModel>> getAccounts() {
    final ref = _userSubCollection('personalAccounts');
    if (ref == null) return Stream.value([]);

    return ref.snapshots().asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) {
        // Create Default Wallets if user has none
        await _createDefaultAccounts();
        final newSnap = await ref.get();
        return newSnap.docs
            .map((doc) => PersonalAccountModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .where((acc) => !acc.isArchived)
            .toList();
      }

      return snapshot.docs
          .map((doc) => PersonalAccountModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .where((acc) => !acc.isArchived)
          .toList();
    });
  }

  Future<void> _createDefaultAccounts() async {
    final ref = _userSubCollection('personalAccounts');
    if (ref == null) return;

    final defaults = [
      PersonalAccountModel(
        id: '',
        name: 'Cash Wallet',
        type: 'cash',
        openingBalancePaisa: 0,
        currentBalancePaisa: 0,
        colorHex: '0xFF10B981',
        iconName: 'account_balance_wallet',
        createdAt: DateTime.now(),
      ),
      PersonalAccountModel(
        id: '',
        name: 'Bank Account',
        type: 'bank',
        openingBalancePaisa: 0,
        currentBalancePaisa: 0,
        colorHex: '0xFF1E3A8A',
        iconName: 'account_balance',
        createdAt: DateTime.now(),
      ),
      PersonalAccountModel(
        id: '',
        name: 'bKash Wallet',
        type: 'mfs_bkash',
        openingBalancePaisa: 0,
        currentBalancePaisa: 0,
        colorHex: '0xFFE11D48',
        iconName: 'smartphone',
        createdAt: DateTime.now(),
      ),
    ];

    for (var acc in defaults) {
      final docRef = ref.doc();
      await docRef.set(acc.toMap());
    }
  }

  Future<bool> createAccount(PersonalAccountModel account) async {
    final ref = _userSubCollection('personalAccounts');
    if (ref == null) return false;

    try {
      final docRef = account.id.isEmpty ? ref.doc() : ref.doc(account.id);
      await docRef.set(account.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteAccount(String accountId) async {
    final ref = _userSubCollection('personalAccounts');
    if (ref == null) return false;

    try {
      await ref.doc(accountId).delete();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> transferMoney({
    required String sourceAccountId,
    required String destinationAccountId,
    required double amountInTaka,
    required String description,
  }) async {
    final ref = _userSubCollection('personalAccounts');
    final txRef = _userSubCollection('transactions');
    if (ref == null || txRef == null || currentUid == null) return false;

    int amountPaisa = (amountInTaka * 100).round();
    if (amountPaisa <= 0) return false;

    try {
      await _firestore.runTransaction((transaction) async {
        final sourceDoc = await transaction.get(ref.doc(sourceAccountId));
        final destDoc = await transaction.get(ref.doc(destinationAccountId));

        if (!sourceDoc.exists || !destDoc.exists) {
          throw Exception("Source or destination account not found");
        }

        int sourceBalance = sourceDoc['currentBalancePaisa'] ?? 0;
        int destBalance = destDoc['currentBalancePaisa'] ?? 0;

        transaction.update(ref.doc(sourceAccountId), {
          'currentBalancePaisa': sourceBalance - amountPaisa,
        });

        transaction.update(ref.doc(destinationAccountId), {
          'currentBalancePaisa': destBalance + amountPaisa,
        });

        final newTxDoc = txRef.doc();
        final tx = PersonalTransactionModel(
          id: newTxDoc.id,
          uid: currentUid!,
          type: 'transfer',
          amountPaisa: amountPaisa,
          sourceAccountId: sourceAccountId,
          destinationAccountId: destinationAccountId,
          categoryId: 'cat_transfer',
          categoryName: 'Transfer',
          description: description.isEmpty ? 'Account Transfer' : description,
          transactionDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );

        transaction.set(newTxDoc, tx.toMap());
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 2. TRANSACTIONS & CASH FLOW
  // ==========================================

  Stream<List<PersonalTransactionModel>> getTransactions() {
    final ref = _userSubCollection('transactions');
    if (ref == null) return Stream.value([]);

    return ref.snapshots().map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PersonalTransactionModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
      list.sort((a, b) => b.transactionDate.compareTo(a.transactionDate));
      return list;
    });
  }

  Future<bool> addTransaction(PersonalTransactionModel tx) async {
    final ref = _userSubCollection('transactions');
    final accRef = _userSubCollection('personalAccounts');
    if (ref == null || accRef == null) return false;

    try {
      String accountId = tx.sourceAccountId.isNotEmpty ? tx.sourceAccountId : 'cash_wallet';

      await _firestore.runTransaction((transaction) async {
        final accDocRef = accRef.doc(accountId);
        final accDoc = await transaction.get(accDocRef);

        int currentBalance = 0;
        if (accDoc.exists) {
          currentBalance = (accDoc.data() as Map<String, dynamic>?)?['currentBalancePaisa'] ?? 0;
        }

        int delta = 0;
        if (tx.type == 'income' || tx.type == 'refund' || tx.type == 'debt_received' || tx.type == 'savings_withdrawal') {
          delta = tx.amountPaisa;
        } else if (tx.type == 'expense' || tx.type == 'debt_repayment' || tx.type == 'savings_contribution') {
          delta = -tx.amountPaisa;
        }

        if (accDoc.exists) {
          transaction.update(accDocRef, {
            'currentBalancePaisa': currentBalance + delta,
          });
        } else {
          // Auto-create account if doc doesn't exist
          transaction.set(accDocRef, {
            'name': 'ক্যাশ ওয়ালেট',
            'type': 'cash',
            'currency': 'BDT',
            'currentBalancePaisa': delta,
            'colorHex': '0xFF10B981',
            'iconName': 'wallet',
            'createdAt': Timestamp.now(),
          });
        }

        final newDoc = ref.doc();
        final finalTx = PersonalTransactionModel(
          id: newDoc.id,
          uid: tx.uid,
          type: tx.type,
          amountPaisa: tx.amountPaisa,
          currency: tx.currency,
          sourceAccountId: accountId,
          destinationAccountId: tx.destinationAccountId,
          categoryId: tx.categoryId,
          categoryName: tx.categoryName,
          description: tx.description,
          notes: tx.notes,
          receiptUrl: tx.receiptUrl,
          transactionDate: tx.transactionDate,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          status: tx.status,
        );

        transaction.set(newDoc, finalTx.toMap());
      });

      return true;
    } catch (e) {
      // Direct fallback save if transaction fails
      try {
        final newDoc = ref.doc();
        await newDoc.set(tx.toMap());
        return true;
      } catch (err) {
        return false;
      }
    }
  }

  Future<bool> deleteTransaction(PersonalTransactionModel tx) async {
    final ref = _userSubCollection('transactions');
    final accRef = _userSubCollection('personalAccounts');
    if (ref == null || accRef == null) return false;

    try {
      await _firestore.runTransaction((transaction) async {
        final accDoc = await transaction.get(accRef.doc(tx.sourceAccountId));
        if (accDoc.exists) {
          int currentBalance = accDoc['currentBalancePaisa'] ?? 0;
          int delta = 0;

          if (tx.type == 'income' || tx.type == 'refund' || tx.type == 'debt_received' || tx.type == 'savings_withdrawal') {
            delta = -tx.amountPaisa;
          } else if (tx.type == 'expense' || tx.type == 'debt_repayment' || tx.type == 'savings_contribution') {
            delta = tx.amountPaisa;
          }

          transaction.update(accRef.doc(tx.sourceAccountId), {
            'currentBalancePaisa': currentBalance + delta,
          });
        }

        transaction.delete(ref.doc(tx.id));
      });

      return true;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 3. DASHBOARD & FINANCIAL SUMMARY
  // ==========================================

  Stream<Map<String, dynamic>> getFinancialSummary() {
    final accRef = _userSubCollection('personalAccounts');
    final txRef = _userSubCollection('transactions');
    final debtRef = _userSubCollection('debts');

    if (accRef == null || txRef == null) {
      return Stream.value({
        'totalBalance': 0.0,
        'monthlyIncome': 0.0,
        'monthlyExpenses': 0.0,
        'netCashFlow': 0.0,
        'outstandingDebt': 0.0,
      });
    }

    String currentMonthId = DateFormat('yyyy-MM').format(DateTime.now());

    return txRef.snapshots().asyncMap((txSnap) async {
      final accSnap = await accRef.get();
      QuerySnapshot? debtSnap;
      if (debtRef != null) {
        debtSnap = await debtRef.get();
      }

      int totalBalancePaisa = 0;
      for (var doc in accSnap.docs) {
        if (doc['isArchived'] != true) {
          totalBalancePaisa += (doc['currentBalancePaisa'] as num? ?? 0).toInt();
        }
      }

      int monthlyIncomePaisa = 0;
      int monthlyExpensePaisa = 0;

      for (var doc in txSnap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final DateTime txDate = (data['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now();
        final String mId = DateFormat('yyyy-MM').format(txDate);

        if (mId == currentMonthId) {
          final String type = data['type'] ?? 'expense';
          final int amount = (data['amountPaisa'] as num? ?? 0).toInt();

          if (type == 'income') {
            monthlyIncomePaisa += amount;
          } else if (type == 'expense') {
            monthlyExpensePaisa += amount;
          } else if (type == 'refund') {
            monthlyExpensePaisa -= amount; // Refund reduces expense
          }
        }
      }

      int totalDebtPaisa = 0;
      if (debtSnap != null) {
        for (var doc in debtSnap.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['type'] == 'borrowed' && data['status'] != 'fully_paid') {
            int principal = (data['principalAmountPaisa'] as num? ?? 0).toInt();
            int repaid = (data['repaidAmountPaisa'] as num? ?? 0).toInt();
            totalDebtPaisa += (principal - repaid);
          }
        }
      }

      return {
        'totalBalance': totalBalancePaisa / 100,
        'monthlyIncome': monthlyIncomePaisa / 100,
        'monthlyExpenses': monthlyExpensePaisa / 100,
        'netCashFlow': (monthlyIncomePaisa - monthlyExpensePaisa) / 100,
        'outstandingDebt': totalDebtPaisa / 100,
      };
    });
  }

  // ==========================================
  // 4. BUDGETS
  // ==========================================

  Stream<List<PersonalBudgetModel>> getBudgets() {
    final ref = _userSubCollection('personalBudgets');
    if (ref == null) return Stream.value([]);

    String currentMonthId = DateFormat('yyyy-MM').format(DateTime.now());

    return ref.where('monthId', isEqualTo: currentMonthId).snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => PersonalBudgetModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Future<bool> addOrUpdateBudget(PersonalBudgetModel budget) async {
    final ref = _userSubCollection('personalBudgets');
    if (ref == null) return false;

    try {
      final docRef = budget.id.isEmpty ? ref.doc() : ref.doc(budget.id);
      await docRef.set(budget.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 5. SAVINGS GOALS
  // ==========================================

  Stream<List<SavingsGoalModel>> getSavingsGoals() {
    final ref = _userSubCollection('savingsGoals');
    if (ref == null) return Stream.value([]);

    return ref.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => SavingsGoalModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Future<bool> addSavingsGoal(SavingsGoalModel goal) async {
    final ref = _userSubCollection('savingsGoals');
    if (ref == null) return false;

    try {
      final docRef = ref.doc();
      await docRef.set(goal.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  // ==========================================
  // 6. DEBT & LENDING
  // ==========================================

  Stream<List<DebtModel>> getDebts() {
    final ref = _userSubCollection('debts');
    if (ref == null) return Stream.value([]);

    return ref.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => DebtModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    });
  }

  Future<bool> addDebt(DebtModel debt) async {
    final ref = _userSubCollection('debts');
    if (ref == null) return false;

    try {
      final docRef = ref.doc();
      await docRef.set(debt.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }
}
