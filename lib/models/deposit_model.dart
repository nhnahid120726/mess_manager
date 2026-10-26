import 'package:cloud_firestore/cloud_firestore.dart';

class DepositModel {
  final String id;
  final String monthId; // YYYY-MM
  final String memberEmail;
  final int amountInPaisa; // 1 Taka = 100 Paisa
  final String paymentMethod; // bKash, Cash, Bank
  final String status; // 'pending' or 'confirmed'
  final String confirmedByAdminEmail;
  final DateTime createdAt;

  DepositModel({
    required this.id,
    required this.monthId,
    required this.memberEmail,
    required this.amountInPaisa,
    required this.paymentMethod,
    required this.status,
    required this.confirmedByAdminEmail,
    required this.createdAt,
  });

  double get amountInTaka => amountInPaisa / 100;

  factory DepositModel.fromMap(Map<String, dynamic> data, String documentId) {
    return DepositModel(
      id: documentId,
      monthId: data['monthId'] ?? '',
      memberEmail: data['memberEmail'] ?? '',
      amountInPaisa: data['amountInPaisa'] ?? 0,
      paymentMethod: data['paymentMethod'] ?? 'Cash',
      status: data['status'] ?? 'pending',
      confirmedByAdminEmail: data['confirmedByAdminEmail'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'monthId': monthId,
      'memberEmail': memberEmail,
      'amountInPaisa': amountInPaisa,
      'paymentMethod': paymentMethod,
      'status': status,
      'confirmedByAdminEmail': confirmedByAdminEmail,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
