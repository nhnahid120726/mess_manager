import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/personal_budget_model.dart';
import '../../models/personal_category_model.dart';
import '../../services/personal_finance_service.dart';

class AddEditBudgetScreen extends StatefulWidget {
  final PersonalBudgetModel? budget;

  const AddEditBudgetScreen({super.key, this.budget});

  @override
  State<AddEditBudgetScreen> createState() => _AddEditBudgetScreenState();
}

class _AddEditBudgetScreenState extends State<AddEditBudgetScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final PersonalFinanceService _financeService = PersonalFinanceService();

  late List<PersonalCategoryModel> _expenseCategories;
  String? _selectedCategoryId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _expenseCategories = PersonalCategoryModel.defaultCategories().where((c) => c.type == 'expense').toList();
    if (_expenseCategories.isNotEmpty) {
      _selectedCategoryId = _expenseCategories.first.id;
    }

    if (widget.budget != null) {
      _amountController.text = widget.budget!.budgetAmountInTaka.toStringAsFixed(0);
      _selectedCategoryId = widget.budget!.categoryId;
    }
  }

  Future<void> _saveBudget() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) return;

    setState(() => _isLoading = true);

    double amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    int amountPaisa = (amount * 100).round();

    final cat = _expenseCategories.firstWhere(
      (c) => c.id == _selectedCategoryId,
      orElse: () => _expenseCategories.first,
    );

    String currentMonthId = DateFormat('yyyy-MM').format(DateTime.now());

    final budget = PersonalBudgetModel(
      id: widget.budget?.id ?? '',
      budgetName: '${cat.name} বাজেট',
      categoryId: cat.id,
      categoryName: cat.name,
      budgetAmountPaisa: amountPaisa,
      monthId: currentMonthId,
      createdAt: widget.budget?.createdAt ?? DateTime.now(),
    );

    bool success = await _financeService.addOrUpdateBudget(budget);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('বাজেট সফলভাবে সেভ হয়েছে!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('বাজেট সেভ করা যায়নি'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.budget == null ? 'ক্যাটাগরি বাজেট সেট করুন' : 'বাজেট এডিট করুন', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Selector
              const Text('খরচের ক্যাটাগরি', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategoryId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                ),
                items: _expenseCategories.map((c) {
                  return DropdownMenuItem(value: c.id, child: Text(c.name));
                }).toList(),
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),

              const SizedBox(height: 20),

              // Monthly Budget Amount
              const Text('মাসিক বাজেট সীমা (৳)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                decoration: InputDecoration(
                  hintText: 'যেমন: 5000',
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixText: '৳ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'বাজেটের পরিমাণ দিন';
                  if ((double.tryParse(val) ?? 0) <= 0) return 'সঠিক পরিমাণ দিন';
                  return null;
                },
              ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveBudget,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('বাজেট সেভ করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
