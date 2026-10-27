import 'package:cloud_firestore/cloud_firestore.dart';

class PersonalAccountModel {
  final String id;
  final String name;
  final String type; // 'cash', 'bank', 'mfs_bkash', 'mfs_nagad', 'mfs_rocket', 'savings', 'other'
  final int openingBalancePaisa;
  final int currentBalancePaisa;
  final String currency; // 'BDT'
  final String? accountNumber;
  final String colorHex;
  final String iconName;
  final DateTime createdAt;
  final bool isArchived;

  PersonalAccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.openingBalancePaisa,
    required this.currentBalancePaisa,
    this.currency = 'BDT',
    this.accountNumber,
    required this.colorHex,
    required this.iconName,
    required this.createdAt,
    this.isArchived = false,
  });

  double get currentBalanceInTaka => currentBalancePaisa / 100;
  double get openingBalanceInTaka => openingBalancePaisa / 100;

  factory PersonalAccountModel.fromMap(Map<String, dynamic> data, String documentId) {
    return PersonalAccountModel(
      id: documentId,
      name: data['name'] ?? '',
      type: data['type'] ?? 'cash',
      openingBalancePaisa: data['openingBalancePaisa'] ?? 0,
      currentBalancePaisa: data['currentBalancePaisa'] ?? 0,
      currency: data['currency'] ?? 'BDT',
      accountNumber: data['accountNumber'],
      colorHex: data['colorHex'] ?? '0xFF1E3A8A',
      iconName: data['iconName'] ?? 'account_balance_wallet',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isArchived: data['isArchived'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type,
      'openingBalancePaisa': openingBalancePaisa,
      'currentBalancePaisa': currentBalancePaisa,
      'currency': currency,
      'accountNumber': accountNumber,
      'colorHex': colorHex,
      'iconName': iconName,
      'createdAt': Timestamp.fromDate(createdAt),
      'isArchived': isArchived,
    };
  }
}
