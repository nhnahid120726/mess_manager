import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/personal_account_model.dart';
import '../../models/personal_category_model.dart';
import '../../models/personal_transaction_model.dart';
import '../../services/personal_finance_service.dart';

class AddPersonalTransactionScreen extends StatefulWidget {
  final String initialType; // 'income' or 'expense'

  const AddPersonalTransactionScreen({super.key, this.initialType = 'expense'});

  @override
  State<AddPersonalTransactionScreen> createState() => _AddPersonalTransactionScreenState();
}

class _AddPersonalTransactionScreenState extends State<AddPersonalTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _notesController = TextEditingController();

  final PersonalFinanceService _financeService = PersonalFinanceService();

  late String _type;
  String? _selectedAccountId;
  String? _selectedCategoryId;
  DateTime _selectedDate = DateTime.now();

  List<PersonalAccountModel> _accounts = [];
  List<PersonalCategoryModel> _categories = [];
  bool _isLoadingAccounts = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _type = widget.initialType;
    _categories = PersonalCategoryModel.defaultCategories().where((c) => c.type == _type).toList();
    if (_categories.isNotEmpty) {
      _selectedCategoryId = _categories.first.id;
    }
    _loadAccounts();
  }

  void _loadAccounts() {
    _financeService.getAccounts().listen((accs) {
      if (mounted) {
        setState(() {
          _accounts = accs;
          if (_accounts.isNotEmpty && _selectedAccountId == null) {
            _selectedAccountId = _accounts.first.id;
          }
          _isLoadingAccounts = false;
        });
      }
    });
  }

  void _onTypeChanged(String newType) {
    setState(() {
      _type = newType;
      _categories = PersonalCategoryModel.defaultCategories().where((c) => c.type == _type).toList();
      if (_categories.isNotEmpty) {
        _selectedCategoryId = _categories.first.id;
      }
    });
  }

  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    double amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    int amountPaisa = (amount * 100).round();

    String targetAccountId = _selectedAccountId ?? (_accounts.isNotEmpty ? _accounts.first.id : 'cash_wallet');

    final cat = _categories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => _categories.first,
    );

    final tx = PersonalTransactionModel(
      id: '',
      uid: _financeService.currentEmail ?? _financeService.currentUid ?? '',
      type: _type,
      amountPaisa: amountPaisa,
      sourceAccountId: targetAccountId,
      categoryId: cat.id,
      categoryName: cat.name,
      description: _descController.text.trim().isEmpty ? cat.name : _descController.text.trim(),
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      transactionDate: _selectedDate,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    bool success = await _financeService.addTransaction(tx);

    if (mounted) {
      setState(() => _isSaving = false);
      if (success) {
        _amountController.clear();
        _descController.clear();
        _notesController.clear();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_type == 'income' ? 'আয়' : 'খরচ'} সফলভাবে সেভ হয়েছে!'),
            backgroundColor: AppColors.success,
          ),
        );

        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('সেভ করা যায়নি। আবার চেষ্টা করুন।'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(_type == 'income' ? 'আয় যোগ করুন' : 'খরচ যোগ করুন', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: _isLoadingAccounts
          ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Income / Expense Segment Toggle
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _onTypeChanged('expense'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _type == 'expense' ? AppColors.danger : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'খরচ (Expense)',
                                    style: TextStyle(
                                      color: _type == 'expense' ? Colors.white : AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Expanded(
                            child: GestureDetector(
                              onTap: () => _onTypeChanged('income'),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                decoration: BoxDecoration(
                                  color: _type == 'income' ? AppColors.success : Colors.transparent,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    'আয় (Income)',
                                    style: TextStyle(
                                      color: _type == 'income' ? Colors.white : AppColors.textSecondary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Amount Field
                    const Text('টাকার পরিমাণ (৳)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      decoration: InputDecoration(
                        hintText: '0.00',
                        filled: true,
                        fillColor: AppColors.surface,
                        prefixText: '৳ ',
                        prefixStyle: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'টাকার পরিমাণ লিখুন';
                        if ((double.tryParse(val) ?? 0) <= 0) return 'সঠিক পরিমাণ দিন';
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Category Selector
                    const Text('ক্যাটাগরি নির্বাচন করুন', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategoryId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      items: _categories.map((c) {
                        return DropdownMenuItem(value: c.id, child: Text(c.name));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedCategoryId = val),
                    ),

                    const SizedBox(height: 20),

                    // Wallet / Account Selector
                    const Text('ওয়ালেট / অ্যাকাউন্ট', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: _selectedAccountId,
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                      items: _accounts.map((a) {
                        return DropdownMenuItem(value: a.id, child: Text('${a.name} (৳${a.currentBalanceInTaka.toStringAsFixed(0)})'));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedAccountId = val),
                    ),

                    const SizedBox(height: 20),

                    // Date Picker
                    const Text('তারিখ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: _selectedDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setState(() => _selectedDate = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(DateFormat('EEE, dd MMM yyyy').format(_selectedDate), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                            const Icon(Icons.calendar_today_rounded, color: AppColors.accent, size: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Description / Merchant
                    const Text('বিবরণ / কোথায় খরচ হয়েছে', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _descController,
                      decoration: InputDecoration(
                        hintText: 'যেমন: সুপারশপে বাজার বা ক্যাফে বিল',
                        filled: true,
                        fillColor: AppColors.surface,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                      ),
                    ),

                    const SizedBox(height: 35),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _type == 'income' ? AppColors.success : AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(color: Colors.white)
                            : Text('${_type == 'income' ? 'আয়' : 'খরচ'} সেভ করুন', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
