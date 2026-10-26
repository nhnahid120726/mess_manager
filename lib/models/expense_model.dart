import 'package:cloud_firestore/cloud_firestore.dart';

class ExpenseModel {
  final String id;
  final String date; // YYYY-MM-DD
  final String monthId; // YYYY-MM
  final List<String> products;
  final int totalAmountInPaisa; // To avoid floating point errors (1 Taka = 100 Paisa)
  final String purchasedByEmail; // Member who went to market
  final String paidByEmail; // Member who actually paid the money
  final String paymentSource; // 'mess_fund' or 'personal'
  final List<String> sharedBetweenEmails; // List of members sharing this expense
  final DateTime createdAt;

  ExpenseModel({
    required this.id,
    required this.date,
    required this.monthId,
    required this.products,
    required this.totalAmountInPaisa,
    required this.purchasedByEmail,
    required this.paidByEmail,
    required this.paymentSource,
    required this.sharedBetweenEmails,
    required this.createdAt,
  });

  // Calculate Taka for display
  double get totalAmountInTaka => totalAmountInPaisa / 100;

  factory ExpenseModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ExpenseModel(
      id: documentId,
      date: data['date'] ?? '',
      monthId: data['monthId'] ?? '',
      products: List<String>.from(data['products'] ?? []),
      totalAmountInPaisa: data['totalAmountInPaisa'] ?? 0,
      purchasedByEmail: data['purchasedByEmail'] ?? '',
      paidByEmail: data['paidByEmail'] ?? '',
      paymentSource: data['paymentSource'] ?? 'mess_fund',
      sharedBetweenEmails: List<String>.from(data['sharedBetweenEmails'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'monthId': monthId,
      'products': products,
      'totalAmountInPaisa': totalAmountInPaisa,
      'purchasedByEmail': purchasedByEmail,
      'paidByEmail': paidByEmail,
      'paymentSource': paymentSource,
      'sharedBetweenEmails': sharedBetweenEmails,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
