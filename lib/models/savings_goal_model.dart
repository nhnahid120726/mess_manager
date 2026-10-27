import 'package:cloud_firestore/cloud_firestore.dart';

class SavingsGoalModel {
  final String id;
  final String goalName;
  final int targetAmountPaisa;
  final int currentSavedPaisa;
  final DateTime targetDate;
  final String? linkedAccountId;
  final String? description;
  final String colorHex;
  final String iconName;
  final String status; // 'active', 'paused', 'completed'
  final DateTime createdAt;

  SavingsGoalModel({
    required this.id,
    required this.goalName,
    required this.targetAmountPaisa,
    required this.currentSavedPaisa,
    required this.targetDate,
    this.linkedAccountId,
    this.description,
    required this.colorHex,
    required this.iconName,
    this.status = 'active',
    required this.createdAt,
  });

  double get targetAmountInTaka => targetAmountPaisa / 100;
  double get currentSavedInTaka => currentSavedPaisa / 100;
  double get remainingInTaka => (targetAmountPaisa - currentSavedPaisa) / 100;
  double get progressPercentage {
    if (targetAmountPaisa <= 0) return 0.0;
    final progress = currentSavedPaisa / targetAmountPaisa;
    return progress > 1.0 ? 1.0 : progress;
  }

  factory SavingsGoalModel.fromMap(Map<String, dynamic> data, String documentId) {
    return SavingsGoalModel(
      id: documentId,
      goalName: data['goalName'] ?? '',
      targetAmountPaisa: data['targetAmountPaisa'] ?? 0,
      currentSavedPaisa: data['currentSavedPaisa'] ?? 0,
      targetDate: (data['targetDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      linkedAccountId: data['linkedAccountId'],
      description: data['description'],
      colorHex: data['colorHex'] ?? '0xFF10B981',
      iconName: data['iconName'] ?? 'savings',
      status: data['status'] ?? 'active',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'goalName': goalName,
      'targetAmountPaisa': targetAmountPaisa,
      'currentSavedPaisa': currentSavedPaisa,
      'targetDate': Timestamp.fromDate(targetDate),
      'linkedAccountId': linkedAccountId,
      'description': description,
      'colorHex': colorHex,
      'iconName': iconName,
      'status': status,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
