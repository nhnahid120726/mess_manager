import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/savings_goal_model.dart';
import '../../services/personal_finance_service.dart';

class AddEditSavingsGoalScreen extends StatefulWidget {
  final SavingsGoalModel? goal;

  const AddEditSavingsGoalScreen({super.key, this.goal});

  @override
  State<AddEditSavingsGoalScreen> createState() => _AddEditSavingsGoalScreenState();
}

class _AddEditSavingsGoalScreenState extends State<AddEditSavingsGoalScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _targetAmountController = TextEditingController();
  final _savedAmountController = TextEditingController();

  final PersonalFinanceService _financeService = PersonalFinanceService();
  DateTime _targetDate = DateTime.now().add(const Duration(days: 180));
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.goal != null) {
      _nameController.text = widget.goal!.goalName;
      _targetAmountController.text = widget.goal!.targetAmountInTaka.toStringAsFixed(0);
      _savedAmountController.text = widget.goal!.currentSavedInTaka.toStringAsFixed(0);
      _targetDate = widget.goal!.targetDate;
    }
  }

  Future<void> _saveGoal() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    double targetAmount = double.tryParse(_targetAmountController.text.trim()) ?? 0.0;
    double savedAmount = double.tryParse(_savedAmountController.text.trim()) ?? 0.0;

    final newGoal = SavingsGoalModel(
      id: widget.goal?.id ?? '',
      goalName: _nameController.text.trim(),
      targetAmountPaisa: (targetAmount * 100).round(),
      currentSavedPaisa: (savedAmount * 100).round(),
      targetDate: _targetDate,
      colorHex: '0xFF10B981',
      iconName: 'savings',
      createdAt: widget.goal?.createdAt ?? DateTime.now(),
    );

    bool success = await _financeService.addSavingsGoal(newGoal);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('সঞ্চয় লক্ষ্য সেভ হয়েছে!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('সেভ করা যায়নি'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.goal == null ? 'নতুন সঞ্চয় লক্ষ্য যোগ করুন' : 'লক্ষ্য এডিট করুন', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              // Goal Name
              const Text('সঞ্চয়ের লক্ষ্যের নাম', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'যেমন: ইমার্জেন্সি ফান্ড, ল্যাপটপ বা নতুন ফোন',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'লক্ষ্যের নাম লিখুন' : null,
              ),

              const SizedBox(height: 20),

              // Target Amount
              const Text('লক্ষ্যমাত্রার টাকা (৳)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _targetAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'যেমন: 50000',
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixText: '৳ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'লক্ষ্যের পরিমাণ দিন';
                  if ((double.tryParse(val) ?? 0) <= 0) return 'সঠিক পরিমাণ দিন';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Already Saved Amount
              const Text('ইতিমধ্যে জমাকৃত টাকা (৳)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _savedAmountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0',
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixText: '৳ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),

              const SizedBox(height: 20),

              // Target Date
              const Text('টার্গেট তারিখ', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _targetDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                  );
                  if (picked != null) {
                    setState(() => _targetDate = picked);
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
                      Text(DateFormat('dd MMM yyyy').format(_targetDate), style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                      const Icon(Icons.calendar_today_rounded, color: AppColors.accent, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 35),

              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveGoal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('সঞ্চয় লক্ষ্য সেভ করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
