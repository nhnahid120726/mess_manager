import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/financial_service.dart';
import '../services/auth_service.dart';

// ============================================================
// ডিপোজিট যোগ করার পেজ
// UI আধুনিক করা হয়েছে। Firebase ও FinancialService-এর
// বিদ্যমান ডেটা ফিল্ড এবং মেথড অপরিবর্তিত রাখা হয়েছে।
// ============================================================

class AddDepositScreen extends StatefulWidget {
  final bool isAdmin;

  const AddDepositScreen({super.key, required this.isAdmin});

  @override
  State<AddDepositScreen> createState() => _AddDepositScreenState();
}

class _AddDepositScreenState extends State<AddDepositScreen> {
  // বিদ্যমান সার্ভিস
  final FinancialService _financialService = FinancialService();
  final AuthService _authService = AuthService();

  // ফর্ম ও ইনপুট কন্ট্রোলার
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();

  // ডিপোজিটের তথ্য
  String _selectedMember = '';
  String _paymentMethod = 'Cash';

  bool _isLoading = false;
  bool _isFetchingMembers = true;

  List<String> _memberEmails = [];

  // UI-এর জন্য নির্ধারিত রং
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
  // Firebase থেকে সদস্যদের তথ্য লোড করা
  // Admin সব সদস্য নির্বাচন করতে পারবেন।
  // সাধারণ সদস্য শুধু নিজের ডিপোজিট জমা দিতে পারবেন।
  // ==========================================================
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
            // আগের নিয়ম অনুযায়ী সাধারণ সদস্যের জন্য নিজের ইমেইল
            _selectedMember = currentEmail ?? _memberEmails.first;

            // সাধারণ সদস্যের তালিকা নিজের মধ্যেই সীমাবদ্ধ
            _memberEmails = [_selectedMember];
          } else {
            // অ্যাডমিনের জন্য সব সদস্য নির্বাচনযোগ্য
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
  // সব ইনপুট ফিল্ডের একই ডিজাইন
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
  // সাদা কার্ডের ডিজাইন
  // ==========================================================
  Widget _sectionCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
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
  // সেকশনের আইকন ও শিরোনাম
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
  // অ্যাডমিন ও সাধারণ সদস্যের জন্য আলাদা তথ্য ব্যানার
  // ==========================================================
  Widget _buildStatusBanner() {
    final Color statusColor = widget.isAdmin
        ? const Color(0xFF15803D)
        : const Color(0xFFC77713);

    final Color statusBackground = widget.isAdmin
        ? const Color(0xFFEAF8EF)
        : const Color(0xFFFFF6E8);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: statusBackground,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: statusColor.withValues(alpha: 0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              widget.isAdmin
                  ? Icons.admin_panel_settings_rounded
                  : Icons.hourglass_top_rounded,
              color: statusColor,
              size: 23,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.isAdmin
                      ? 'অ্যাডমিন মোড'
                      : 'ডিপোজিট অনুমোদনের অপেক্ষায়',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  widget.isAdmin
                      ? 'অ্যাডমিন হিসেবে যোগ করা ডিপোজিট স্বয়ংক্রিয়ভাবে নিশ্চিত হবে।'
                      : 'আপনার ডিপোজিটের অনুরোধ অ্যাডমিন নিশ্চিত না করা পর্যন্ত অপেক্ষমাণ থাকবে।',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    height: 1.7,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // পেমেন্ট মেথড নির্বাচন করার কার্ড
  // Cash, bKash, Nagad ও Bank আগের মতোই রাখা হয়েছে।
  // ==========================================================
  Widget _paymentOption({
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final bool selected = _paymentMethod == value;

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        setState(() => _paymentMethod = value);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(13),
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
              width: 43,
              height: 43,
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFFD8F0E9)
                    : const Color(0xFFF2F5F8),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                icon,
                color: selected ? _primary : _textMuted,
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
  // ডিপোজিট সেভ করা
  // আগের addDeposit মেথড ও সব প্যারামিটার অপরিবর্তিত।
  // ==========================================================
  Future<void> _submitDeposit() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (_memberEmails.isEmpty || !_memberEmails.contains(_selectedMember)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('সঠিক সদস্য নির্বাচন করুন।')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // ইনপুট থেকে টাকার পরিমাণ নেওয়া
      final double amount = double.parse(_amountController.text.trim());

      // ডিপোজিট যোগকারী বর্তমান ব্যবহারকারী
      final String currentUserEmail =
          _authService.currentUser?.email ?? 'Unknown';

      // বিদ্যমান সার্ভিসে আগের মতো তথ্য পাঠানো হচ্ছে
      final bool success = await _financialService.addDeposit(
        memberEmail: _selectedMember,
        amountInTaka: amount,
        paymentMethod: _paymentMethod,
        addedByEmail: currentUserEmail,
        isAdmin: widget.isAdmin,
      );

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.isAdmin
                  ? 'ডিপোজিট সফলভাবে যোগ হয়েছে!'
                  : 'ডিপোজিটের অনুরোধ অ্যাডমিনের কাছে পাঠানো হয়েছে!',
            ),
            backgroundColor: _primary,
            behavior: SnackBarBehavior.floating,
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ডিপোজিট যোগ করা যায়নি। আবার চেষ্টা করুন।'),
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
          content: Text('একটি সমস্যা হয়েছে। তথ্য যাচাই করে আবার চেষ্টা করুন।'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ==========================================================
  // পেজের মূল ডিজাইন
  // ==========================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,

      // উপরের অ্যাপ বার
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primary,
        foregroundColor: Colors.white,
        centerTitle: false,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ডিপোজিট যোগ করুন',
              style: TextStyle(fontSize: 19, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 2),
            Text(
              'মেসের জমার হিসাব পরিচালনা করুন',
              style: TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.maybePop(context),
        ),
      ),

      // সদস্যদের তথ্য লোড হওয়ার অবস্থা
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

                            const SizedBox(height: 20),

                            // অ্যাডমিন বা সাধারণ সদস্যের স্ট্যাটাস
                            _buildStatusBanner(),

                            const SizedBox(height: 20),

                            // ১. সদস্য নির্বাচন
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
                                    value:
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
                                    onChanged: widget.isAdmin
                                        ? (value) {
                                            if (value == null) return;

                                            setState(() {
                                              _selectedMember = value;
                                            });
                                          }
                                        : null,
                                  ),

                                  if (!widget.isAdmin) ...[
                                    const SizedBox(height: 12),
                                    const Row(
                                      children: [
                                        Icon(
                                          Icons.lock_outline_rounded,
                                          size: 15,
                                          color: _textMuted,
                                        ),
                                        SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            'সাধারণ সদস্য হিসেবে এই নির্বাচন পরিবর্তন করা যাবে না।',
                                            style: TextStyle(
                                              color: _textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),

                            // ২. ডিপোজিটের পরিমাণ
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

                                  const SizedBox(height: 12),

                                  // ছোট সহায়ক তথ্য
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF0F9F7),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(
                                          Icons.info_outline_rounded,
                                          color: _primary,
                                          size: 18,
                                        ),
                                        SizedBox(width: 9),
                                        Expanded(
                                          child: Text(
                                            'টাকার পরিমাণ সঠিকভাবে লিখুন।',
                                            style: TextStyle(
                                              color: _primaryDark,
                                              fontSize: 12,
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

                            // ৩. পেমেন্ট মেথড
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

                    // নিচে স্থির Submit বাটন
                    _buildBottomButton(),
                  ],
                ),
              ),
            ),
    );
  }

  // ==========================================================
  // উপরের গ্রেডিয়েন্ট ব্যানার
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
                  'ডিপোজিট ম্যানেজমেন্ট',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
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
                        'নিরাপদ ও গোছানো হিসাব',
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
              Icons.savings_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // কোনো সদস্য পাওয়া না গেলে দেখানো UI
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
              'Firebase-এর members কালেকশন পরীক্ষা করুন।',
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
  // নিচের স্থির Submit বাটন
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
            onPressed: _isLoading ? null : _submitDeposit,
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
                        'ডিপোজিট জমা হচ্ছে...',
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
                        widget.isAdmin
                            ? 'ডিপোজিট নিশ্চিত করে যোগ করুন'
                            : 'ডিপোজিটের অনুরোধ পাঠান',
                        style: const TextStyle(
                          fontSize: 15,
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

  // পেজ বন্ধ হলে ইনপুট কন্ট্রোলার পরিষ্কার করা
  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }
}
