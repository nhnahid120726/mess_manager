import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class _AddDepositScreenState extends State<AddDepositScreen>
    with TickerProviderStateMixin {
  final FinancialService _financialService = FinancialService();
  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();

  String _selectedMember = '';
  String _paymentMethod = 'Cash';

  bool _isLoading = false;
  bool _isFetchingMembers = true;

  List<String> _memberEmails = [];

  // ── Animations ──
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  late AnimationController _contentCtrl;

  // ── Navy Palette ──
  static const Color _navyDeep = Color(0xFF0F172A);
  static const Color _navyMid = Color(0xFF1E3A8A);
  static const Color _navyLight = Color(0xFF2563EB);
  static const Color _navyAccent = Color(0xFF3B82F6);
  static const Color _pageBg = Color(0xFFF0F4F8);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);
  static const Color _inputBg = Color(0xFFF8FAFC);

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _contentCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000));

    _headerCtrl.forward();
    _pulseCtrl.repeat(reverse: true);
    _contentCtrl.forward();

    _fetchMembers();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _pulseCtrl.dispose();
    _contentCtrl.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ============================================================
  // FETCH MEMBERS (logic preserved)
  // ============================================================
  Future<void> _fetchMembers() async {
    try {
      final QuerySnapshot snapshot =
      await FirebaseFirestore.instance.collection('members').get();

      if (!mounted) return;

      final messMemberDocs = snapshot.docs.where((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return data['role'] != 'wallet_only';
      }).toList();

      messMemberDocs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>?;
        final bData = b.data() as Map<String, dynamic>?;
        final aName = (aData?['name'] ?? '').toString();
        final bName = (bData?['name'] ?? '').toString();
        final aIsNamed = aName.isNotEmpty && aName != 'Unknown' && aName != 'ব্যবহারকারী';
        final bIsNamed = bName.isNotEmpty && bName != 'Unknown' && bName != 'ব্যবহারকারী';
        if (aIsNamed && !bIsNamed) return -1;
        if (!aIsNamed && bIsNamed) return 1;
        return a.id.compareTo(b.id);
      });

      setState(() {
        _memberEmails = messMemberDocs.map((doc) => doc.id).take(8).toList();

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
          content: Text('সদস্যদের তথ্য লোড করা যায়নি। আবার চেষ্টা করুন।'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // SUBMIT DEPOSIT (logic unchanged)
  // ============================================================
  Future<void> _submitDeposit() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

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
        final currentUserEmail =
        _authService.currentUser?.email?.toLowerCase().trim();
        final isOwnDeposit =
            currentUserEmail == _selectedMember.toLowerCase().trim();
        bool walletAdjustmentSucceeded = !isOwnDeposit;

        if (isOwnDeposit) {
          try {
            final personalFinanceService = PersonalFinanceService();
            final accounts = await personalFinanceService.getAccounts().first;
            if (accounts.isNotEmpty) {
              final targetAccount = accounts.firstWhere(
                    (acc) =>
                acc.type.toLowerCase().contains(_paymentMethod.toLowerCase()) ||
                    acc.name.toLowerCase().contains(_paymentMethod.toLowerCase()),
                orElse: () => accounts.first,
              );

              final tx = PersonalTransactionModel(
                id: '',
                uid: _authService.currentUser?.uid ?? '',
                type: 'expense',
                amountPaisa: (amount * 100).round(),
                sourceAccountId: targetAccount.id,
                categoryId: 'cat_rent',
                categoryName: 'বাসা ভাড়া / মেস ভাড়া',
                description: 'মেসে জমা প্রদান ($_paymentMethod)',
                notes: 'Mess Deposit',
                transactionDate: DateTime.now(),
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );

              walletAdjustmentSucceeded =
              await personalFinanceService.addTransaction(tx);
            }
          } catch (_) {
            walletAdjustmentSucceeded = false;
          }
        }

        if (!mounted) return;

        final String successMessage = !isOwnDeposit
            ? 'ডিপোজিট সফলভাবে জমা হয়েছে। ব্যক্তিগত ওয়ালেট পরিবর্তন করা হয়নি।'
            : walletAdjustmentSucceeded
            ? widget.isAdmin
            ? 'ডিপোজিট সফলভাবে জমা হয়েছে এবং আপনার পার্সোনাল ওয়ালেট থেকে টাকা কেটে নেওয়া হয়েছে!'
            : 'ডিপোজিটের অনুরোধ পাঠানো হয়েছে এবং আপনার পার্সোনাল ওয়ালেট থেকে টাকা সমন্বয় করা হয়েছে!'
            : 'ডিপোজিট জমা হয়েছে, কিন্তু ব্যক্তিগত ওয়ালেট সমন্বয় করা যায়নি। হিসাবটি যাচাই করুন।';

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(successMessage),
            backgroundColor: isOwnDeposit && !walletAdjustmentSucceeded
                ? const Color(0xFFF59E0B)
                : const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('ডিপোজিট যোগ করা যায়নি। আবার চেষ্টা করুন।'),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          content: const Text('একটি সমস্যা হয়েছে। তথ্য যাচাই করে আবার চেষ্টা করুন।'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  // ============================================================
  // MAIN BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildFixedHeader(),
            Expanded(
              child: _isFetchingMembers
                  ? _buildLoadingState()
                  : _memberEmails.isEmpty
                  ? _buildEmptyMembers()
                  : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 30),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildAnimatedItem(0, _buildStatusBanner()),
                      const SizedBox(height: 14),
                      _buildAnimatedItem(1, _buildMemberCard()),
                      const SizedBox(height: 14),
                      _buildAnimatedItem(2, _buildAmountCard()),
                      const SizedBox(height: 14),
                      _buildAnimatedItem(3, _buildPaymentMethodCard()),
                    ],
                  ),
                ),
              ),
            ),
            if (!_isFetchingMembers && _memberEmails.isNotEmpty)
              _buildBottomFloatingButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildAnimatedItem(int index, Widget child) {
    final delay = index * 80;
    return AnimatedBuilder(
      animation: _contentCtrl,
      builder: (context, c) {
        final t = Curves.easeOutCubic.transform(
          ((_contentCtrl.value * 1000 - delay) / 500).clamp(0.0, 1.0),
        );
        return Transform.translate(
          offset: Offset(0, 30 * (1 - t)),
          child: Opacity(opacity: t, child: c),
        );
      },
      child: child,
    );
  }

  // ============================================================
  // FIXED HEADER
  // ============================================================
  Widget _buildFixedHeader() {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_navyDeep, _navyMid, _navyLight],
              stops: [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(
                color: Color(0x331E3A8A),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              // Glass Back Button
              _GlassIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'নতুন জমা',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'মেসের জমার হিসাব যোগ করুন',
                      style: TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Pulsing Savings Icon
              AnimatedBuilder(
                animation: _pulseAnim,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnim.value,
                    child: Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _navyAccent.withValues(alpha: 0.3 * _pulseAnim.value),
                            blurRadius: 12 * _pulseAnim.value,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.savings_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // STATUS BANNER
  // ============================================================
  Widget _buildStatusBanner() {
    final bool admin = widget.isAdmin;
    final Color color = admin ? const Color(0xFF059669) : const Color(0xFFF59E0B);
    final Color bg = admin ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7);
    final Color border = admin ? const Color(0xFFA7F3D0) : const Color(0xFFFDE68A);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.2 * _pulseAnim.value),
                      blurRadius: 8 * _pulseAnim.value,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Icon(
                  admin ? Icons.admin_panel_settings_rounded : Icons.hourglass_top_rounded,
                  color: color,
                  size: 20,
                ),
              );
            },
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      admin ? 'অ্যাডমিন মোড' : 'অনুমোদনের অপেক্ষায়',
                      style: TextStyle(
                        color: color,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (admin)
                      Icon(Icons.verified_rounded, size: 14, color: color),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  admin
                      ? 'অ্যাডমিন হিসেবে আপনার যোগ করা ডিপোজিট স্বয়ংক্রিয়ভাবে "গৃহীত" হবে।'
                      : 'আপনার জমা দেওয়া ডিপোজিটটি অ্যাডমিন নিশ্চিত না করা পর্যন্ত অপেক্ষমাণ থাকবে।',
                  style: TextStyle(
                    color: color.withValues(alpha: 0.85),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // MEMBER CARD
  // ============================================================
  Widget _buildMemberCard() {
    return _buildSectionCard(
      accent: const _CardAccent(
        stripe: Color(0xFF8B5CF6),
        icon: Color(0xFF8B5CF6),
        bg: Color(0xFFEDE9FE),
      ),
      icon: Icons.person_pin_circle_rounded,
      title: 'কার ডিপোজিট?',
      subtitle: widget.isAdmin
          ? 'যে সদস্যের জমা যোগ করবেন তাকে নির্বাচন করুন'
          : 'আপনি নিজের ডিপোজিট জমা দিচ্ছেন',
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: _memberEmails.contains(_selectedMember) ? _selectedMember : null,
            isExpanded: true,
            icon: const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _navyLight,
            ),
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
                    color: _textDark,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }).toList(),
            validator: (value) => (value == null || !_memberEmails.contains(value))
                ? 'একজন সদস্য নির্বাচন করুন'
                : null,
            onChanged: widget.isAdmin
                ? (value) {
              if (value != null) {
                setState(() {
                  _selectedMember = value;
                });
              }
            }
                : null,
          ),
          if (!widget.isAdmin)
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 13, color: _textMuted),
                    SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'সাধারণ সদস্য হিসেবে এই নির্বাচন পরিবর্তন করা যাবে না।',
                        style: TextStyle(
                          color: _textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ============================================================
  // AMOUNT CARD
  // ============================================================
  Widget _buildAmountCard() {
    return _buildSectionCard(
      accent: const _CardAccent(
        stripe: Color(0xFF10B981),
        icon: Color(0xFF10B981),
        bg: Color(0xFFD1FAE5),
      ),
      icon: Icons.account_balance_wallet_rounded,
      title: 'জমার পরিমাণ',
      subtitle: 'কত টাকা জমা দেওয়া হয়েছে তা লিখুন',
      child: Column(
        children: [
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
            ],
            style: const TextStyle(
              color: _textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            decoration: _inputDecoration(
              label: 'টাকার পরিমাণ',
              hint: 'যেমন: 2000',
              icon: Icons.payments_rounded,
            ).copyWith(
              prefixText: '৳ ',
              prefixStyle: const TextStyle(
                color: Color(0xFF059669),
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'টাকার পরিমাণ লিখুন';
              }
              final amount = double.tryParse(value.trim());
              if (amount == null || !amount.isFinite || amount <= 0) {
                return 'সঠিক টাকার পরিমাণ লিখুন';
              }
              return null;
            },
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: _navyLight.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _navyLight.withValues(alpha: 0.15)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline_rounded, color: _navyLight, size: 15),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'টাকার পরিমাণ ইংরেজিতে লিখুন (e.g. 1500)',
                    style: TextStyle(
                      color: _navyMid,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // PAYMENT METHOD CARD
  // ============================================================
  Widget _buildPaymentMethodCard() {
    return _buildSectionCard(
      accent: const _CardAccent(
        stripe: Color(0xFF06B6D4),
        icon: Color(0xFF06B6D4),
        bg: Color(0xFFCFFAFE),
      ),
      icon: Icons.account_balance_rounded,
      title: 'পেমেন্ট মেথড',
      subtitle: 'কোন মাধ্যমে টাকা জমা দেওয়া হয়েছে?',
      child: Column(
        children: [
          _paymentOption(
            value: 'Cash',
            title: 'নগদ টাকা',
            subtitle: 'সরাসরি হাতে টাকা দেওয়া',
            icon: Icons.payments_rounded,
            color: const Color(0xFF10B981),
          ),
          const SizedBox(height: 10),
          _paymentOption(
            value: 'bKash',
            title: 'বিকাশ',
            subtitle: 'বিকাশের মাধ্যমে পেমেন্ট',
            icon: Icons.phone_android_rounded,
            color: const Color(0xFFEC4899),
          ),
          const SizedBox(height: 10),
          _paymentOption(
            value: 'Nagad',
            title: 'নগদ',
            subtitle: 'নগদ মোবাইল ফিন্যান্সিয়াল সার্ভিস',
            icon: Icons.account_balance_wallet_rounded,
            color: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 10),
          _paymentOption(
            value: 'Bank',
            title: 'ব্যাংক',
            subtitle: 'ব্যাংকের মাধ্যমে টাকা জমা',
            icon: Icons.account_balance_rounded,
            color: const Color(0xFF2563EB),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD (with left accent stripe)
  // ============================================================
  Widget _buildSectionCard({
    required _CardAccent accent,
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: accent.stripe.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: accent.stripe),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: accent.bg,
                              borderRadius: BorderRadius.circular(11),
                            ),
                            child: Icon(icon, color: accent.icon, size: 20),
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
                                    fontSize: 15,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.2,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  subtitle,
                                  style: const TextStyle(
                                    color: _textMuted,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      child,
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
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
    required Color color,
  }) {
    final bool selected = _paymentMethod == value;

    return _TapScaleButton(
      onTap: () {
        setState(() {
          _paymentMethod = value;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : _inputBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? color : _borderColor,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: color.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
                    : null,
                color: selected ? null : Colors.white,
                borderRadius: BorderRadius.circular(10),
                boxShadow: selected
                    ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
                    : null,
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : _textMuted,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? _textDark : _textMuted,
                      fontSize: 14,
                      fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: _textMuted,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                gradient: selected
                    ? LinearGradient(
                  colors: [color, color.withValues(alpha: 0.7)],
                )
                    : null,
                color: selected ? null : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? color : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
          ],
        ),
      ),
    );
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
      prefixIcon: Icon(icon, color: _navyLight, size: 20),
      filled: true,
      fillColor: _inputBg,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: const TextStyle(
        color: _textMuted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFFB4C1D0),
        fontSize: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: _navyLight, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
    );
  }

  // ============================================================
  // BOTTOM FLOATING BUTTON
  // ============================================================
  Widget _buildBottomFloatingButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: _pageBg,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: AnimatedBuilder(
          animation: _pulseAnim,
          builder: (context, child) {
            return SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _isLoading
                        ? [Colors.grey.shade400, Colors.grey.shade500]
                        : const [_navyDeep, _navyMid, _navyLight],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: _isLoading
                      ? []
                      : [
                    BoxShadow(
                      color: _navyLight.withValues(alpha: 0.4 * _pulseAnim.value),
                      blurRadius: 18 * _pulseAnim.value,
                      offset: const Offset(0, 8),
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: _isLoading ? null : _submitDeposit,
                    child: _isLoading
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'প্রসেসিং হচ্ছে...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    )
                        : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.check_circle_outline_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          widget.isAdmin ? 'নিশ্চিত করুন' : 'অনুরোধ পাঠান',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================================
  // LOADING STATE
  // ============================================================
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    color: _navyLight.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _navyLight.withValues(alpha: 0.2),
                      width: 2,
                    ),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(
                      strokeWidth: 3,
                      color: _navyLight,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          const Text(
            'লোড হচ্ছে...',
            style: TextStyle(
              color: _textDark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
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
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _navyLight.withValues(alpha: 0.12),
                          _navyLight.withValues(alpha: 0.04),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: _navyLight.withValues(alpha: 0.2),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _navyLight.withValues(alpha: 0.1 * _pulseAnim.value),
                          blurRadius: 20 * _pulseAnim.value,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: _navyLight.withValues(alpha: 0.7),
                      size: 48,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            const Text(
              'কোনো সদস্য পাওয়া যায়নি',
              style: TextStyle(
                color: _textDark,
                fontSize: 19,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'মেম্বার ডাটাবেস ফাঁকা রয়েছে।\nঅনুগ্রহ করে আবার চেষ্টা করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _textMuted,
                fontSize: 13,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 24),
            _TapScaleButton(
              onTap: () {
                setState(() => _isFetchingMembers = true);
                _fetchMembers();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_navyDeep, _navyMid, _navyLight],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: _navyLight.withValues(alpha: 0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      'আবার লোড করুন',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  REUSABLE WIDGETS
// ═══════════════════════════════════════════════

class _CardAccent {
  final Color stripe;
  final Color icon;
  final Color bg;
  const _CardAccent({required this.stripe, required this.icon, required this.bg});
}

class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _GlassIconButton({required this.icon, required this.onTap});

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.25),
              width: 1,
            ),
          ),
          child: Icon(widget.icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

class _TapScaleButton extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;

  const _TapScaleButton({required this.child, required this.onTap});

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}

class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    Listenable? animation,
    Listenable? listenable,
    required this.builder,
    this.child,
  }) : super(listenable: animation ?? listenable ?? const AlwaysStoppedAnimation(0));

  Animation<double> get animation => listenable as Animation<double>;

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}