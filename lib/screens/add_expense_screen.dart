import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/financial_service.dart';
import '../services/auth_service.dart';
import '../models/expense_model.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? existingExpense;

  const AddExpenseScreen({super.key, this.existingExpense});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen>
    with TickerProviderStateMixin {
  final FinancialService _financialService = FinancialService();
  final AuthService _authService = AuthService();

  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productsController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();

  String _selectedPurchaser = '';
  String _paymentSource = 'mess_fund';

  bool _isLoading = false;
  bool _isFetchingMembers = true;

  List<String> _memberEmails = [];
  List<String> _selectedConsumers = [];

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
    _productsController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  // ============================================================
  // FETCH MEMBERS (logic preserved)
  // ============================================================
  Future<void> _fetchMembers() async {
    try {
      final snapshot = await FirebaseFirestore.instance.collection('members').get();

      if (!mounted) return;

      final messMemberDocs = snapshot.docs.where((doc) {
        final data = doc.data();
        return data['role'] != 'wallet_only';
      }).toList();

      messMemberDocs.sort((a, b) {
        final aData = a.data();
        final bData = b.data();
        final aName = (aData['name'] ?? '').toString();
        final bName = (bData['name'] ?? '').toString();
        final aIsNamed = aName.isNotEmpty && aName != 'Unknown' && aName != 'ব্যবহারকারী';
        final bIsNamed = bName.isNotEmpty && bName != 'Unknown' && bName != 'ব্যবহারকারী';
        if (aIsNamed && !bIsNamed) return -1;
        if (!aIsNamed && bIsNamed) return 1;
        return a.id.compareTo(b.id);
      });

      final emails = messMemberDocs.map((doc) => doc.id).take(8).toList();

      setState(() {
        _memberEmails = emails;

        if (_memberEmails.isNotEmpty) {
          final currentEmail = _authService.currentUser?.email;

          if (widget.existingExpense != null) {
            _selectedPurchaser = widget.existingExpense!.purchasedByEmail;
            _paymentSource = widget.existingExpense!.paymentSource;
            _selectedConsumers = List.from(widget.existingExpense!.sharedBetweenEmails);
            _productsController.text = widget.existingExpense!.products.join(', ');
            _amountController.text =
                widget.existingExpense!.totalAmountInTaka.toStringAsFixed(0);
          } else {
            _selectedPurchaser = currentEmail != null && _memberEmails.contains(currentEmail)
                ? currentEmail
                : _memberEmails.first;
            _selectedConsumers = List.from(_memberEmails);
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
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // PRODUCT SELECTION
  // ============================================================
  Future<void> _openProductSelection() async {
    final existingProducts = _productsController.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final result = await Navigator.push<List<String>>(
      context,
      PageRouteBuilder(
        pageBuilder: (_, _, _) => ProductSelectionScreen(initialProducts: existingProducts),
        transitionsBuilder: (_, anim, _, child) => SlideTransition(
          position: Tween<Offset>(begin: const Offset(1, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
        transitionDuration: const Duration(milliseconds: 350),
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _productsController.text = result.join(', ');
      });
    }
  }

  // ============================================================
  // SUBMIT EXPENSE (logic unchanged)
  // ============================================================
  Future<void> _submitExpense() async {
    if (_isLoading) return;
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    if (_memberEmails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('কোনো সদস্য পাওয়া যায়নি।'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    if (_selectedConsumers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অন্তত একজন সদস্য নির্বাচন করুন।'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final List<String> productsList = _productsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final double amount = double.parse(_amountController.text.trim());

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
          SnackBar(
            content: Text(widget.existingExpense == null
                ? 'বাজারের খরচ সফলভাবে সেভ হয়েছে!'
                : 'বাজারের খরচ সফলভাবে আপডেট হয়েছে!'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('খরচ যোগ করা যায়নি। Firebase Rules ও সংযোগ পরীক্ষা করুন।'),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('একটি সমস্যা হয়েছে। আবার চেষ্টা করুন।'),
          backgroundColor: Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
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
                  : Form(
                key: _formKey,
                child: Column(
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildAnimatedItem(0, _buildProductsCard()),
                            const SizedBox(height: 14),
                            _buildAnimatedItem(1, _buildAmountCard()),
                            const SizedBox(height: 14),
                            _buildAnimatedItem(2, _buildPurchaserCard()),
                            const SizedBox(height: 14),
                            _buildAnimatedItem(3, _buildConsumersCard()),
                          ],
                        ),
                      ),
                    ),
                    _buildBottomButton(),
                  ],
                ),
              ),
            ),
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
    final bool isEditing = widget.existingExpense != null;

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
              _GlassIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.maybePop(context),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isEditing ? 'খরচ সম্পাদনা' : 'বাজারের খরচ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      isEditing
                          ? 'পুরোনো বাজারের তথ্য আপডেট করুন'
                          : 'নতুন বাজারের খরচ যোগ করুন',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
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
                      child: Icon(
                        isEditing ? Icons.edit_note_rounded : Icons.shopping_cart_rounded,
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
  // PRODUCTS CARD
  // ============================================================
  Widget _buildProductsCard() {
    return _buildSectionCard(
      accent: const _CardAccent(
        stripe: Color(0xFF8B5CF6),
        icon: Color(0xFF8B5CF6),
        bg: Color(0xFFEDE9FE),
      ),
      icon: Icons.shopping_basket_rounded,
      title: 'বাজারের তালিকা',
      subtitle: 'সহজেই পছন্দের পণ্য নির্বাচন করুন',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _TapScaleButton(
            onTap: _openProductSelection,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                    const Color(0xFF2563EB).withValues(alpha: 0.08),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF2563EB)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add_shopping_cart_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'পণ্য নির্বাচন করুন',
                          style: TextStyle(
                            color: _textDark,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        SizedBox(height: 3),
                        Text(
                          'সার্চ করে অথবা ক্যাটাগরি থেকে বেছে নিন',
                          style: TextStyle(
                            color: _textMuted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Color(0xFF8B5CF6),
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _productsController,
            builder: (context, value, child) {
              final products = value.text
                  .split(',')
                  .map((e) => e.trim())
                  .where((e) => e.isNotEmpty)
                  .toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 17),
                      const SizedBox(width: 6),
                      const Text(
                        'নির্বাচিত পণ্য',
                        style: TextStyle(
                          color: _textDark,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFA7F3D0)),
                        ),
                        child: Text(
                          '${products.length} টি',
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (products.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _borderColor),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.shopping_basket_outlined, color: Color(0xFF94A3B8), size: 28),
                          SizedBox(height: 8),
                          Text(
                            'এখনো কোনো পণ্য নির্বাচন করা হয়নি',
                            style: TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: products.map((product) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                          decoration: BoxDecoration(
                            color: const Color(0xFFD1FAE5),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFA7F3D0)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF059669), size: 13),
                              const SizedBox(width: 5),
                              Text(
                                product,
                                style: const TextStyle(
                                  color: Color(0xFF065F46),
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                ],
              );
            },
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
      title: 'মোট খরচ',
      subtitle: 'বাজারের জন্য মোট কত টাকা খরচ হয়েছে',
      child: Column(
        children: [
          TextFormField(
            controller: _amountController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}'))],
            style: const TextStyle(
              color: _textDark,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
            decoration: _inputDecoration(
              label: 'টাকার পরিমাণ',
              hint: 'যেমন: 1250.00',
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
              if (value == null || value.trim().isEmpty) return 'টাকার পরিমাণ লিখুন';
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
                    'এই সম্পূর্ণ খরচ নির্বাচিত সদস্যদের মধ্যে ভাগ হবে।',
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
  // PURCHASER CARD
  // ============================================================
  Widget _buildPurchaserCard() {
    return _buildSectionCard(
      accent: const _CardAccent(
        stripe: Color(0xFFF59E0B),
        icon: Color(0xFFF59E0B),
        bg: Color(0xFFFEF3C7),
      ),
      icon: Icons.person_pin_circle_rounded,
      title: 'বাজার করেছেন কে?',
      subtitle: 'যে সদস্য বাজারে গিয়েছেন তাকে নির্বাচন করুন',
      child: DropdownButtonFormField<String>(
        initialValue: _memberEmails.contains(_selectedPurchaser) ? _selectedPurchaser : null,
        isExpanded: true,
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _navyLight),
        decoration: _inputDecoration(
          label: 'সদস্য নির্বাচন করুন',
          hint: 'বাজারকারীর নাম',
          icon: Icons.person_rounded,
        ),
        items: _memberEmails.map((email) {
          return DropdownMenuItem<String>(
            value: email,
            child: Text(
              email.split('@').first,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _textDark,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          );
        }).toList(),
        validator: (value) {
          if (value == null || !_memberEmails.contains(value)) {
            return 'একজন সদস্য নির্বাচন করুন';
          }
          return null;
        },
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedPurchaser = value);
        },
      ),
    );
  }

  // ============================================================
  // CONSUMERS CARD
  // ============================================================
  Widget _buildConsumersCard() {
    return _buildSectionCard(
      accent: const _CardAccent(
        stripe: Color(0xFF06B6D4),
        icon: Color(0xFF06B6D4),
        bg: Color(0xFFCFFAFE),
      ),
      icon: Icons.groups_rounded,
      title: 'খরচ ভাগ করবেন কারা?',
      subtitle: 'যেসব সদস্যের মধ্যে এই বাজারের খরচ ভাগ হবে',
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFCFFAFE),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF06B6D4).withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.groups_2_rounded, color: Color(0xFF0891B2), size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${_selectedConsumers.length} / ${_memberEmails.length} জন নির্বাচিত',
                    style: const TextStyle(
                      color: Color(0xFF0891B2),
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                _TapScaleButton(
                  onTap: () {
                    setState(() {
                      if (_selectedConsumers.length == _memberEmails.length) {
                        _selectedConsumers = [_memberEmails.first];
                      } else {
                        _selectedConsumers = List.from(_memberEmails);
                      }
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedConsumers.length == _memberEmails.length ? 'সবাই বাদ' : 'সবাই নির্বাচন',
                      style: const TextStyle(
                        color: Color(0xFF0891B2),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _memberEmails.map((email) {
              final bool selected = _selectedConsumers.contains(email);
              return _TapScaleButton(
                onTap: () {
                  setState(() {
                    if (!selected) {
                      _selectedConsumers.add(email);
                    } else if (_selectedConsumers.length > 1) {
                      _selectedConsumers.remove(email);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('অন্তত একজন সদস্য নির্বাচন করতে হবে।'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF06B6D4) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? const Color(0xFF06B6D4) : _borderColor,
                      width: selected ? 1.5 : 1,
                    ),
                    boxShadow: selected
                        ? [
                      BoxShadow(
                        color: const Color(0xFF06B6D4).withValues(alpha: 0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        selected ? Icons.check_circle_rounded : Icons.person_outline_rounded,
                        size: 15,
                        color: selected ? Colors.white : _textMuted,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        email.split('@').first,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
                          color: selected ? Colors.white : _textDark,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutCubic,
                height: 8,
                width: _memberEmails.isEmpty
                    ? 0
                    : MediaQuery.of(context).size.width *
                    0.74 *
                    (_selectedConsumers.length / _memberEmails.length),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF06B6D4), Color(0xFF2563EB)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.3),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SECTION CARD WRAPPER
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
      labelStyle: const TextStyle(color: _textMuted, fontSize: 12, fontWeight: FontWeight.w600),
      hintStyle: const TextStyle(color: Color(0xFFB4C1D0), fontSize: 13),
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
  // BOTTOM BUTTON
  // ============================================================
  Widget _buildBottomButton() {
    final bool isEditing = widget.existingExpense != null;

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
                    onTap: _isLoading ? null : _submitExpense,
                    child: _isLoading
                        ? const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'খরচ সেভ হচ্ছে...',
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
                        Icon(
                          isEditing ? Icons.system_update_alt_rounded : Icons.save_rounded,
                          size: 20,
                          color: Colors.white,
                        ),
                        const SizedBox(width: 9),
                        Text(
                          isEditing ? 'খরচ আপডেট করুন' : 'খরচ সেভ করুন',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18, color: Colors.white),
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
                    border: Border.all(color: _navyLight.withValues(alpha: 0.2), width: 2),
                  ),
                  child: const Padding(
                    padding: EdgeInsets.all(18),
                    child: CircularProgressIndicator(strokeWidth: 3, color: _navyLight),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 18),
          const Text(
            'সদস্যদের তথ্য লোড হচ্ছে...',
            style: TextStyle(color: _textDark, fontSize: 14, fontWeight: FontWeight.w800),
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
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return Transform.scale(
                  scale: _pulseAnim.value,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          _navyLight.withValues(alpha: 0.12),
                          _navyLight.withValues(alpha: 0.04),
                        ],
                      ),
                      shape: BoxShape.circle,
                      border: Border.all(color: _navyLight.withValues(alpha: 0.2), width: 2),
                    ),
                    child: Icon(Icons.groups_rounded, color: _navyLight.withValues(alpha: 0.7), size: 45),
                  ),
                );
              },
            ),
            const SizedBox(height: 22),
            const Text(
              'কোনো সদস্য পাওয়া যায়নি',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textDark, fontSize: 19, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            const Text(
              'Firebase-এর members কালেকশনে সদস্যদের তথ্য আছে কি না পরীক্ষা করুন।',
              textAlign: TextAlign.center,
              style: TextStyle(color: _textMuted, fontSize: 13, height: 1.6),
            ),
            const SizedBox(height: 22),
            _TapScaleButton(
              onTap: () {
                setState(() => _isFetchingMembers = true);
                _fetchMembers();
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_navyDeep, _navyMid, _navyLight]),
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
                      'আবার চেষ্টা করুন',
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

// ═══════════════════════════════════════════════════════════
//  PRODUCT SELECTION SCREEN — NAVY REDESIGN
// ═══════════════════════════════════════════════════════════

class ProductSelectionScreen extends StatefulWidget {
  final List<String> initialProducts;

  const ProductSelectionScreen({super.key, required this.initialProducts});

  @override
  State<ProductSelectionScreen> createState() => _ProductSelectionScreenState();
}

class _ProductSelectionScreenState extends State<ProductSelectionScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _customController = TextEditingController();

  static const Color _navyDeep = Color(0xFF0F172A);
  static const Color _navyMid = Color(0xFF1E3A8A);
  static const Color _navyLight = Color(0xFF2563EB);
  static const Color _navyAccent = Color(0xFF3B82F6);
  static const Color _pageBg = Color(0xFFF0F4F8);
  static const Color _textDark = Color(0xFF0F172A);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFFE2E8F0);

  int _selectedCategory = 0;
  late List<String> _selectedProducts;

  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  final List<Map<String, dynamic>> _categories = [
    {'name': 'সব পণ্য', 'icon': Icons.apps_rounded, 'color': Color(0xFF2563EB)},
    {'name': 'চাল ও শস্য', 'icon': Icons.rice_bowl_rounded, 'color': Color(0xFFF59E0B)},
    {'name': 'ডাল ও বীজ', 'icon': Icons.grain_rounded, 'color': Color(0xFF8B5CF6)},
    {'name': 'সবজি', 'icon': Icons.eco_rounded, 'color': Color(0xFF10B981)},
    {'name': 'শাকপাতা', 'icon': Icons.spa_rounded, 'color': Color(0xFF059669)},
    {'name': 'মাছ', 'icon': Icons.set_meal_rounded, 'color': Color(0xFF06B6D4)},
    {'name': 'মাংস ও ডিম', 'icon': Icons.egg_alt_rounded, 'color': Color(0xFFDC2626)},
    {'name': 'মসলা', 'icon': Icons.local_dining_rounded, 'color': Color(0xFFEA580C)},
    {'name': 'তেল ও ঘি', 'icon': Icons.water_drop_rounded, 'color': Color(0xFFEAB308)},
    {'name': 'দুধ ও দুগ্ধজাত', 'icon': Icons.local_drink_rounded, 'color': Color(0xFF3B82F6)},
    {'name': 'মুদি ও শুকনো খাবার', 'icon': Icons.shopping_bag_rounded, 'color': Color(0xFFEC4899)},
    {'name': 'নাশতা ও পানীয়', 'icon': Icons.fastfood_rounded, 'color': Color(0xFFF97316)},
    {'name': 'পরিষ্কার সামগ্রী', 'icon': Icons.cleaning_services_rounded, 'color': Color(0xFF14B8A6)},
    {'name': 'অন্যান্য', 'icon': Icons.inventory_2_rounded, 'color': Color(0xFF64748B)},
  ];

  final List<Map<String, String>> _catalog = [
    // 1. চাল ও শস্য
    {'name': 'চাল', 'category': 'চাল ও শস্য'},
    {'name': 'মিনিকেট চাল', 'category': 'চাল ও শস্য'},
    {'name': 'নাজিরশাইল চাল', 'category': 'চাল ও শস্য'},
    {'name': 'আটাশ চাল', 'category': 'চাল ও শস্য'},
    {'name': 'সিদ্ধ চাল', 'category': 'চাল ও শস্য'},
    {'name': 'আতপ চাল', 'category': 'চাল ও শস্য'},
    {'name': 'বাসমতি চাল', 'category': 'চাল ও শস্য'},
    {'name': 'পোলাও চাল', 'category': 'চাল ও শস্য'},
    {'name': 'খিচুড়ির চাল', 'category': 'চাল ও শস্য'},
    {'name': 'চিড়া', 'category': 'চাল ও শস্য'},
    {'name': 'মুড়ি', 'category': 'চাল ও শস্য'},
    {'name': 'খই', 'category': 'চাল ও শস্য'},
    {'name': 'গম', 'category': 'চাল ও শস্য'},
    {'name': 'আটা', 'category': 'চাল ও শস্য'},
    {'name': 'ময়দা', 'category': 'চাল ও শস্য'},
    {'name': 'সুজি', 'category': 'চাল ও শস্য'},
    {'name': 'বেসন', 'category': 'চাল ও শস্য'},
    {'name': 'ভুট্টার আটা', 'category': 'চাল ও শস্য'},
    {'name': 'চালের গুঁড়া', 'category': 'চাল ও শস্য'},
    // 2. ডাল ও বীজ
    {'name': 'মসুর ডাল', 'category': 'ডাল ও বীজ'},
    {'name': 'মুগ ডাল', 'category': 'ডাল ও বীজ'},
    {'name': 'মাষকলাই ডাল', 'category': 'ডাল ও বীজ'},
    {'name': 'ছোলার ডাল', 'category': 'ডাল ও বীজ'},
    {'name': 'খেসারি ডাল', 'category': 'ডাল ও বীজ'},
    {'name': 'অড়হর ডাল', 'category': 'ডাল ও বীজ'},
    {'name': 'বুট', 'category': 'ডাল ও বীজ'},
    {'name': 'ছোলা', 'category': 'ডাল ও বীজ'},
    {'name': 'সাদা মটর', 'category': 'ডাল ও বীজ'},
    {'name': 'কালো মটর', 'category': 'ডাল ও বীজ'},
    {'name': 'সয়াবিন বীজ', 'category': 'ডাল ও বীজ'},
    {'name': 'বাদাম', 'category': 'ডাল ও বীজ'},
    {'name': 'তিল', 'category': 'ডাল ও বীজ'},
    // 3. সবজি
    {'name': 'আলু', 'category': 'সবজি'},
    {'name': 'মিষ্টি আলু', 'category': 'সবজি'},
    {'name': 'পেঁয়াজ', 'category': 'সবজি'},
    {'name': 'রসুন', 'category': 'সবজি'},
    {'name': 'আদা', 'category': 'সবজি'},
    {'name': 'কাঁচামরিচ', 'category': 'সবজি'},
    {'name': 'শুকনা মরিচ', 'category': 'সবজি'},
    {'name': 'টমেটো', 'category': 'সবজি'},
    {'name': 'বেগুন', 'category': 'সবজি'},
    {'name': 'লম্বা বেগুন', 'category': 'সবজি'},
    {'name': 'গোল বেগুন', 'category': 'সবজি'},
    {'name': 'লাউ', 'category': 'সবজি'},
    {'name': 'মিষ্টি কুমড়া', 'category': 'সবজি'},
    {'name': 'চাল কুমড়া', 'category': 'সবজি'},
    {'name': 'ফুলকপি', 'category': 'সবজি'},
    {'name': 'বাঁধাকপি', 'category': 'সবজি'},
    {'name': 'ব্রকলি', 'category': 'সবজি'},
    {'name': 'গাজর', 'category': 'সবজি'},
    {'name': 'মুলা', 'category': 'সবজি'},
    {'name': 'শসা', 'category': 'সবজি'},
    {'name': 'করলা', 'category': 'সবজি'},
    {'name': 'পটল', 'category': 'সবজি'},
    {'name': 'ঢেঁড়স', 'category': 'সবজি'},
    {'name': 'ঝিঙা', 'category': 'সবজি'},
    {'name': 'চিচিঙ্গা', 'category': 'সবজি'},
    {'name': 'ধুন্দুল', 'category': 'সবজি'},
    {'name': 'বরবটি', 'category': 'সবজি'},
    {'name': 'শিম', 'category': 'সবজি'},
    {'name': 'কাঁচা পেঁপে', 'category': 'সবজি'},
    {'name': 'কাঁচা কলা', 'category': 'সবজি'},
    {'name': 'মোচা', 'category': 'সবজি'},
    {'name': 'থোড়', 'category': 'সবজি'},
    {'name': 'কচু', 'category': 'সবজি'},
    {'name': 'মুখী কচু', 'category': 'সবজি'},
    {'name': 'ওল কচু', 'category': 'সবজি'},
    {'name': 'কচুর লতি', 'category': 'সবজি'},
    {'name': 'ক্যাপসিকাম', 'category': 'সবজি'},
    {'name': 'মাশরুম', 'category': 'সবজি'},
    {'name': 'লেবু', 'category': 'সবজি'},
    // 4. শাকপাতা
    {'name': 'পালং শাক', 'category': 'শাকপাতা'},
    {'name': 'লাল শাক', 'category': 'শাকপাতা'},
    {'name': 'ডাঁটা শাক', 'category': 'শাকপাতা'},
    {'name': 'কলমি শাক', 'category': 'শাকপাতা'},
    {'name': 'পুঁই শাক', 'category': 'শাকপাতা'},
    {'name': 'লাউ শাক', 'category': 'শাকপাতা'},
    {'name': 'কুমড়া শাক', 'category': 'শাকপাতা'},
    {'name': 'সরিষা শাক', 'category': 'শাকপাতা'},
    {'name': 'মুলা শাক', 'category': 'শাকপাতা'},
    {'name': 'কচু শাক', 'category': 'শাকপাতা'},
    {'name': 'ধনেপাতা', 'category': 'শাকপাতা'},
    {'name': 'পুদিনা পাতা', 'category': 'শাকপাতা'},
    {'name': 'কারিপাতা', 'category': 'শাকপাতা'},
    {'name': 'পেঁয়াজ পাতা', 'category': 'শাকপাতা'},
    // 5. মাছ
    {'name': 'রুই মাছ', 'category': 'মাছ'},
    {'name': 'কাতলা মাছ', 'category': 'মাছ'},
    {'name': 'মৃগেল মাছ', 'category': 'মাছ'},
    {'name': 'তেলাপিয়া মাছ', 'category': 'মাছ'},
    {'name': 'পাঙ্গাস মাছ', 'category': 'মাছ'},
    {'name': 'সিলভার কার্প', 'category': 'মাছ'},
    {'name': 'গ্রাস কার্প', 'category': 'মাছ'},
    {'name': 'কৈ মাছ', 'category': 'মাছ'},
    {'name': 'শিং মাছ', 'category': 'মাছ'},
    {'name': 'মাগুর মাছ', 'category': 'মাছ'},
    {'name': 'টেংরা মাছ', 'category': 'মাছ'},
    {'name': 'পুঁটি মাছ', 'category': 'মাছ'},
    {'name': 'মলা মাছ', 'category': 'মাছ'},
    {'name': 'কাচকি মাছ', 'category': 'মাছ'},
    {'name': 'চিংড়ি মাছ', 'category': 'মাছ'},
    {'name': 'ইলিশ মাছ', 'category': 'মাছ'},
    {'name': 'বোয়াল মাছ', 'category': 'মাছ'},
    {'name': 'আইড় মাছ', 'category': 'মাছ'},
    {'name': 'শোল মাছ', 'category': 'মাছ'},
    {'name': 'গজার মাছ', 'category': 'মাছ'},
    {'name': 'বাইম মাছ', 'category': 'মাছ'},
    {'name': 'শুঁটকি মাছ', 'category': 'মাছ'},
    {'name': 'ফ্রোজেন মাছ', 'category': 'মাছ'},
    // 6. মাংস ও ডিম
    {'name': 'ব্রয়লার মুরগি', 'category': 'মাংস ও ডিম'},
    {'name': 'সোনালী মুরগি', 'category': 'মাংস ও ডিম'},
    {'name': 'দেশি মুরগি', 'category': 'মাংস ও ডিম'},
    {'name': 'গরুর মাংস', 'category': 'মাংস ও ডিম'},
    {'name': 'খাসির মাংস', 'category': 'মাংস ও ডিম'},
    {'name': 'হাঁসের মাংস', 'category': 'মাংস ও ডিম'},
    {'name': 'কলিজা', 'category': 'মাংস ও ডিম'},
    {'name': 'মুরগির কলিজা', 'category': 'মাংস ও ডিম'},
    {'name': 'মুরগির পা', 'category': 'মাংস ও ডিম'},
    {'name': 'মুরগির ডানা', 'category': 'মাংস ও ডিম'},
    {'name': 'মুরগির গিলা', 'category': 'মাংস ও ডিম'},
    {'name': 'গরুর হাড়', 'category': 'মাংস ও ডিম'},
    {'name': 'গরুর ভুঁড়ি', 'category': 'মাংস ও ডিম'},
    {'name': 'হাঁসের ডিম', 'category': 'মাংস ও ডিম'},
    {'name': 'দেশি মুরগির ডিম', 'category': 'মাংস ও ডিম'},
    {'name': 'ফার্মের ডিম', 'category': 'মাংস ও ডিম'},
    {'name': 'কোয়েলের ডিম', 'category': 'মাংস ও ডিম'},
    // 7. মসলা
    {'name': 'হলুদ গুঁড়া', 'category': 'মসলা'},
    {'name': 'মরিচ গুঁড়া', 'category': 'মসলা'},
    {'name': 'ধনিয়া গুঁড়া', 'category': 'মসলা'},
    {'name': 'জিরা গুঁড়া', 'category': 'মসলা'},
    {'name': 'গরম মসলা', 'category': 'মসলা'},
    {'name': 'পাঁচফোড়ন', 'category': 'মসলা'},
    {'name': 'জিরা', 'category': 'মসলা'},
    {'name': 'ধনিয়া', 'category': 'মসলা'},
    {'name': 'দারুচিনি', 'category': 'মসলা'},
    {'name': 'এলাচ', 'category': 'মসলা'},
    {'name': 'লবঙ্গ', 'category': 'মসলা'},
    {'name': 'গোলমরিচ', 'category': 'মসলা'},
    {'name': 'তেজপাতা', 'category': 'মসলা'},
    {'name': 'জয়ফল', 'category': 'মসলা'},
    {'name': 'জয়ত্রী', 'category': 'মসলা'},
    {'name': 'মেথি', 'category': 'মসলা'},
    {'name': 'সরিষা', 'category': 'মসলা'},
    {'name': 'কালোজিরা', 'category': 'মসলা'},
    {'name': 'রাঁধুনি', 'category': 'মসলা'},
    {'name': 'আমচুর', 'category': 'মসলা'},
    {'name': 'চাট মসলা', 'category': 'মসলা'},
    {'name': 'বিরিয়ানি মসলা', 'category': 'মসলা'},
    {'name': 'মাংসের মসলা', 'category': 'মসলা'},
    {'name': 'মাছের মসলা', 'category': 'মসলা'},
    {'name': 'কাবাব মসলা', 'category': 'মসলা'},
    {'name': 'লবণ', 'category': 'মসলা'},
    {'name': 'বিট লবণ', 'category': 'মসলা'},
    // 8. তেল ও ঘি
    {'name': 'সয়াবিন তেল', 'category': 'তেল ও ঘি'},
    {'name': 'সরিষার তেল', 'category': 'তেল ও ঘি'},
    {'name': 'পাম তেল', 'category': 'তেল ও ঘি'},
    {'name': 'রাইস ব্র্যান তেল', 'category': 'তেল ও ঘি'},
    {'name': 'নারিকেল তেল', 'category': 'তেল ও ঘি'},
    {'name': 'ঘি', 'category': 'তেল ও ঘি'},
    {'name': 'বাটার', 'category': 'তেল ও ঘি'},
    {'name': 'ডালডা', 'category': 'তেল ও ঘি'},
    // 9. দুধ ও দুগ্ধজাত
    {'name': 'তরল দুধ', 'category': 'দুধ ও দুগ্ধজাত'},
    {'name': 'গুঁড়া দুধ', 'category': 'দুধ ও দুগ্ধজাত'},
    {'name': 'কনডেন্সড মিল্ক', 'category': 'দুধ ও দুগ্ধজাত'},
    {'name': 'টক দই', 'category': 'দুধ ও দুগ্ধজাত'},
    {'name': 'মিষ্টি দই', 'category': 'দুধ ও দুগ্ধজাত'},
    {'name': 'পনির', 'category': 'দুধ ও দুগ্ধজাত'},
    {'name': 'চিজ', 'category': 'দুধ ও দুগ্ধজাত'},
    {'name': 'মাখন', 'category': 'দুধ ও দুগ্ধজাত'},
    // 10. মুদি
    {'name': 'চিনি', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'লাল চিনি', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'গুড়', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'খেজুরের গুড়', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'চা পাতা', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'কফি', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'সেমাই', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'নুডলস', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'পাস্তা', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'ম্যাকারনি', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'পাউরুটি', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'টোস্ট বিস্কুট', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'বিস্কুট', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'কেক', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'টমেটো সস', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'সয়াসস', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'ভিনেগার', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'আচার', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'জ্যাম', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'মধু', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'নারিকেল', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'শুকনা নারিকেল', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'কিশমিশ', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'খেজুর', 'category': 'মুদি ও শুকনো খাবার'},
    {'name': 'চিনাবাদাম', 'category': 'মুদি ও শুকনো খাবার'},
    // 11. নাশতা
    {'name': 'পানি', 'category': 'নাশতা ও পানীয়'},
    {'name': 'মিনারেল ওয়াটার', 'category': 'নাশতা ও পানীয়'},
    {'name': 'জুস', 'category': 'নাশতা ও পানীয়'},
    {'name': 'কোল্ড ড্রিংকস', 'category': 'নাশতা ও পানীয়'},
    {'name': 'লাচ্ছি', 'category': 'নাশতা ও পানীয়'},
    {'name': 'চিপস', 'category': 'নাশতা ও পানীয়'},
    {'name': 'চানাচুর', 'category': 'নাশতা ও পানীয়'},
    {'name': 'ঝালমুড়ি', 'category': 'নাশতা ও পানীয়'},
    {'name': 'পপকর্ন', 'category': 'নাশতা ও পানীয়'},
    {'name': 'চকলেট', 'category': 'নাশতা ও পানীয়'},
    {'name': 'ওয়েফার', 'category': 'নাশতা ও পানীয়'},
    // 12. পরিষ্কার
    {'name': 'কাপড় কাচার সাবান', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'ডিটারজেন্ট পাউডার', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'হুইল পাউডার', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'সার্ফ এক্সেল', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'ডিশওয়াশ', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'বাসন মাজার সাবান', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'ফ্লোর ক্লিনার', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'টয়লেট ক্লিনার', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'ব্লিচিং পাউডার', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'ফিনাইল', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'মশার কয়েল', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'মশার স্প্রে', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'টিস্যু', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'টয়লেট টিস্যু', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'ঝাড়ু', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'মোছার কাপড়', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'স্ক্রাবার', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'ডাস্টবিন ব্যাগ', 'category': 'পরিষ্কার সামগ্রী'},
    {'name': 'ময়লার ব্যাগ', 'category': 'পরিষ্কার সামগ্রী'},
    // 13. অন্যান্য
    {'name': 'গোসলের সাবান', 'category': 'অন্যান্য'},
    {'name': 'হ্যান্ডওয়াশ', 'category': 'অন্যান্য'},
    {'name': 'শ্যাম্পু', 'category': 'অন্যান্য'},
    {'name': 'টুথপেস্ট', 'category': 'অন্যান্য'},
    {'name': 'টুথব্রাশ', 'category': 'অন্যান্য'},
    {'name': 'ম্যাচ', 'category': 'অন্যান্য'},
    {'name': 'লাইটার', 'category': 'অন্যান্য'},
    {'name': 'মোমবাতি', 'category': 'অন্যান্য'},
    {'name': 'পলিথিন', 'category': 'অন্যান্য'},
    {'name': 'কাগজ', 'category': 'অন্যান্য'},
    {'name': 'অ্যালুমিনিয়াম ফয়েল', 'category': 'অন্যান্য'},
    {'name': 'প্যাকেট', 'category': 'অন্যান্য'},
    {'name': 'রান্নার গ্যাস', 'category': 'অন্যান্য'},
    {'name': 'গ্যাস সিলিন্ডার', 'category': 'অন্যান্য'},
    {'name': 'পানির জার', 'category': 'অন্যান্য'},
    {'name': 'অন্যান্য বাজার', 'category': 'অন্যান্য'},
  ];

  @override
  void initState() {
    super.initState();
    _selectedProducts = List.from(widget.initialProducts);

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.1)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _headerCtrl.forward();
    _pulseCtrl.repeat(reverse: true);
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _pulseCtrl.dispose();
    _searchController.dispose();
    _customController.dispose();
    super.dispose();
  }

  bool _containsProduct(String name) {
    return _selectedProducts.any((e) => e.toLowerCase() == name.trim().toLowerCase());
  }

  void _toggleProduct(String name) {
    setState(() {
      if (_containsProduct(name)) {
        _selectedProducts.removeWhere((e) => e.toLowerCase() == name.toLowerCase());
      } else {
        _selectedProducts.add(name);
      }
    });
  }

  void _addCustomProduct() {
    final name = _customController.text.trim();
    if (name.isEmpty) return;

    if (_containsProduct(name)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('পণ্যটি আগে থেকেই নির্বাচন করা আছে।')),
      );
      return;
    }

    setState(() {
      _selectedProducts.add(name);
      _customController.clear();
      _searchController.clear();
    });

    FocusScope.of(context).unfocus();
  }

  List<Map<String, String>> get _filteredProducts {
    final query = _searchController.text.trim().toLowerCase();
    return _catalog.where((product) {
      final matchesCategory =
          _selectedCategory == 0 || product['category'] == _categories[_selectedCategory]['name'];
      final matchesSearch = query.isEmpty || product['name']!.toLowerCase().contains(query);
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final products = _filteredProducts;

    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _buildFixedHeader(),
            _buildSearchBar(),
            _buildCategoriesBar(),
            _buildCountBar(),
            Expanded(
              child: products.isEmpty
                  ? _buildEmptyProductsState()
                  : GridView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.6,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  final name = product['name']!;
                  final selected = _containsProduct(name);
                  return _buildProductTile(name, selected);
                },
              ),
            ),
            _buildBottomSection(),
          ],
        ),
      ),
    );
  }

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
            ),
            borderRadius: BorderRadius.only(
              bottomLeft: Radius.circular(28),
              bottomRight: Radius.circular(28),
            ),
            boxShadow: [
              BoxShadow(color: Color(0x331E3A8A), blurRadius: 24, offset: Offset(0, 8)),
            ],
          ),
          child: Row(
            children: [
              _GlassIconButton(
                icon: Icons.arrow_back_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'পণ্য নির্বাচন',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'আপনার বাজারের পণ্যগুলো বেছে নিন',
                      style: TextStyle(
                        color: Color(0xB3FFFFFF),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Done button
              _TapScaleButton(
                onTap: () => Navigator.pop(context, _selectedProducts),
                child: AnimatedBuilder(
                  animation: _pulseAnim,
                  builder: (context, child) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: _navyAccent.withValues(alpha: 0.3 * _pulseAnim.value),
                            blurRadius: 10 * _pulseAnim.value,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check_rounded, color: Colors.white, size: 15),
                          const SizedBox(width: 4),
                          const Text(
                            'সম্পন্ন',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _navyMid.withValues(alpha: 0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (_) => setState(() {}),
          style: const TextStyle(
            color: _textDark,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          decoration: InputDecoration(
            hintText: 'পণ্যের নাম লিখে সার্চ করুন...',
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: const Icon(Icons.search_rounded, color: _navyLight),
            suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
              onPressed: () {
                _searchController.clear();
                setState(() {});
              },
              icon: const Icon(Icons.close_rounded, color: _textMuted),
            )
                : null,
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: _navyLight, width: 1.5),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCategoriesBar() {
    return SizedBox(
      height: 46,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final selected = _selectedCategory == index;
          final cat = _categories[index];
          final color = cat['color'] as Color;

          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: _TapScaleButton(
              onTap: () => setState(() => _selectedCategory = index),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  gradient: selected
                      ? LinearGradient(colors: [color, color.withValues(alpha: 0.7)])
                      : null,
                  color: selected ? null : Colors.white,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: selected ? color : _borderColor,
                    width: 1,
                  ),
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
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      cat['icon'],
                      size: 15,
                      color: selected ? Colors.white : color,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      cat['name'],
                      style: TextStyle(
                        color: selected ? Colors.white : _textDark,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCountBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Row(
        children: [
          const Text(
            'পণ্যের তালিকা',
            style: TextStyle(
              color: _textDark,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFD1FAE5),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFA7F3D0)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 12, color: Color(0xFF059669)),
                const SizedBox(width: 4),
                Text(
                  '${_selectedProducts.length} টি নির্বাচিত',
                  style: const TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductTile(String name, bool selected) {
    return _TapScaleButton(
      onTap: () => _toggleProduct(name),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? LinearGradient(
            colors: [
              const Color(0xFF10B981).withValues(alpha: 0.12),
              const Color(0xFF2563EB).withValues(alpha: 0.08),
            ],
          )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF10B981) : _borderColor,
            width: selected ? 1.5 : 1,
          ),
          boxShadow: selected
              ? [
            BoxShadow(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ]
              : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? const Color(0xFF065F46) : _textDark,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 6),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                    : null,
                color: selected ? null : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? const Color(0xFF10B981) : const Color(0xFFCBD5E1),
                  width: 2,
                ),
              ),
              child: Icon(
                selected ? Icons.check_rounded : Icons.add_rounded,
                color: selected ? Colors.white : _textMuted,
                size: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyProductsState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _pulseAnim,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnim.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _navyLight.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.search_off_rounded,
                    size: 40,
                    color: _navyLight.withValues(alpha: 0.6),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          const Text(
            'কোনো পণ্য পাওয়া যায়নি',
            style: TextStyle(
              color: _textDark,
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'অন্য ক্যাটাগরি বা সার্চ চেষ্টা করুন',
            style: TextStyle(
              color: Colors.grey.shade500,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
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
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: _pageBg,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: TextField(
                      controller: _customController,
                      style: const TextStyle(
                        color: _textDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                      decoration: InputDecoration(
                        hintText: 'নতুন পণ্যের নাম লিখুন',
                        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        isDense: true,
                        filled: true,
                        fillColor: _pageBg,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _addCustomProduct(),
                    ),
                  ),
                ),
                const SizedBox(width: 9),
                _TapScaleButton(
                  onTap: _addCustomProduct,
                  child: Container(
                    height: 48,
                    width: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF2563EB)],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) {
                return SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_navyDeep, _navyMid, _navyLight],
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: _navyLight.withValues(alpha: 0.35 * _pulseAnim.value),
                          blurRadius: 14 * _pulseAnim.value,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(15),
                        onTap: () => Navigator.pop(context, _selectedProducts),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'নির্বাচিত পণ্য যুক্ত করুন (${_selectedProducts.length})',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
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
            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
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