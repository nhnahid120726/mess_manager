import 'package:flutter_test/flutter_test.dart';
import 'package:mas_manegment/models/personal_account_model.dart';
import 'package:mas_manegment/models/personal_transaction_model.dart';
import 'package:mas_manegment/models/savings_goal_model.dart';
import 'package:mas_manegment/models/debt_model.dart';

void main() {
  group('Financial Calculations & Model Unit Tests', () {
    test('PersonalAccountModel converts Paisa/Poisha to Taka accurately', () {
      final account = PersonalAccountModel(
        id: 'acc_1',
        name: 'Bank Account',
        type: 'bank',
        openingBalancePaisa: 100000, // 1000.00 Taka
        currentBalancePaisa: 250050, // 2500.50 Taka
        colorHex: '0xFF1E3A8A',
        iconName: 'account_balance',
        createdAt: DateTime.now(),
      );

      expect(account.openingBalanceInTaka, equals(1000.00));
      expect(account.currentBalanceInTaka, equals(2500.50));
    });

    test('PersonalTransactionModel converts Paisa to Taka accurately', () {
      final tx = PersonalTransactionModel(
        id: 'tx_1',
        uid: 'user_1',
        type: 'expense',
        amountPaisa: 45000, // 450.00 Taka
        sourceAccountId: 'acc_1',
        categoryId: 'cat_food',
        categoryName: 'Food & Groceries',
        description: 'Dinner at Nanna Biryani',
        transactionDate: DateTime.now(),
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(tx.amountInTaka, equals(450.00));
    });

    test('SavingsGoalModel calculates progress percentage and remaining amount correctly', () {
      final goal = SavingsGoalModel(
        id: 'goal_1',
        goalName: 'New Laptop',
        targetAmountPaisa: 8000000, // 80,000 Taka
        currentSavedPaisa: 4000000, // 40,000 Taka
        targetDate: DateTime.now().add(const Duration(days: 90)),
        colorHex: '0xFF10B981',
        iconName: 'savings',
        createdAt: DateTime.now(),
      );

      expect(goal.targetAmountInTaka, equals(80000.00));
      expect(goal.currentSavedInTaka, equals(40000.00));
      expect(goal.remainingInTaka, equals(40000.00));
      expect(goal.progressPercentage, equals(0.5));
    });

    test('DebtModel calculates remaining debt correctly', () {
      final debt = DebtModel(
        id: 'debt_1',
        contactName: 'Karim',
        type: 'borrowed',
        principalAmountPaisa: 500000, // 5,000 Taka
        repaidAmountPaisa: 200000,    // 2,000 Taka
        createdAt: DateTime.now(),
      );

      expect(debt.principalInTaka, equals(5000.00));
      expect(debt.repaidInTaka, equals(2000.00));
      expect(debt.remainingInTaka, equals(3000.00));
    });
  });
}
