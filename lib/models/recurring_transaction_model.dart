import 'package:cloud_firestore/cloud_firestore.dart';

class RecurringTransactionModel {
  final String id;
  final String title;
  final String type; // 'income' or 'expense'
  final int amountPaisa;
  final String categoryId;
  final String accountId;
  final String frequency; // 'daily', 'weekly', 'monthly', 'yearly'
  final DateTime nextDueDate;
  final bool isActive;
  final DateTime createdAt;

  RecurringTransactionModel({
    required this.id,
    required this.title,
    required this.type,
    required this.amountPaisa,
    required this.categoryId,
    required this.accountId,
    required this.frequency,
    required this.nextDueDate,
    this.isActive = true,
    required this.createdAt,
  });

  double get amountInTaka => amountPaisa / 100;

  factory RecurringTransactionModel.fromMap(Map<String, dynamic> data, String documentId) {
    return RecurringTransactionModel(
      id: documentId,
      title: data['title'] ?? '',
      type: data['type'] ?? 'expense',
      amountPaisa: data['amountPaisa'] ?? 0,
      categoryId: data['categoryId'] ?? '',
      accountId: data['accountId'] ?? '',
      frequency: data['frequency'] ?? 'monthly',
      nextDueDate: (data['nextDueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'type': type,
      'amountPaisa': amountPaisa,
      'categoryId': categoryId,
      'accountId': accountId,
      'frequency': frequency,
      'nextDueDate': Timestamp.fromDate(nextDueDate),
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
