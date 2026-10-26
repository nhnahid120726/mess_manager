import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/financial_service.dart';
import '../services/auth_service.dart';
import '../models/expense_model.dart'; // ExpenseModel ইমপোর্ট করা হলো

// ============================================================
// বাজারের খরচ যোগ করার পেজ
// এখানে শুধু UI আধুনিক করা হয়েছে। Firebase-এর কালেকশন,
// সার্ভিস মেথড ও ডেটা ফিল্ডের নাম আগের মতোই রাখা হয়েছে।
// ============================================================

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? existingExpense;

  const AddExpenseScreen({super.key, this.existingExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  // বিদ্যমান সার্ভিসগুলো
  final FinancialService _financialService = FinancialService();
  final AuthService _authService = AuthService();

  // ফর্ম ও ইনপুট কন্ট্রোলার
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productsController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  // সদস্য, বাজারকারী ও খরচ ভাগ করার তথ্য
  String _selectedPurchaser = '';
  String _paymentSource = 'mess_fund';
  bool _isLoading = false;
  bool _isFetchingMembers = true;

  List<String> _memberEmails = [];
  List<String> _selectedConsumers = [];

  // অ্যাপের ডিজাইনের রং
  static const Color _primary = Color(0xFF0F766E);
  static const Color _primaryDark = Color(0xFF115E59);
  static const Color _background = Color(0xFFF5F7FA);
  static const Color _textDark = Color(0xFF172B3A);
  static const Color _textMuted = Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  // ==========================================================
  // Firebase থেকে সদস্যদের ইমেইল আনা
  // আগের members কালেকশন ও doc.id ব্যবহারের নিয়ম অপরিবর্তিত।
  // ==========================================================
  Future<void> _fetchMembers() async {
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('members')
          .get();

      if (!mounted) return;

      final emails = snapshot.docs.map((doc) => doc.id).toList();

      setState(() {
        _memberEmails = emails;

        if (_memberEmails.isNotEmpty) {
          final currentEmail = _authService.currentUser?.email;

          if (widget.existingExpense != null) {
            _selectedPurchaser = widget.existingExpense!.purchasedByEmail;
            _paymentSource = widget.existingExpense!.paymentSource;
            _selectedConsumers = List.from(widget.existingExpense!.sharedBetweenEmails);
            _productsController.text = widget.existingExpense!.products.join(', ');
            _amountController.text = widget.existingExpense!.totalAmountInTaka.toStringAsFixed(0);
          } else {
            _selectedPurchaser =
                currentEmail != null && _memberEmails.contains(currentEmail)
                ? currentEmail
                : _memberEmails.first;
            _selectedConsumers = List.from(_memberEmails);
          }
        }

        _isFetchingMembers = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() => _isFetchingMembers = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সদস্যদের তথ্য লোড করা যায়নি। আবার চেষ্টা করুন।'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================================
  // ইনপুট ফিল্ডের একই ডিজাইন বজায় রাখার জন্য হেল্পার
  // ==========================================================
  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _primary),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      labelStyle: const TextStyle(color: _textMuted),
      hintStyle: const TextStyle(color: Color(0xFFADB5C0), fontSize: 13),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5EAF0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE5EAF0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
    );
  }

  // ==========================================================
  // প্রতিটি সেকশনের জন্য সুন্দর কার্ড ডিজাইন
  // ==========================================================
  Widget _sectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(18),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFEDF0F4)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF203040).withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: child,
    );
  }

  // ==========================================================
  // সেকশনের শিরোনাম ও আইকন
  // ==========================================================
  Widget _sectionTitle(IconData icon, String title, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: const Color(0xFFE5F5F1),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: _primary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _textMuted,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================================
  // পণ্যের সাজেশন চিপ
  // ক্লিক করলে পণ্যের নাম ইনপুটে যুক্ত হবে
  // ==========================================================
  void _addProduct(String item) {
    final current = _productsController.text.trim();

    // একই পণ্য বারবার যোগ করা ঠেকানো
    final products = current.isEmpty
        ? <String>[]
        : current.split(',').map((e) => e.trim()).toList();

    if (products.contains(item)) return;

    setState(() {
      if (current.isEmpty) {
        _productsController.text = item;
      } else {
        _productsController.text = '$current, $item';
      }

      _productsController.selection = TextSelection.collapsed(
        offset: _productsController.text.length,
      );
    });
  }

  // ==========================================================
  // বাজারের খরচ সেভ করা
  // addMarketExpense-এর ফিল্ড ও ডেটা পাঠানোর নিয়ম আগের মতো।
  // ==========================================================
  Future<void> _submitExpense() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_memberEmails.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('কোনো সদস্য পাওয়া যায়নি।')));
      return;
    }

    if (_selectedConsumers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অন্তত একজন সদস্য নির্বাচন করুন।')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // কমা দিয়ে আলাদা করা পণ্যের নামের তালিকা
      final List<String> productsList = _productsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      // মোট টাকাকে সংখ্যায় রূপান্তর
      final double amount = double.parse(_amountController.text.trim());

      // আগের FinancialService মেথডেই তথ্য পাঠানো হচ্ছে
      bool success = false;
      if (widget.existingExpense == null) {
        success = await _financialService.addMarketExpense(
          products: productsList,
          totalAmountInTaka: amount,
          purchasedByEmail: _selectedPurchaser,
          paidByEmail: _selectedPurchaser,
          paymentSource: _paymentSource,
          sharedBetweenEmails: List<String>.from(_selectedConsumers),
        );
      } else {
        success = await _financialService.updateMarketExpense(
          expenseId: widget.existingExpense!.id,
          products: productsList,
          totalAmountInTaka: amount,
          purchasedByEmail: _selectedPurchaser,
          paidByEmail: _selectedPurchaser,
          paymentSource: _paymentSource,
          sharedBetweenEmails: List<String>.from(_selectedConsumers),
        );
      }

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('বাজারের খরচ সফলভাবে সেভ হয়েছে!'),
            backgroundColor: _primary,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'খরচ যোগ করা যায়নি। Firebase Rules ও সংযোগ পরীক্ষা করুন।',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() => _isLoading = false);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('একটি সমস্যা হয়েছে। আবার চেষ্টা করুন।'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================================
  // পেজের মূল UI
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      // উপরের আধুনিক অ্যাপ বার
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.existingExpense == null ? 'বাজারের খরচ' : 'খরচ সম্পাদনা',
              style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 2),
            Text(
              widget.existingExpense == null ? 'নতুন খরচের তথ্য যোগ করুন' : 'পুরোনো খরচ আপডেট করুন',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),

      body: _isFetchingMembers
          ? const Center(child: CircularProgressIndicator(color: _primary))
          : _memberEmails.isEmpty
          ? _buildEmptyMembers()
          : SafeArea(
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // স্ক্রলযোগ্য ফর্ম
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // উপরের পরিচিতি ব্যানার
                            _buildHeaderBanner(),

                            const SizedBox(height: 22),

                            // ১. পণ্যের নাম ও সাজেশন
                            _sectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle(
                                    Icons.shopping_basket_rounded,
                                    'বাজারের তালিকা',
                                    subtitle: 'কী কী কিনেছেন, কমা দিয়ে লিখুন',
                                  ),
                                  const SizedBox(height: 20),

                                  TextFormField(
                                    controller: _productsController,
                                    textCapitalization:
                                        TextCapitalization.sentences,
                                    decoration: _inputDecoration(
                                      label: 'পণ্যের নাম',
                                      hint: 'যেমন: চাল, ডাল, মুরগি',
                                      icon: Icons.receipt_long_rounded,
                                    ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'পণ্যের নাম লিখুন';
                                      }

                                      if (value
                                          .split(',')
                                          .every((e) => e.trim().isEmpty)) {
                                        return 'সঠিক পণ্যের নাম লিখুন';
                                      }

                                      return null;
                                    },
                                  ),

                                  const SizedBox(height: 18),

                                  const Text(
                                    'দ্রুত পণ্য যোগ করুন',
                                    style: TextStyle(
                                      color: _textDark,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 10),

                                  // সাধারণ বাজারের পণ্যের চিপ
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children:
                                        [
                                          'চাল', 'ডাল', 'সয়াবিন তেল', 'সরিষার তেল', 'পেঁয়াজ', 'রসুন', 'আদা', 
                                          'আলু', 'ডিম', 'ব্রয়লার মুরগি', 'সোনালী মুরগি', 'গরুর মাংস', 'মাছ', 
                                          'সবজি', 'কাঁচামরিচ', 'ধনেপাতা', 'লেবু', 'টমেটো', 'শসা',
                                          'লবণ', 'হলুদ', 'মরিচ গুঁড়া', 'জিরা', 'গরম মসলা',
                                          'চা পাতা', 'চিনি', 'দুধ', 'বিস্কুট', 'মুড়ি',
                                          'সাবান', 'শ্যাম্পু', 'হুইল পাউডার', 'ডিশওয়াশ', 'টিস্যু', 'মশা মারার কয়েল'
                                        ].map((item) {
                                          return ActionChip(
                                            label: Text(
                                              item,
                                              style: const TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            backgroundColor: const Color(
                                              0xFFF0F9F7,
                                            ),
                                            side: const BorderSide(
                                              color: Color(0xFFD5EBE5),
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            onPressed: () => _addProduct(item),
                                          );
                                        }).toList(),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ২. মোট খরচের পরিমাণ
                            _sectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle(
                                    Icons.account_balance_wallet_rounded,
                                    'মোট খরচ',
                                    subtitle:
                                        'বাজারের জন্য মোট কত টাকা খরচ হয়েছে',
                                  ),

                                  const SizedBox(height: 20),

                                  TextFormField(
                                    controller: _amountController,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d{0,2}'),
                                      ),
                                    ],
                                    decoration:
                                        _inputDecoration(
                                          label: 'টাকার পরিমাণ',
                                          hint: 'যেমন: 1250.00',
                                          icon: Icons.payments_rounded,
                                        ).copyWith(
                                          prefixText: '৳ ',
                                          prefixStyle: const TextStyle(
                                            color: _primary,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                    validator: (value) {
                                      if (value == null ||
                                          value.trim().isEmpty) {
                                        return 'টাকার পরিমাণ লিখুন';
                                      }

                                      final amount = double.tryParse(
                                        value.trim(),
                                      );

                                      if (amount == null ||
                                          !amount.isFinite ||
                                          amount <= 0) {
                                        return 'সঠিক টাকার পরিমাণ লিখুন';
                                      }

                                      return null;
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ৩. কে বাজার করেছেন
                            _sectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle(
                                    Icons.person_pin_circle_rounded,
                                    'বাজার করেছেন কে?',
                                    subtitle: 'যে সদস্য বাজারে গিয়েছেন তাকে নির্বাচন করুন',
                                  ),

                                  const SizedBox(height: 20),

                                  DropdownButtonFormField<String>(
                                    value:
                                        _memberEmails.contains(
                                          _selectedPurchaser,
                                        )
                                        ? _selectedPurchaser
                                        : null,
                                    isExpanded: true,
                                    decoration: _inputDecoration(
                                      label: 'সদস্য নির্বাচন করুন',
                                      hint: 'বাজারকারীর নাম',
                                      icon: Icons.person_rounded,
                                    ),
                                    items: _memberEmails.map((email) {
                                      return DropdownMenuItem<String>(
                                        value: email,
                                        child: Text(
                                          email.split('@')[0],
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: _textDark,
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                    validator: (value) {
                                      if (value == null ||
                                          !_memberEmails.contains(value)) {
                                        return 'একজন সদস্য নির্বাচন করুন';
                                      }
                                      return null;
                                    },
                                    onChanged: (value) {
                                      if (value == null) return;
                                      setState(() {
                                        _selectedPurchaser = value;
                                      });
                                    },
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ৪. টাকা কোন উৎস থেকে দেওয়া হয়েছে
                            _sectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle(
                                    Icons.account_balance_rounded,
                                    'টাকা দেওয়া হয়েছে কোথা থেকে?',
                                    subtitle: 'খরচের টাকার উৎস নির্বাচন করুন',
                                  ),

                                  const SizedBox(height: 16),

                                  _paymentOption(
                                    value: 'mess_fund',
                                    title: 'মেস ফান্ড',
                                    subtitle: 'মেসের জমা টাকা থেকে পরিশোধ',
                                    icon: Icons.savings_rounded,
                                  ),

                                  const SizedBox(height: 10),

                                  _paymentOption(
                                    value: 'personal',
                                    title: 'ব্যক্তিগত টাকা',
                                    subtitle: 'নিজের টাকা দিয়ে বাজার করা হয়েছে',
                                    icon: Icons.account_balance_wallet,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ৫. কারা এই বাজারের খাবার খাবেন
                            _sectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle(
                                    Icons.groups_rounded,
                                    'খরচ ভাগ করবেন কারা?',
                                    subtitle: 'যেসব সদস্যের মধ্যে এই খরচ ভাগ হবে তাদের বেছে নিন',
                                  ),

                                  const SizedBox(height: 18),

                                  // সব সদস্য নির্বাচন ও বাতিল
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          '${_selectedConsumers.length} / ${_memberEmails.length} জন নির্বাচিত',
                                          style: const TextStyle(
                                            color: _primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          setState(() {
                                            if (_selectedConsumers.length ==
                                                _memberEmails.length) {
                                              _selectedConsumers = [
                                                _memberEmails.first,
                                              ];
                                            } else {
                                              _selectedConsumers = List.from(
                                                _memberEmails,
                                              );
                                            }
                                          });
                                        },
                                        child: Text(
                                          _selectedConsumers.length ==
                                                  _memberEmails.length
                                              ? 'সবাই বাদ দিন'
                                              : 'সবাই নির্বাচন',
                                          style: const TextStyle(
                                            color: _primary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 6),

                                  // নির্বাচিত সদস্যদের চিপ
                                  Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _memberEmails.map((email) {
                                      final isSelected = _selectedConsumers
                                          .contains(email);

                                      return FilterChip(
                                        avatar: Icon(
                                          isSelected
                                              ? Icons.check_circle_rounded
                                              : Icons.person_outline_rounded,
                                          size: 17,
                                          color: isSelected
                                              ? _primary
                                              : _textMuted,
                                        ),
                                        label: Text(
                                          email.split('@')[0],
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            color: isSelected
                                                ? _primaryDark
                                                : _textDark,
                                          ),
                                        ),
                                        selected: isSelected,
                                        showCheckmark: false,
                                        backgroundColor: Colors.white,
                                        selectedColor: const Color(0xFFE0F4EF),
                                        side: BorderSide(
                                          color: isSelected
                                              ? const Color(0xFF8BD1BE)
                                              : const Color(0xFFE5EAF0),
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                        ),
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedConsumers.add(email);
                                            } else if (_selectedConsumers
                                                    .length >
                                                1) {
                                              _selectedConsumers.remove(email);
                                            } else {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                        'অন্তত একজন সদস্য নির্বাচন করতে হবে।',
                                                      ),
                                                    ),
                                                  );
                                            }
                                          });
                                        },
                                      );
                                    }).toList(),
                                  ),

                                  const SizedBox(height: 14),

                                  // নির্বাচিত সদস্যদের সংখ্যা বোঝানোর বার
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(20),
                                    child: LinearProgressIndicator(
                                      value: _memberEmails.isEmpty
                                          ? 0
                                          : _selectedConsumers.length /
                                                _memberEmails.length,
                                      minHeight: 6,
                                      backgroundColor: const Color(0xFFEAF0F2),
                                      color: _primary,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ),

                    // নিচে স্থির সেভ বাটন
                    _buildBottomButton(),
                  ],
                ),
              ),
            ),
    );
  }

  // ==========================================================
  // পেজের পরিচিতি ব্যানার
  // ==========================================================
  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_primary, _primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.18),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'আজকের বাজারের হিসাব',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'পণ্যের তালিকা ও খরচের তথ্য যোগ করুন। '
                  'সব হিসাব থাকবে এক জায়গায়।',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user_rounded,
                        color: Colors.white,
                        size: 15,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'সহজ ও গোছানো হিসাব',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Icon(
              Icons.shopping_cart_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // টাকা দেওয়ার উৎস নির্বাচন করার কার্ড
  // ==========================================================
  Widget _paymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool selected = _paymentSource == value;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() => _paymentSource = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF0F9F7) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? const Color(0xFF83CDBA) : const Color(0xFFE5EAF0),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFD8F0E9)
                    : const Color(0xFFF2F5F8),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: selected ? _primary : _textMuted,
                size: 23,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: _textDark,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: _textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected ? _primary : const Color(0xFFB5BEC8),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // সদস্য পাওয়া না গেলে দেখানো খালি অবস্থা
  // ==========================================================
  Widget _buildEmptyMembers() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFE5F5F1),
                borderRadius: BorderRadius.circular(28),
              ),
              child: const Icon(
                Icons.groups_rounded,
                color: _primary,
                size: 44,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'কোনো সদস্য পাওয়া যায়নি',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textDark,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Firebase-এর members কালেকশনে সদস্যদের তথ্য আছে কি না পরীক্ষা করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMuted, fontSize: 13, height: 1.7),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () {
                setState(() => _isFetchingMembers = true);
                _fetchMembers();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('আবার চেষ্টা করুন'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================================
  // নিচের স্থির সেভ বাটন
  // ==========================================================
  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFEDF0F4))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitExpense,
            style: ElevatedButton.styleFrom(
              backgroundColor: _primary,
              disabledBackgroundColor: const Color(0xFF8ABAB3),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(
                        width: 21,
                        height: 21,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'খরচ সেভ হচ্ছে...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded, size: 21),
                      const SizedBox(width: 10),
                      Text(
                        widget.existingExpense == null ? 'খরচ সেভ করুন' : 'খরচ আপডেট করুন',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 19),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  // ইনপুট কন্ট্রোলার পরিষ্কার করা
  @override
  void dispose() {
    _productsController.dispose();
    _amountController.dispose();
    super.dispose();
  }
}
