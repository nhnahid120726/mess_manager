import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/personal_account_model.dart';
import '../../services/personal_finance_service.dart';

class AddEditAccountScreen extends StatefulWidget {
  final PersonalAccountModel? account;

  const AddEditAccountScreen({super.key, this.account});

  @override
  State<AddEditAccountScreen> createState() => _AddEditAccountScreenState();
}

class _AddEditAccountScreenState extends State<AddEditAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _balanceController = TextEditingController();
  final _accNumberController = TextEditingController();
  final PersonalFinanceService _financeService = PersonalFinanceService();

  String _selectedType = 'cash';
  bool _isLoading = false;

  final Map<String, String> _typeNames = {
    'cash': 'ক্যাশ ওয়ালেট (Cash)',
    'bank': 'ব্যাংক অ্যাকাউন্ট (Bank)',
    'mfs_bkash': 'বিকাশ (bKash)',
    'mfs_nagad': 'নগদ (Nagad)',
    'mfs_rocket': 'রকেট (Rocket)',
    'savings': 'সঞ্চয়ী অ্যাকাউন্ট (Savings)',
    'other': 'অন্যান্য ওয়ালেট',
  };

  @override
  void initState() {
    super.initState();
    if (widget.account != null) {
      _nameController.text = widget.account!.name;
      _balanceController.text = widget.account!.currentBalanceInTaka.toStringAsFixed(0);
      _accNumberController.text = widget.account!.accountNumber ?? '';
      _selectedType = widget.account!.type;
    }
  }

  Future<void> _saveAccount() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    double balance = double.tryParse(_balanceController.text.trim()) ?? 0.0;
    int balancePaisa = (balance * 100).round();

    final newAcc = PersonalAccountModel(
      id: widget.account?.id ?? '',
      name: _nameController.text.trim(),
      type: _selectedType,
      openingBalancePaisa: widget.account?.openingBalancePaisa ?? balancePaisa,
      currentBalancePaisa: balancePaisa,
      accountNumber: _accNumberController.text.trim().isEmpty ? null : _accNumberController.text.trim(),
      colorHex: _getHexForType(_selectedType),
      iconName: _getIconForType(_selectedType),
      createdAt: widget.account?.createdAt ?? DateTime.now(),
    );

    bool success = await _financeService.createAccount(newAcc);

    if (mounted) {
      setState(() => _isLoading = false);
      if (success) {
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ওয়ালেট সেভ করা যায়নি')),
        );
      }
    }
  }

  String _getHexForType(String type) {
    switch (type) {
      case 'mfs_bkash': return '0xFFE11D48';
      case 'mfs_nagad': return '0xFFF97316';
      case 'mfs_rocket': return '0xFF8B5CF6';
      case 'bank': return '0xFF1E3A8A';
      case 'savings': return '0xFF10B981';
      default: return '0xFF3B82F6';
    }
  }

  String _getIconForType(String type) {
    switch (type) {
      case 'bank': return 'account_balance';
      case 'savings': return 'savings';
      case 'mfs_bkash':
      case 'mfs_nagad':
      case 'mfs_rocket': return 'smartphone';
      default: return 'account_balance_wallet';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.account == null ? 'নতুন ওয়ালেট যোগ করুন' : 'ওয়ালেট এডিট করুন', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
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
              // Account Name
              const Text('ওয়ালেট বা অ্যাকাউন্টের নাম', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  hintText: 'যেমন: বিকাশ ওয়ালেট বা ডাচ বাংলা ব্যাংক',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'ওয়ালেটের নাম লিখুন' : null,
              ),

              const SizedBox(height: 20),

              // Account Type Dropdown
              const Text('অ্যাকাউন্টের ধরন', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                ),
                items: _typeNames.entries.map((e) {
                  return DropdownMenuItem(value: e.key, child: Text(e.value));
                }).toList(),
                onChanged: (val) => setState(() => _selectedType = val ?? 'cash'),
              ),

              const SizedBox(height: 20),

              // Current Balance
              const Text('প্রাথমিক ব্যালেন্স (৳)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _balanceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '0.00',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                ),
                validator: (val) => val == null || val.isEmpty ? 'প্রাথমিক ব্যালেন্স দিন' : null,
              ),

              const SizedBox(height: 20),

              // Account Number (Optional)
              const Text('ফোন নম্বর / অ্যাকাউন্ট নম্বর (ঐচ্ছিক)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _accNumberController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  hintText: 'যেমন: 01700000000',
                  filled: true,
                  fillColor: AppColors.surface,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: AppColors.border)),
                ),
              ),

              const SizedBox(height: 35),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAccount,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ওয়ালেট সেভ করুন', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
