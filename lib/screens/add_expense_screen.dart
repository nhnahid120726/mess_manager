import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_colors.dart';
import '../services/financial_service.dart';
import '../services/auth_service.dart';
import '../models/expense_model.dart';

class AddExpenseScreen extends StatefulWidget {
  final ExpenseModel? existingExpense;

  const AddExpenseScreen({
    super.key,
    this.existingExpense,
  });

  @override
  State<AddExpenseScreen> createState() =>
      _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final FinancialService _financialService =
  FinancialService();

  final AuthService _authService =
  AuthService();

  final _formKey = GlobalKey<FormState>();

  final TextEditingController _productsController =
  TextEditingController();

  final TextEditingController _amountController =
  TextEditingController();

  String _selectedPurchaser = '';
  String _paymentSource = 'mess_fund';

  bool _isLoading = false;
  bool _isFetchingMembers = true;

  List<String> _memberEmails = [];
  List<String> _selectedConsumers = [];

  // ============================================================
  // MODERN UI COLORS
  // ============================================================

  static const Color primary = AppColors.primary;
  static const Color primaryDark = AppColors.primaryDark;

  static const Color background = AppColors.background;
  static const Color textDark = AppColors.textPrimary;
  static const Color textMuted = AppColors.textSecondary;

  static const Color border = AppColors.border;

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
      final snapshot = await FirebaseFirestore.instance
          .collection('members')
          .get();

      if (!mounted) return;

      final emails =
      snapshot.docs.map((doc) => doc.id).toList();

      setState(() {
        _memberEmails = emails;

        if (_memberEmails.isNotEmpty) {
          final currentEmail =
              _authService.currentUser?.email;

          if (widget.existingExpense != null) {
            _selectedPurchaser =
                widget.existingExpense!.purchasedByEmail;

            _paymentSource =
                widget.existingExpense!.paymentSource;

            _selectedConsumers = List.from(
              widget.existingExpense!
                  .sharedBetweenEmails,
            );

            _productsController.text =
                widget.existingExpense!.products.join(', ');

            _amountController.text =
                widget.existingExpense!
                    .totalAmountInTaka
                    .toStringAsFixed(0);
          } else {
            _selectedPurchaser =
            currentEmail != null &&
                _memberEmails.contains(currentEmail)
                ? currentEmail
                : _memberEmails.first;

            _selectedConsumers =
                List.from(_memberEmails);
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
          content: Text(
            'সদস্যদের তথ্য লোড করা যায়নি। আবার চেষ্টা করুন।',
          ),
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

      prefixIcon: Icon(
        icon,
        color: primary,
        size: 21,
      ),

      filled: true,
      fillColor: const Color(0xFFFBFCFE),

      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),

      labelStyle: const TextStyle(
        color: textMuted,
        fontSize: 13,
        fontWeight: FontWeight.w500,
      ),

      hintStyle: const TextStyle(
        color: Color(0xFFAAB5C3),
        fontSize: 13,
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: border,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: border,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: primary,
          width: 1.6,
        ),
      ),

      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
        ),
      ),

      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  // ============================================================
  // SECTION CARD
  // ============================================================

  Widget _sectionCard({
    required Widget child,
    EdgeInsetsGeometry padding =
    const EdgeInsets.all(18),
  }) {
    return Container(
      width: double.infinity,
      padding: padding,

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),

        border: Border.all(
          color: border,
        ),

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

  Widget _sectionTitle(
      IconData icon,
      String title, {
        String? subtitle,
      }) {
    return Row(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Container(
          width: 44,
          height: 44,

          decoration: BoxDecoration(
            color: const Color(0xFFE8F7F5),
            borderRadius:
            BorderRadius.circular(14),
          ),

          child: Icon(
            icon,
            color: primary,
            size: 22,
          ),
        ),

        const SizedBox(width: 12),

        Expanded(
          child: Column(
            crossAxisAlignment:
            CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: textDark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
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
  // PRODUCT CHIP
  // ============================================================

  void _addProduct(String item) {
    final current =
    _productsController.text.trim();

    final products = current.isEmpty
        ? <String>[]
        : current
        .split(',')
        .map((e) => e.trim())
        .toList();

    if (products.contains(item)) return;

    setState(() {
      if (current.isEmpty) {
        _productsController.text = item;
      } else {
        _productsController.text =
        '$current, $item';
      }

      _productsController.selection =
          TextSelection.collapsed(
            offset:
            _productsController.text.length,
          );
    });
  }

  // ============================================================
  // SUBMIT EXPENSE
  // ============================================================

  Future<void> _submitExpense() async {
    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_memberEmails.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'কোনো সদস্য পাওয়া যায়নি।',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    if (_selectedConsumers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'অন্তত একজন সদস্য নির্বাচন করুন।',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final List<String> productsList =
      _productsController.text
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();

      final double amount =
      double.parse(
        _amountController.text.trim(),
      );

      // ========================================================
      // EXISTING BACKEND LOGIC — UNCHANGED
      // ========================================================

      bool success = false;

      if (widget.existingExpense == null) {
        success =
        await _financialService.addMarketExpense(
          products: productsList,
          totalAmountInTaka: amount,
          purchasedByEmail: _selectedPurchaser,
          paidByEmail: _selectedPurchaser,
          paymentSource: _paymentSource,
          sharedBetweenEmails:
          List<String>.from(
            _selectedConsumers,
          ),
        );
      } else {
        success =
        await _financialService
            .updateMarketExpense(
          expenseId:
          widget.existingExpense!.id,
          products: productsList,
          totalAmountInTaka: amount,
          purchasedByEmail: _selectedPurchaser,
          paidByEmail: _selectedPurchaser,
          paymentSource: _paymentSource,
          sharedBetweenEmails:
          List<String>.from(
            _selectedConsumers,
          ),
        );
      }

      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.existingExpense == null
                  ? 'বাজারের খরচ সফলভাবে সেভ হয়েছে!'
                  : 'বাজারের খরচ সফলভাবে আপডেট হয়েছে!',
            ),

            backgroundColor: primary,

            behavior:
            SnackBarBehavior.floating,

            shape:
            RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(12),
            ),
          ),
        );

        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'খরচ যোগ করা যায়নি। Firebase Rules ও সংযোগ পরীক্ষা করুন।',
            ),
            backgroundColor:
            Colors.redAccent,
            behavior:
            SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'একটি সমস্যা হয়েছে। আবার চেষ্টা করুন।',
          ),
          backgroundColor:
          Colors.redAccent,
          behavior:
          SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ============================================================
  // MAIN UI
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final bool isEditing =
        widget.existingExpense != null;

    return Scaffold(
      backgroundColor: background,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        foregroundColor: textDark,

        centerTitle: false,

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
          ),
          onPressed: () {
            Navigator.maybePop(context);
          },
        ),

        title: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            Text(
              isEditing
                  ? 'খরচ সম্পাদনা'
                  : 'বাজারের খরচ',

              style: const TextStyle(
                color: textDark,
                fontSize: 20,
                fontWeight: FontWeight.w900,
              ),
            ),

            const SizedBox(height: 2),

            Text(
              isEditing
                  ? 'পুরোনো বাজারের তথ্য আপডেট করুন'
                  : 'নতুন বাজারের খরচ যোগ করুন',

              style: const TextStyle(
                color: textMuted,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),

        bottom: PreferredSize(
          preferredSize:
          const Size.fromHeight(1),

          child: Container(
            height: 1,
            color: border,
          ),
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
                child:
                SingleChildScrollView(
                  physics:
                  const BouncingScrollPhysics(),

                  padding:
                  const EdgeInsets.fromLTRB(
                    16,
                    18,
                    16,
                    24,
                  ),

                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,

                    children: [
                      _buildHeaderBanner(),

                      const SizedBox(
                        height: 18,
                      ),

                      // ==================================================
                      // PRODUCTS
                      // ==================================================

                      _sectionCard(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [
                            _sectionTitle(
                              Icons
                                  .shopping_basket_rounded,
                              'বাজারের তালিকা',
                              subtitle:
                              'কী কী কিনেছেন, কমা দিয়ে লিখুন',
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            TextFormField(
                              controller:
                              _productsController,

                              textCapitalization:
                              TextCapitalization
                                  .sentences,

                              maxLines: 2,

                              decoration:
                              _inputDecoration(
                                label:
                                'পণ্যের নাম',
                                hint:
                                'যেমন: চাল, ডাল, মুরগি',
                                icon:
                                Icons
                                    .receipt_long_rounded,
                              ),

                              validator:
                                  (value) {
                                if (value ==
                                    null ||
                                    value
                                        .trim()
                                        .isEmpty) {
                                  return 'পণ্যের নাম লিখুন';
                                }

                                if (value
                                    .split(',')
                                    .every(
                                      (e) => e
                                      .trim()
                                      .isEmpty,
                                )) {
                                  return 'সঠিক পণ্যের নাম লিখুন';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            Row(
                              children: [
                                Container(
                                  width: 30,
                                  height: 30,

                                  decoration:
                                  BoxDecoration(
                                    color:
                                    const Color(
                                      0xFFE8F7F5,
                                    ),
                                    borderRadius:
                                    BorderRadius
                                        .circular(
                                      9,
                                    ),
                                  ),

                                  child:
                                  const Icon(
                                    Icons
                                        .auto_awesome_rounded,
                                    color:
                                    primary,
                                    size: 16,
                                  ),
                                ),

                                const SizedBox(
                                  width: 9,
                                ),

                                const Text(
                                  'দ্রুত পণ্য যোগ করুন',
                                  style:
                                  TextStyle(
                                    color:
                                    textDark,
                                    fontSize:
                                    13,
                                    fontWeight:
                                    FontWeight
                                        .w700,
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,

                              children: [
                                'চাল',
                                'ডাল',
                                'সয়াবিন তেল',
                                'সরিষার তেল',
                                'পেঁয়াজ',
                                'রসুন',
                                'আদা',
                                'আলু',
                                'ডিম',
                                'ব্রয়লার মুরগি',
                                'সোনালী মুরগি',
                                'গরুর মাংস',
                                'মাছ',
                                'সবজি',
                                'কাঁচামরিচ',
                                'ধনেপাতা',
                                'লেবু',
                                'টমেটো',
                                'শসা',
                                'লবণ',
                                'হলুদ',
                                'মরিচ গুঁড়া',
                                'জিরা',
                                'গরম মসলা',
                                'চা পাতা',
                                'চিনি',
                                'দুধ',
                                'বিস্কুট',
                                'মুড়ি',
                                'সাবান',
                                'শ্যাম্পু',
                                'হুইল পাউডার',
                                'ডিশওয়াশ',
                                'টিস্যু',
                                'মশা মারার কয়েল',
                              ].map(
                                    (item) {
                                  return ActionChip(
                                    avatar:
                                    const Icon(
                                      Icons
                                          .add_rounded,
                                      size:
                                      15,
                                      color:
                                      primary,
                                    ),

                                    label:
                                    Text(
                                      item,
                                      style:
                                      const TextStyle(
                                        fontSize:
                                        11.5,
                                        fontWeight:
                                        FontWeight
                                            .w600,
                                      ),
                                    ),

                                    backgroundColor:
                                    const Color(
                                      0xFFF1F9F7,
                                    ),

                                    side:
                                    const BorderSide(
                                      color:
                                      Color(
                                        0xFFD7EBE6,
                                      ),
                                    ),

                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        12,
                                      ),
                                    ),

                                    onPressed:
                                        () =>
                                        _addProduct(
                                          item,
                                        ),
                                  );
                                },
                              ).toList(),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // AMOUNT
                      // ==================================================

                      _sectionCard(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [
                            _sectionTitle(
                              Icons
                                  .account_balance_wallet_rounded,
                              'মোট খরচ',
                              subtitle:
                              'বাজারের জন্য মোট কত টাকা খরচ হয়েছে',
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            TextFormField(
                              controller:
                              _amountController,

                              keyboardType:
                              const TextInputType
                                  .numberWithOptions(
                                decimal: true,
                              ),

                              inputFormatters: [
                                FilteringTextInputFormatter
                                    .allow(
                                  RegExp(
                                    r'^\d*\.?\d{0,2}',
                                  ),
                                ),
                              ],

                              decoration:
                              _inputDecoration(
                                label:
                                'টাকার পরিমাণ',
                                hint:
                                'যেমন: 1250.00',
                                icon:
                                Icons
                                    .payments_rounded,
                              ).copyWith(
                                prefixText:
                                '৳ ',

                                prefixStyle:
                                const TextStyle(
                                  color:
                                  primary,
                                  fontSize:
                                  18,
                                  fontWeight:
                                  FontWeight
                                      .w900,
                                ),
                              ),

                              validator:
                                  (value) {
                                if (value ==
                                    null ||
                                    value
                                        .trim()
                                        .isEmpty) {
                                  return 'টাকার পরিমাণ লিখুন';
                                }

                                final amount =
                                double.tryParse(
                                  value.trim(),
                                );

                                if (amount ==
                                    null ||
                                    !amount.isFinite ||
                                    amount <=
                                        0) {
                                  return 'সঠিক টাকার পরিমাণ লিখুন';
                                }

                                return null;
                              },
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            Container(
                              width:
                              double.infinity,

                              padding:
                              const EdgeInsets
                                  .all(
                                12,
                              ),

                              decoration:
                              BoxDecoration(
                                color:
                                const Color(
                                  0xFFEFF9F7,
                                ),

                                borderRadius:
                                BorderRadius
                                    .circular(
                                  12,
                                ),
                              ),

                              child:
                              const Row(
                                children: [
                                  Icon(
                                    Icons
                                        .info_outline_rounded,
                                    color:
                                    primary,
                                    size:
                                    18,
                                  ),

                                  SizedBox(
                                    width: 9,
                                  ),

                                  Expanded(
                                    child:
                                    Text(
                                      'এই সম্পূর্ণ খরচ নির্বাচিত সদস্যদের মধ্যে ভাগ হবে।',
                                      style:
                                      TextStyle(
                                        color:
                                        primaryDark,
                                        fontSize:
                                        11.5,
                                        fontWeight:
                                        FontWeight
                                            .w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // PURCHASER
                      // ==================================================

                      _sectionCard(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [
                            _sectionTitle(
                              Icons
                                  .person_pin_circle_rounded,
                              'বাজার করেছেন কে?',
                              subtitle:
                              'যে সদস্য বাজারে গিয়েছেন তাকে নির্বাচন করুন',
                            ),

                            const SizedBox(
                              height: 20,
                            ),

                            DropdownButtonFormField<
                                String>(
                              initialValue:
                              _memberEmails
                                  .contains(
                                _selectedPurchaser,
                              )
                                  ? _selectedPurchaser
                                  : null,

                              isExpanded:
                              true,

                              decoration:
                              _inputDecoration(
                                label:
                                'সদস্য নির্বাচন করুন',
                                hint:
                                'বাজারকারীর নাম',
                                icon:
                                Icons
                                    .person_rounded,
                              ),

                              items:
                              _memberEmails
                                  .map(
                                    (email) {
                                  return DropdownMenuItem<
                                      String>(
                                    value:
                                    email,

                                    child:
                                    Text(
                                      email
                                          .split(
                                        '@',
                                      )
                                          .first,

                                      overflow:
                                      TextOverflow
                                          .ellipsis,

                                      style:
                                      const TextStyle(
                                        color:
                                        textDark,
                                        fontSize:
                                        14,
                                        fontWeight:
                                        FontWeight
                                            .w600,
                                      ),
                                    ),
                                  );
                                },
                              ).toList(),

                              validator:
                                  (value) {
                                if (value ==
                                    null ||
                                    !_memberEmails
                                        .contains(
                                      value,
                                    )) {
                                  return 'একজন সদস্য নির্বাচন করুন';
                                }

                                return null;
                              },

                              onChanged:
                                  (value) {
                                if (value ==
                                    null) {
                                  return;
                                }

                                setState(() {
                                  _selectedPurchaser =
                                      value;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      // ==================================================
                      // CONSUMERS
                      // ==================================================

                      _sectionCard(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,

                          children: [
                            _sectionTitle(
                              Icons
                                  .groups_rounded,
                              'খরচ ভাগ করবেন কারা?',
                              subtitle:
                              'যেসব সদস্যের মধ্যে এই বাজারের খরচ ভাগ হবে',
                            ),

                            const SizedBox(
                              height: 18,
                            ),

                            Container(
                              padding:
                              const EdgeInsets
                                  .symmetric(
                                horizontal: 13,
                                vertical: 10,
                              ),

                              decoration:
                              BoxDecoration(
                                color:
                                const Color(
                                  0xFFF4F8FA,
                                ),

                                borderRadius:
                                BorderRadius
                                    .circular(
                                  13,
                                ),
                              ),

                              child: Row(
                                children: [
                                  const Icon(
                                    Icons
                                        .groups_2_rounded,
                                    color:
                                    primary,
                                    size: 19,
                                  ),

                                  const SizedBox(
                                    width: 8,
                                  ),

                                  Expanded(
                                    child:
                                    Text(
                                      '${_selectedConsumers.length} / ${_memberEmails.length} জন নির্বাচিত',

                                      style:
                                      const TextStyle(
                                        color:
                                        primary,
                                        fontSize:
                                        12,
                                        fontWeight:
                                        FontWeight
                                            .w800,
                                      ),
                                    ),
                                  ),

                                  TextButton(
                                    onPressed:
                                        () {
                                      setState(
                                            () {
                                          if (_selectedConsumers
                                              .length ==
                                              _memberEmails
                                                  .length) {
                                            _selectedConsumers =
                                            [
                                              _memberEmails
                                                  .first,
                                            ];
                                          } else {
                                            _selectedConsumers =
                                                List.from(
                                                  _memberEmails,
                                                );
                                          }
                                        },
                                      );
                                    },

                                    child:
                                    Text(
                                      _selectedConsumers
                                          .length ==
                                          _memberEmails
                                              .length
                                          ? 'সবাই বাদ'
                                          : 'সবাই নির্বাচন',

                                      style:
                                      const TextStyle(
                                        color:
                                        primary,
                                        fontSize:
                                        11.5,
                                        fontWeight:
                                        FontWeight
                                            .w800,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(
                              height: 14,
                            ),

                            Wrap(
                              spacing: 8,
                              runSpacing: 8,

                              children:
                              _memberEmails
                                  .map(
                                    (email) {
                                  final bool
                                  selected =
                                  _selectedConsumers
                                      .contains(
                                    email,
                                  );

                                  return FilterChip(
                                    avatar:
                                    Icon(
                                      selected
                                          ? Icons
                                          .check_circle_rounded
                                          : Icons
                                          .person_outline_rounded,

                                      size:
                                      17,

                                      color: selected
                                          ? primary
                                          : textMuted,
                                    ),

                                    label:
                                    Text(
                                      email
                                          .split(
                                        '@',
                                      )
                                          .first,

                                      style:
                                      TextStyle(
                                        fontSize:
                                        12,

                                        fontWeight:
                                        selected
                                            ? FontWeight
                                            .w700
                                            : FontWeight
                                            .w500,

                                        color:
                                        selected
                                            ? primaryDark
                                            : textDark,
                                      ),
                                    ),

                                    selected:
                                    selected,

                                    showCheckmark:
                                    false,

                                    backgroundColor:
                                    Colors
                                        .white,

                                    selectedColor:
                                    const Color(
                                      0xFFE3F5F0,
                                    ),

                                    side:
                                    BorderSide(
                                      color:
                                      selected
                                          ? const Color(
                                        0xFF82CDBB,
                                      )
                                          : border,

                                      width:
                                      selected
                                          ? 1.3
                                          : 1,
                                    ),

                                    shape:
                                    RoundedRectangleBorder(
                                      borderRadius:
                                      BorderRadius
                                          .circular(
                                        14,
                                      ),
                                    ),

                                    onSelected:
                                        (value) {
                                      setState(
                                            () {
                                          if (value) {
                                            if (!_selectedConsumers
                                                .contains(
                                              email,
                                            )) {
                                              _selectedConsumers
                                                  .add(
                                                email,
                                              );
                                            }
                                          } else if (_selectedConsumers
                                              .length >
                                              1) {
                                            _selectedConsumers
                                                .remove(
                                              email,
                                            );
                                          } else {
                                            ScaffoldMessenger
                                                .of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content:
                                                Text(
                                                  'অন্তত একজন সদস্য নির্বাচন করতে হবে।',
                                                ),
                                                behavior:
                                                SnackBarBehavior
                                                    .floating,
                                              ),
                                            );
                                          }
                                        },
                                      );
                                    },
                                  );
                                },
                              ).toList(),
                            ),

                            const SizedBox(
                              height: 16,
                            ),

                            ClipRRect(
                              borderRadius:
                              BorderRadius
                                  .circular(
                                20,
                              ),

                              child:
                              LinearProgressIndicator(
                                value:
                                _memberEmails
                                    .isEmpty
                                    ? 0
                                    : _selectedConsumers
                                    .length /
                                    _memberEmails
                                        .length,

                                minHeight: 7,

                                backgroundColor:
                                const Color(
                                  0xFFEAF0F2,
                                ),

                                color:
                                primary,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),
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
    final bool isEditing =
        widget.existingExpense != null;

    return Container(
      width: double.infinity,

      padding: const EdgeInsets.all(20),

      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            primary,
            primaryDark,
          ],

          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),

        borderRadius:
        BorderRadius.circular(24),

        boxShadow: [
          BoxShadow(
            color:
            primary.withValues(alpha: 0.20),
            blurRadius: 22,
            offset: const Offset(0, 9),
          ),
        ],
      ),

      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,

              children: [
                Text(
                  isEditing
                      ? 'বাজারের খরচ আপডেট'
                      : 'আজকের বাজারের হিসাব',

                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight:
                    FontWeight.w900,
                  ),
                ),

                const SizedBox(
                  height: 8,
                ),

                Text(
                  isEditing
                      ? 'আগের বাজারের তথ্য পরিবর্তন করে নতুন হিসাব সংরক্ষণ করুন।'
                      : 'পণ্যের তালিকা ও খরচের তথ্য যোগ করুন। সব হিসাব থাকবে এক জায়গায়।',

                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.7,
                  ),
                ),

                const SizedBox(
                  height: 12,
                ),

                Container(
                  padding:
                  const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 7,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white
                        .withValues(alpha: 0.14),

                    borderRadius:
                    BorderRadius.circular(
                      10,
                    ),
                  ),

                  child: Row(
                    mainAxisSize:
                    MainAxisSize.min,

                    children: [
                      const Icon(
                        Icons
                            .verified_user_rounded,
                        color:
                        Colors.white,
                        size: 15,
                      ),

                      const SizedBox(
                        width: 6,
                      ),

                      Text(
                        isEditing
                            ? 'তথ্য নিরাপদে আপডেট করুন'
                            : 'সহজ ও গোছানো হিসাব',

                        style:
                        const TextStyle(
                          color:
                          Colors.white,
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(
            width: 12,
          ),

          Container(
            width: 68,
            height: 68,

            decoration: BoxDecoration(
              color: Colors.white
                  .withValues(alpha: 0.14),

              borderRadius:
              BorderRadius.circular(
                22,
              ),
            ),

            child: Icon(
              isEditing
                  ? Icons.edit_note_rounded
                  : Icons.shopping_cart_rounded,

              color: Colors.white,
              size: 36,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // LOADING STATE
  // ============================================================

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment:
        MainAxisAlignment.center,

        children: [
          Container(
            width: 70,
            height: 70,

            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,

              boxShadow: [
                BoxShadow(
                  color: Colors.black
                      .withValues(alpha: 0.05),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),

            child: const Padding(
              padding:
              EdgeInsets.all(21),

              child:
              CircularProgressIndicator(
                strokeWidth: 3,
                color: primary,
              ),
            ),
          ),

          const SizedBox(
            height: 18,
          ),

          const Text(
            'সদস্যদের তথ্য লোড হচ্ছে...',
            style: TextStyle(
              color: textDark,
              fontSize: 14,
              fontWeight:
              FontWeight.w700,
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
        padding:
        const EdgeInsets.all(28),

        child: Column(
          mainAxisSize:
          MainAxisSize.min,

          children: [
            Container(
              width: 95,
              height: 95,

              decoration: BoxDecoration(
                color:
                const Color(0xFFE8F7F5),

                borderRadius:
                BorderRadius.circular(
                  28,
                ),
              ),

              child: const Icon(
                Icons.groups_rounded,
                color: primary,
                size: 45,
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            const Text(
              'কোনো সদস্য পাওয়া যায়নি',
              textAlign:
              TextAlign.center,

              style: TextStyle(
                color: textDark,
                fontSize: 19,
                fontWeight:
                FontWeight.w900,
              ),
            ),

            const SizedBox(
              height: 8,
            ),

            const Text(
              'Firebase-এর members কালেকশনে সদস্যদের তথ্য আছে কি না পরীক্ষা করুন।',
              textAlign:
              TextAlign.center,

              style: TextStyle(
                color: textMuted,
                fontSize: 13,
                height: 1.6,
              ),
            ),

            const SizedBox(
              height: 22,
            ),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isFetchingMembers = true;
                });

                _fetchMembers();
              },

              icon: const Icon(
                Icons.refresh_rounded,
              ),

              label: const Text(
                'আবার চেষ্টা করুন',
              ),

              style:
              ElevatedButton.styleFrom(
                backgroundColor:
                primary,

                foregroundColor:
                Colors.white,

                elevation: 0,

                padding:
                const EdgeInsets
                    .symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),

                shape:
                RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(
                    14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BOTTOM BUTTON
  // ============================================================

  Widget _buildBottomButton() {
    final bool isEditing =
        widget.existingExpense != null;

    return Container(
      padding:
      const EdgeInsets.fromLTRB(
        16,
        12,
        16,
        14,
      ),

      decoration: BoxDecoration(
        color: Colors.white,

        border: const Border(
          top: BorderSide(
            color: border,
          ),
        ),

        boxShadow: [
          BoxShadow(
            color:
            Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset:
            const Offset(0, -5),
          ),
        ],
      ),

      child: SafeArea(
        top: false,

        child: SizedBox(
          width: double.infinity,
          height: 56,

          child: ElevatedButton(
            onPressed:
            _isLoading
                ? null
                : _submitExpense,

            style:
            ElevatedButton.styleFrom(
              backgroundColor:
              primary,

              disabledBackgroundColor:
              const Color(
                0xFF91BDB8,
              ),

              foregroundColor:
              Colors.white,

              disabledForegroundColor:
              Colors.white70,

              elevation: 0,

              shape:
              RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(
                  17,
                ),
              ),
            ),

            child: _isLoading
                ? const Row(
              mainAxisAlignment:
              MainAxisAlignment
                  .center,

              children: [
                SizedBox(
                  width: 21,
                  height: 21,

                  child:
                  CircularProgressIndicator(
                    color:
                    Colors.white,
                    strokeWidth:
                    2.5,
                  ),
                ),

                SizedBox(
                  width: 12,
                ),

                Text(
                  'খরচ সেভ হচ্ছে...',
                  style:
                  TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight
                        .w800,
                  ),
                ),
              ],
            )
                : Row(
              mainAxisAlignment:
              MainAxisAlignment
                  .center,

              children: [
                Icon(
                  isEditing
                      ? Icons
                      .system_update_alt_rounded
                      : Icons
                      .save_rounded,
                  size: 21,
                ),

                const SizedBox(
                  width: 9,
                ),

                Text(
                  isEditing
                      ? 'খরচ আপডেট করুন'
                      : 'খরচ সেভ করুন',

                  style:
                  const TextStyle(
                    fontSize: 15,
                    fontWeight:
                    FontWeight
                        .w800,
                  ),
                ),

                const SizedBox(
                  width: 8,
                ),

                const Icon(
                  Icons
                      .arrow_forward_rounded,
                  size: 19,
                ),
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
    _productsController.dispose();
    _amountController.dispose();

    super.dispose();
  }
}