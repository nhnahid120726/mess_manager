import 'package:cloud_firestore/cloud_firestore.dart';

class DebtModel {
  final String id;
  final String contactName;
  final String? contactPhone;
  final String type; // 'borrowed' (I owe) or 'lent' (They owe me)
  final int principalAmountPaisa;
  final int repaidAmountPaisa;
  final DateTime? dueDate;
  final String? notes;
  final String status; // 'outstanding', 'partially_paid', 'fully_paid'
  final DateTime createdAt;

  DebtModel({
    required this.id,
    required this.contactName,
    this.contactPhone,
    required this.type,
    required this.principalAmountPaisa,
    required this.repaidAmountPaisa,
    this.dueDate,
    this.notes,
    this.status = 'outstanding',
    required this.createdAt,
  });

  double get principalInTaka => principalAmountPaisa / 100;
  double get repaidInTaka => repaidAmountPaisa / 100;
  double get remainingInTaka => (principalAmountPaisa - repaidAmountPaisa) / 100;

  factory DebtModel.fromMap(Map<String, dynamic> data, String documentId) {
    return DebtModel(
      id: documentId,
      contactName: data['contactName'] ?? 'Unknown',
      contactPhone: data['contactPhone'],
      type: data['type'] ?? 'borrowed',
      principalAmountPaisa: data['principalAmountPaisa'] ?? 0,
      repaidAmountPaisa: data['repaidAmountPaisa'] ?? 0,
      dueDate: (data['dueDate'] as Timestamp?)?.toDate(),
      notes: data['notes'],
      status: data['status'] ?? 'outstanding',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'contactName': contactName,
      'contactPhone': contactPhone,
      'type': type,
      'principalAmountPaisa': principalAmountPaisa,
      'repaidAmountPaisa': repaidAmountPaisa,
      'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : null,
      'notes': notes,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
