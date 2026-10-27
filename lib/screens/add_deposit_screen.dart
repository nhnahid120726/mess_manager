import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_colors.dart';
import '../services/financial_service.dart';
import '../services/auth_service.dart';
import '../services/personal_finance_service.dart';
import '../models/personal_transaction_model.dart';

class AddDepositScreen extends StatefulWidget {
  final bool isAdmin;

  const AddDepositScreen({super.key, required this.isAdmin});

  @override
  State<AddDepositScreen> createState() => _AddDepositScreenState();
}

class _AddDepositScreenState extends State<AddDepositScreen> {
  final FinancialService _financialService = FinancialService();
  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();

  String _selectedMember = '';
  String _paymentMethod = 'Cash';

  bool _isLoading = false;
  bool _isFetchingMembers = true;

  List<String> _memberEmails = [];

  // ============================================================
  // MODERN UI COLORS
  // ============================================================

  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;
  static const Color background = AppColors.background;
  static const Color cardColor = AppColors.surface;
  static const Color textDark = AppColors.textPrimary;
  static const Color textMuted = AppColors.textSecondary;

  static const Color border = Color(0xFFE6ECF3);

  static const Color success = Color(0xFF0BB77A);
  static const Color warning = Color(0xFFF59E0B);

  @override
  void initState() {
    super.initState();
    _fetchMembers();
  }

  // ============================================================
  // FETCH MEMBERS
  // ============================================================

  Future<void> _fetchMembers() async {
    try {
      final QuerySnapshot snapshot = await FirebaseFirestore.instance
          .collection('members')
          .get();

      if (!mounted) return;

      setState(() {
        _memberEmails = snapshot.docs.map((doc) => doc.id).toList();

        if (_memberEmails.isNotEmpty) {
          final currentEmail = _authService.currentUser?.email;

          if (!widget.isAdmin) {
            _selectedMember = currentEmail ?? _memberEmails.first;

            _memberEmails = [_selectedMember];
          } else {
            _selectedMember =
                currentEmail != null && _memberEmails.contains(currentEmail)
                ? currentEmail
                : _memberEmails.first;
          }
        }

        _isFetchingMembers = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isFetchingMembers = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সদস্যদের তথ্য লোড করা যায়নি। আবার চেষ্টা করুন।'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _inputDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,

      prefixIcon: Icon(icon, color: primary, size: 21),

      filled: true,
      fillColor: const Color(0xFFFBFCFE),

      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),

      labelStyle: const TextStyle(
        color: textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),

      hintStyle: const TextStyle(color: Color(0xFFAAB5C3), fontSize: 13),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: border),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: border),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primary, width: 1.6),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(22),

        border: Border.all(color: border),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),

      child: child,
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================

  Widget _sectionTitle(IconData icon, String title, {String? subtitle}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,

          decoration: BoxDecoration(
            color: const Color(0xFFE8F7F5),
            borderRadius: BorderRadius.circular(14),
          ),

          child: Icon(icon, color: primary, size: 22),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),

              if (subtitle != null) ...[
                const SizedBox(height: 5),

                Text(
                  subtitle,
                  style: const TextStyle(
                    color: textMuted,
                    fontSize: 11.5,
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

  // ============================================================
  // STATUS BANNER
  // ============================================================

  Widget _buildStatusBanner() {
    final bool admin = widget.isAdmin;

    final Color color = admin ? success : warning;

    final Color bg = admin ? const Color(0xFFEAFBF4) : const Color(0xFFFFF7E7);

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),

      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 43,
            height: 43,

            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(13),
            ),

            child: Icon(
              admin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.hourglass_top_rounded,
              color: color,
              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  admin ? 'অ্যাডমিন মোড' : 'ডিপোজিট অনুমোদনের অপেক্ষায়',
                  style: TextStyle(
                    color: color,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(height: 5),

                Text(
                  admin
                      ? 'অ্যাডমিন হিসেবে যোগ করা ডিপোজিট স্বয়ংক্রিয়ভাবে নিশ্চিত হবে।'
                      : 'আপনার ডিপোজিটের অনুরোধ অ্যাডমিন নিশ্চিত না করা পর্যন্ত অপেক্ষমাণ থাকবে।',
                  style: TextStyle(color: color, fontSize: 11.5, height: 1.65),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT OPTION
  // ============================================================

  Widget _paymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool selected = _paymentMethod == value;

    return Material(
      color: Colors.transparent,

      child: InkWell(
        borderRadius: BorderRadius.circular(17),

        onTap: () {
          setState(() {
            _paymentMethod = value;
          });
        },

        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),

          padding: const EdgeInsets.all(13),

          decoration: BoxDecoration(
            color: selected ? const Color(0xFFEFF9F7) : Colors.white,

            borderRadius: BorderRadius.circular(17),

            border: Border.all(
              color: selected ? const Color(0xFF75C6B7) : border,

              width: selected ? 1.5 : 1,
            ),
          ),

          child: Row(
            children: [
              Container(
                width: 45,
                height: 45,

                decoration: BoxDecoration(
                  color: selected
                      ? const Color(0xFFD9F1EB)
                      : const Color(0xFFF3F6F9),

                  borderRadius: BorderRadius.circular(14),
                ),

                child: Icon(
                  icon,
                  color: selected ? primary : textMuted,
                  size: 22,
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
                        color: textDark,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      subtitle,
                      style: const TextStyle(color: textMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),

              AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),

                child: Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.radio_button_off_rounded,

                  key: ValueKey(selected),

                  color: selected ? primary : const Color(0xFFB7C0CA),

                  size: 23,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUBMIT DEPOSIT
  // ============================================================

  Future<void> _submitDeposit() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_memberEmails.isEmpty || !_memberEmails.contains(_selectedMember)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('সঠিক সদস্য নির্বাচন করুন।'),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final double amount = double.parse(_amountController.text.trim());

      final String currentUserEmail =
          _authService.currentUser?.email ?? 'Unknown';

      // BACKEND LOGIC UNCHANGED
      final bool success = await _financialService.addDeposit(
        memberEmail: _selectedMember,
        amountInTaka: amount,
        paymentMethod: _paymentMethod,
        addedByEmail: currentUserEmail,
        isAdmin: widget.isAdmin,
      );

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        // Automatically deduct from Personal Wallet
        try {
          final personalFinanceService = PersonalFinanceService();
          final accounts = await personalFinanceService.getAccounts().first;
          if (accounts.isNotEmpty) {
            final targetAccount = accounts.firstWhere(
              (acc) => acc.type.toLowerCase().contains(_paymentMethod.toLowerCase()) || acc.name.toLowerCase().contains(_paymentMethod.toLowerCase()),
              orElse: () => accounts.first,
            );

            final tx = PersonalTransactionModel(
              id: '',
              uid: _authService.currentUser?.uid ?? '',
              type: 'expense',
              amountPaisa: (amount * 100).round(),
              sourceAccountId: targetAccount.id,
              categoryId: 'cat_rent',
              categoryName: 'বাসা ভাড়া / মেস ভাড়া',
              description: 'মেসে জমা প্রদান ($_paymentMethod)',
              notes: 'Mess Deposit',
              transactionDate: DateTime.now(),
              createdAt: DateTime.now(),
              updatedAt: DateTime.now(),
            );

            await personalFinanceService.addTransaction(tx);
          }
        } catch (_) {
          // Ignored
        }

        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isAdmin
                  ? 'ডিপোজিট সফলভাবে জমা হয়েছে এবং আপনার পার্সোনাল ওয়ালেট থেকে টাকা কেটে নেওয়া হয়েছে!'
                  : 'ডিপোজিটের অনুরোধ পাঠানো হয়েছে এবং আপনার পার্সোনাল ওয়ালেট থেকে টাকা সমন্বয় করা হয়েছে!',
            ),
            backgroundColor: primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ডিপোজিট যোগ করা যায়নি। আবার চেষ্টা করুন।'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'একটি সমস্যা হয়েছে। তথ্য যাচাই করে আবার চেষ্টা করুন।',
          ),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,

        foregroundColor: textDark,

        centerTitle: false,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),

        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ডিপোজিট যোগ করুন',
              style: TextStyle(
                color: textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),

            SizedBox(height: 2),

            Text(
              'মেসের জমার হিসাব পরিচালনা করুন',
              style: TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),

          child: Container(height: 1, color: border),
        ),
      ),

      body: _isFetchingMembers
          ? _buildLoadingState()
          : _memberEmails.isEmpty
          ? _buildEmptyMembers()
          : SafeArea(
              child: Form(
                key: _formKey,

                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),

                        padding: const EdgeInsets.fromLTRB(16, 18, 16, 25),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            _buildHeaderBanner(),

                            const SizedBox(height: 16),

                            _buildStatusBanner(),

                            const SizedBox(height: 18),

                            // MEMBER
                            _sectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle(
                                    Icons.person_pin_circle_rounded,
                                    'কার ডিপোজিট?',
                                    subtitle: widget.isAdmin
                                        ? 'যে সদস্যের জমা যোগ করবেন তাকে নির্বাচন করুন'
                                        : 'আপনি নিজের ডিপোজিট জমা দিচ্ছেন',
                                  ),

                                  const SizedBox(height: 20),

                                  DropdownButtonFormField<String>(
                                    initialValue:
                                        _memberEmails.contains(_selectedMember)
                                        ? _selectedMember
                                        : null,

                                    isExpanded: true,

                                    decoration: _inputDecoration(
                                      label: 'সদস্য নির্বাচন করুন',
                                      hint: 'সদস্যের নাম',
                                      icon: Icons.person_rounded,
                                    ),

                                    items: _memberEmails.map((email) {
                                      return DropdownMenuItem<String>(
                                        value: email,

                                        child: Text(
                                          email.split('@')[0],
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: textDark,
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
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

                                    onChanged: widget.isAdmin
                                        ? (value) {
                                            if (value == null) {
                                              return;
                                            }

                                            setState(() {
                                              _selectedMember = value;
                                            });
                                          }
                                        : null,
                                  ),

                                  if (!widget.isAdmin)
                                    const Padding(
                                      padding: EdgeInsets.only(top: 12),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.lock_outline_rounded,
                                            size: 15,
                                            color: textMuted,
                                          ),
                                          SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'সাধারণ সদস্য হিসেবে এই নির্বাচন পরিবর্তন করা যাবে না।',
                                              style: TextStyle(
                                                color: textMuted,
                                                fontSize: 11,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // AMOUNT
                            _sectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle(
                                    Icons.account_balance_wallet_rounded,
                                    'জমার পরিমাণ',
                                    subtitle:
                                        'কত টাকা জমা দেওয়া হয়েছে তা লিখুন',
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
                                          hint: 'যেমন: 2000.00',
                                          icon: Icons.payments_rounded,
                                        ).copyWith(
                                          prefixText: '৳ ',

                                          prefixStyle: const TextStyle(
                                            color: primary,
                                            fontSize: 18,
                                            fontWeight: FontWeight.w900,
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

                                  const SizedBox(height: 12),

                                  Container(
                                    width: double.infinity,

                                    padding: const EdgeInsets.all(12),

                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEFF9F7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),

                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          color: primary,
                                          size: 18,
                                        ),
                                        SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                            'টাকার পরিমাণ সঠিকভাবে লিখুন।',
                                            style: TextStyle(
                                              color: primaryDark,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // PAYMENT
                            _sectionCard(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _sectionTitle(
                                    Icons.account_balance_rounded,
                                    'পেমেন্ট মেথড',
                                    subtitle:
                                        'কোন মাধ্যমে টাকা জমা দেওয়া হয়েছে?',
                                  ),

                                  const SizedBox(height: 18),

                                  _paymentOption(
                                    value: 'Cash',
                                    title: 'নগদ টাকা',
                                    subtitle: 'সরাসরি হাতে টাকা দেওয়া',
                                    icon: Icons.payments_rounded,
                                  ),

                                  const SizedBox(height: 10),

                                  _paymentOption(
                                    value: 'bKash',
                                    title: 'বিকাশ',
                                    subtitle: 'বিকাশের মাধ্যমে পেমেন্ট',
                                    icon: Icons.phone_android_rounded,
                                  ),

                                  const SizedBox(height: 10),

                                  _paymentOption(
                                    value: 'Nagad',
                                    title: 'নগদ',
                                    subtitle:
                                        'নগদ মোবাইল ফিন্যান্সিয়াল সার্ভিস',
                                    icon: Icons.account_balance_wallet_rounded,
                                  ),

                                  const SizedBox(height: 10),

                                  _paymentOption(
                                    value: 'Bank',
                                    title: 'ব্যাংক',
                                    subtitle: 'ব্যাংকের মাধ্যমে টাকা জমা',
                                    icon: Icons.account_balance_rounded,
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 18),
                          ],
                        ),
                      ),
                    ),

                    _buildBottomButton(),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // HEADER BANNER
  // ============================================================

  Widget _buildHeaderBanner() {
    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [primary, primaryDark],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius: BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 9),
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
                  'ডিপোজিট ম্যানেজমেন্ট',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const SizedBox(height: 8),

                const Text(
                  'সদস্যদের জমার তথ্য যোগ করুন। '
                  'মেসের আর্থিক হিসাব রাখুন গোছানোভাবে।',
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
                    color: Colors.white.withValues(alpha: 0.14),
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
                        'নিরাপদ ও গোছানো হিসাব',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Container(
            width: 68,
            height: 68,

            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(22),
            ),

            child: const Icon(
              Icons.savings_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING
  // ============================================================

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 70,
            height: 70,

            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,

              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),

            child: const Padding(
              padding: EdgeInsets.all(21),
              child: CircularProgressIndicator(strokeWidth: 3, color: primary),
            ),
          ),

          const SizedBox(height: 18),

          const Text(
            'সদস্যদের তথ্য লোড হচ্ছে...',
            style: TextStyle(
              color: textDark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY MEMBERS
  // ============================================================

  Widget _buildEmptyMembers() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),

        child: Column(
          mainAxisSize: MainAxisSize.min,

          children: [
            Container(
              width: 95,
              height: 95,

              decoration: BoxDecoration(
                color: const Color(0xFFEAF8F6),
                borderRadius: BorderRadius.circular(28),
              ),

              child: const Icon(Icons.groups_rounded, color: primary, size: 45),
            ),

            const SizedBox(height: 22),

            const Text(
              'কোনো সদস্য পাওয়া যায়নি',
              textAlign: TextAlign.center,

              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Firebase-এর members কালেকশন পরীক্ষা করুন।',
              textAlign: TextAlign.center,

              style: TextStyle(color: textMuted, fontSize: 13, height: 1.6),
            ),

            const SizedBox(height: 22),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isFetchingMembers = true;
                });

                _fetchMembers();
              },

              icon: const Icon(Icons.refresh_rounded),

              label: const Text('আবার চেষ্টা করুন'),

              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,

                elevation: 0,

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

  // ============================================================
  // BOTTOM SUBMIT BUTTON
  // ============================================================

  Widget _buildBottomButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),

      decoration: BoxDecoration(
        color: Colors.white,

        border: const Border(top: BorderSide(color: border)),

        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, -5),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: SizedBox(
          width: double.infinity,
          height: 56,

          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitDeposit,

            style: ElevatedButton.styleFrom(
              backgroundColor: primary,

              disabledBackgroundColor: const Color(0xFF91BDB8),

              foregroundColor: Colors.white,

              disabledForegroundColor: Colors.white70,

              elevation: 0,

              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(17),
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
                        'ডিপোজিট জমা হচ্ছে...',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded, size: 21),

                      const SizedBox(width: 9),

                      Text(
                        widget.isAdmin
                            ? 'ডিপোজিট নিশ্চিত করে যোগ করুন'
                            : 'ডিপোজিটের অনুরোধ পাঠান',

                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
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

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
