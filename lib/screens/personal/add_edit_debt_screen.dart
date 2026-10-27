import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_colors.dart';
import '../../models/debt_model.dart';
import '../../services/personal_finance_service.dart';

class AddEditDebtScreen extends StatefulWidget {
  final DebtModel? debt;

  const AddEditDebtScreen({super.key, this.debt});

  @override
  State<AddEditDebtScreen> createState() => _AddEditDebtScreenState();
}

class _AddEditDebtScreenState extends State<AddEditDebtScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _amountController = TextEditingController();
  final _repaidController = TextEditingController();
  final _notesController = TextEditingController();

  final PersonalFinanceService _financeService = PersonalFinanceService();
  String _type = 'borrowed'; // 'borrowed' (I owe) or 'lent' (They owe me)
  DateTime? _dueDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.debt != null) {
      _nameController.text = widget.debt!.contactName;
      _phoneController.text = widget.debt!.contactPhone ?? '';
      _amountController.text = widget.debt!.principalInTaka.toStringAsFixed(0);
      _repaidController.text = widget.debt!.repaidInTaka.toStringAsFixed(0);
      _notesController.text = widget.debt!.notes ?? '';
      _type = widget.debt!.type;
      _dueDate = widget.debt!.dueDate;
    }
  }

  Future<void> _saveDebt() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    double principal = double.tryParse(_amountController.text.trim()) ?? 0.0;
    double repaid = double.tryParse(_repaidController.text.trim()) ?? 0.0;

    int principalPaisa = (principal * 100).round();
    int repaidPaisa = (repaid * 100).round();

    String status = 'outstanding';
    if (repaidPaisa >= principalPaisa) {
      status = 'fully_paid';
    } else if (repaidPaisa > 0) {
      status = 'partially_paid';
    }

    final debt = DebtModel(
      id: widget.debt?.id ?? '',
      contactName: _nameController.text.trim(),
      contactPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
      type: _type,
      principalAmountPaisa: principalPaisa,
      repaidAmountPaisa: repaidPaisa,
      dueDate: _dueDate,
      notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      status: status,
      createdAt: widget.debt?.createdAt ?? DateTime.now(),
    );

    bool success = await _financeService.addDebt(debt);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('দেনা-পাওনার হিসাব সেভ হয়েছে!'), backgroundColor: AppColors.success),
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
        title: Text(widget.debt == null ? 'ধার দেওয়া বা নেওয়ার হিসাব যোগ' : 'হিসাব এডিট করুন', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              // Segmented Control (Borrowed vs Lent)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'borrowed'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'borrowed' ? AppColors.danger : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'আমি ধার নিয়েছি (দেনা)',
                              style: TextStyle(
                                color: _type == 'borrowed' ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _type = 'lent'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _type == 'lent' ? AppColors.success : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'আমি ধার দিয়েছি (পাওনা)',
                              style: TextStyle(
                                color: _type == 'lent' ? Colors.white : AppColors.textSecondary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
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

              // Contact Name
              const Text('ব্যক্তির নাম', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'যেমন: রহিম বা বন্ধু',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'ব্যক্তির নাম লিখুন' : null,
              ),

              const SizedBox(height: 20),

              // Principal Amount
              const Text('মূল টাকার পরিমাণ (৳)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'যেমন: 2000',
                  filled: true,
                  fillColor: AppColors.surface,
                  prefixText: '৳ ',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                ),
                validator: (val) {
                  if (val == null || val.isEmpty) return 'টাকার পরিমাণ দিন';
                  if ((double.tryParse(val) ?? 0) <= 0) return 'সঠিক পরিমাণ দিন';
                  return null;
                },
              ),

              const SizedBox(height: 20),

              // Repaid Amount
              const Text('পরিশোধিত টাকা (৳)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _repaidController,
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

              // Due Date (Optional)
              const Text('পরিশোধের শেষ তারিখ (ঐচ্ছিক)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _dueDate ?? DateTime.now().add(const Duration(days: 30)),
                    firstDate: DateTime(2020),
                    lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
                  );
                  if (picked != null) {
                    setState(() => _dueDate = picked);
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
                      Text(
                        _dueDate == null ? 'তারিখ সেট করা নেই' : DateFormat('dd MMM yyyy').format(_dueDate!),
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
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
                  onPressed: _isLoading ? null : _saveDebt,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _type == 'borrowed' ? AppColors.danger : AppColors.success,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('হিসাব সেভ করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
