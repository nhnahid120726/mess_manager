import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/personal_account_model.dart';
import '../../services/personal_finance_service.dart';

class TransferMoneyScreen extends StatefulWidget {
  final List<PersonalAccountModel> accounts;

  const TransferMoneyScreen({super.key, required this.accounts});

  @override
  State<TransferMoneyScreen> createState() => _TransferMoneyScreenState();
}

class _TransferMoneyScreenState extends State<TransferMoneyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final PersonalFinanceService _financeService = PersonalFinanceService();

  String? _fromAccountId;
  String? _toAccountId;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.accounts.length >= 2) {
      _fromAccountId = widget.accounts[0].id;
      _toAccountId = widget.accounts[1].id;
    } else if (widget.accounts.isNotEmpty) {
      _fromAccountId = widget.accounts[0].id;
    }
  }

  Future<void> _handleTransfer() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fromAccountId == _toAccountId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('উৎস ও গন্তব্য অ্যাকাউন্ট ভিন্ন হতে হবে')),
      );
      return;
    }

    setState(() => _isLoading = true);

    double amount = double.tryParse(_amountController.text.trim()) ?? 0.0;

    bool success = await _financeService.transferMoney(
      sourceAccountId: _fromAccountId!,
      destinationAccountId: _toAccountId!,
      amountInTaka: amount,
      description: _descController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('টাকা ট্রান্সফার সফল হয়েছে!'), backgroundColor: AppColors.success),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ট্রান্সফার করা যায়নি। পর্যাপ্ত ব্যালেন্স আছে কিনা দেখুন।'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('টাকা ট্রান্সফার', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              // From Account
              const Text('কোন অ্যাকাউন্ট থেকে', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _fromAccountId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                ),
                items: widget.accounts.map((acc) {
                  return DropdownMenuItem(
                    value: acc.id,
                    child: Text('${acc.name} (৳${acc.currentBalanceInTaka.toStringAsFixed(0)})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _fromAccountId = val),
              ),

              const SizedBox(height: 20),

              // To Account
              const Text('কোন অ্যাকাউন্টে', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _toAccountId,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                ),
                items: widget.accounts.map((acc) {
                  return DropdownMenuItem(
                    value: acc.id,
                    child: Text('${acc.name} (৳${acc.currentBalanceInTaka.toStringAsFixed(0)})'),
                  );
                }).toList(),
                onChanged: (val) => setState(() => _toAccountId = val),
              ),

              const SizedBox(height: 20),

              // Amount
              const Text('ট্রান্সফারের পরিমাণ (৳)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _amountController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0.00',
                  filled: true,
                  fillColor: AppColors.surface,
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

              // Note
              const Text('রেফারেন্স / বিবরণ (ঐচ্ছিক)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  hintText: 'যেমন: ব্যাংক থেকে ক্যাশ তোলা বা বিকাশ ক্যাশআউট',
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
                  onPressed: _isLoading ? null : _handleTransfer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ট্রান্সফার সম্পন্ন করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
