import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalBudgetModel {
  final String id;
  final String budgetName;
  final String categoryId;
  final String categoryName;
  final int budgetAmountPaisa;
  final String monthId; // YYYY-MM
  final String period; // 'monthly'
  final bool rollover;
  final List<double> alertThresholds; // [0.5, 0.75, 0.9, 1.0]
  final DateTime createdAt;

  PersonalBudgetModel({
    required this.id,
    required this.budgetName,
    required this.categoryId,
    required this.categoryName,
    required this.budgetAmountPaisa,
    required this.monthId,
    this.period = 'monthly',
    this.rollover = false,
    this.alertThresholds = const [0.5, 0.75, 0.9, 1.0],
    required this.createdAt,
  });

  double get budgetAmountInTaka => budgetAmountPaisa / 100;

  factory PersonalBudgetModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PersonalBudgetModel(
      id: documentId,
      budgetName: data['budgetName'] ?? 'Category Budget',
      categoryId: data['categoryId'] ?? '',
      categoryName: data['categoryName'] ?? 'General',
      budgetAmountPaisa: data['budgetAmountPaisa'] ?? 0,
      monthId: data['monthId'] ?? '',
      period: data['period'] ?? 'monthly',
      rollover: data['rollover'] ?? false,
      alertThresholds: List<double>.from(
        (data['alertThresholds'] as List<dynamic>?)?.map((e) => (e as num).toDouble()) ?? [0.5, 0.75, 0.9, 1.0],
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'budgetName': budgetName,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'budgetAmountPaisa': budgetAmountPaisa,
      'monthId': monthId,
      'period': period,
      'rollover': rollover,
      'alertThresholds': alertThresholds,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }
}
