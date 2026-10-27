import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalTransactionModel {
  final String id;
  final String uid;
  final String type; // 'income', 'expense', 'transfer', 'refund', 'debt_received', 'debt_repayment', 'savings_contribution', 'savings_withdrawal', 'adjustment'
  final int amountPaisa;
  final String currency; // 'BDT'
  final String sourceAccountId;
  final String? destinationAccountId;
  final String categoryId;
  final String categoryName;
  final String description;
  final String? notes;
  final String? receiptUrl;
  final DateTime transactionDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String status; // 'posted', 'pending', 'cancelled'

  PersonalTransactionModel({
    required this.id,
    required this.uid,
    required this.type,
    required this.amountPaisa,
    this.currency = 'BDT',
    required this.sourceAccountId,
    this.destinationAccountId,
    required this.categoryId,
    required this.categoryName,
    required this.description,
    this.notes,
    this.receiptUrl,
    required this.transactionDate,
    required this.createdAt,
    required this.updatedAt,
    this.status = 'posted',
  });

  double get amountInTaka => amountPaisa / 100;

  factory PersonalTransactionModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PersonalTransactionModel(
      id: documentId,
      uid: data['uid'] ?? '',
      type: data['type'] ?? 'expense',
      amountPaisa: data['amountPaisa'] ?? 0,
      currency: data['currency'] ?? 'BDT',
      sourceAccountId: data['sourceAccountId'] ?? '',
      destinationAccountId: data['destinationAccountId'],
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? 'অন্যান্য',
      description: data['description'] ?? 'লেনদেন',
      notes: data['notes'],
      receiptUrl: data['receiptUrl'],
      transactionDate: (data['transactionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: data['status'] ?? 'posted',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'type': type,
      'amountPaisa': amountPaisa,
      'currency': currency,
      'sourceAccountId': sourceAccountId,
      'destinationAccountId': destinationAccountId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'description': description,
      'notes': notes,
      'receiptUrl': receiptUrl,
      'transactionDate': Timestamp.fromDate(transactionDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'status': status,
    };
  }
}
