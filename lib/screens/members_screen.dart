import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../services/financial_service.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen>
    with AutomaticKeepAliveClientMixin<MembersScreen>, TickerProviderStateMixin {
  final FinancialService _financialService = FinancialService();

  // ── Animations ──
  late AnimationController _headerCtrl;
  late Animation<double> _headerFade;
  late Animation<Offset> _headerSlide;

  late AnimationController _counterCtrl;
  late Animation<double> _counterAnim;

  late AnimationController _pulseCtrl;
  late Animation<double> _pulseAnim;

  late AnimationController _shimmerCtrl;

  int _memberCount = 0;
  int _displayCount = 0;

  // ── Card Themes ──
  static const List<_CardAccent> _accents = [
    _CardAccent(stripe: Color(0xFF8B5CF6), icon: Color(0xFF8B5CF6), bg: Color(0xFFEDE9FE)),
    _CardAccent(stripe: Color(0xFFF59E0B), icon: Color(0xFFF59E0B), bg: Color(0xFFFEF3C7)),
    _CardAccent(stripe: Color(0xFF06B6D4), icon: Color(0xFF06B6D4), bg: Color(0xFFCFFAFE)),
    _CardAccent(stripe: Color(0xFF10B981), icon: Color(0xFF10B981), bg: Color(0xFFD1FAE5)),
    _CardAccent(stripe: Color(0xFFEC4899), icon: Color(0xFFEC4899), bg: Color(0xFFFCE7F3)),
    _CardAccent(stripe: Color(0xFF2563EB), icon: Color(0xFF2563EB), bg: Color(0xFFDBEAFE)),
  ];

  static const _CardAccent _adminAccent = _CardAccent(
    stripe: Color(0xFFF59E0B),
    icon: Color(0xFFF59E0B),
    bg: Color(0xFFFEF3C7),
  );

  // ── Navy Palette ──
  static const Color _navyDeep = Color(0xFF0F172A);
  static const Color _navyMid = Color(0xFF1E3A8A);
  static const Color _navyLight = Color(0xFF2563EB);
  static const Color _navyAccent = Color(0xFF3B82F6);
  static const Color _pageBg = Color(0xFFF0F4F8);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();

    _headerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _headerFade = CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic);
    _headerSlide = Tween<Offset>(begin: const Offset(0, -0.4), end: Offset.zero)
        .animate(CurvedAnimation(parent: _headerCtrl, curve: Curves.easeOutCubic));

    _counterCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _counterAnim = CurvedAnimation(parent: _counterCtrl, curve: Curves.easeOutCubic);
    _counterAnim.addListener(() {
      if (mounted) {
        setState(() {
          _displayCount = (_counterAnim.value * _memberCount).round();
        });
      }
    });

    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 2500));
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12)
        .animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

    _shimmerCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));

    _headerCtrl.forward();
    _pulseCtrl.repeat(reverse: true);
    _shimmerCtrl.repeat();
  }

  @override
  void dispose() {
    _headerCtrl.dispose();
    _counterCtrl.dispose();
    _pulseCtrl.dispose();
    _shimmerCtrl.dispose();
    super.dispose();
  }

  void _animateCount(int count) {
    if (_memberCount != count) {
      _memberCount = count;
      _counterCtrl.reset();
      _counterCtrl.forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: _pageBg,
      body: SafeArea(
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _financialService.getAllMembersBalances(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting && !snapshot.hasData) {
              return Column(
                children: [
                  _buildFixedHeader(0),
                  Expanded(child: _buildShimmerList()),
                ],
              );
            }

            if (snapshot.hasError) {
              return Column(
                children: [
                  _buildFixedHeader(0),
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline_rounded, size: 56, color: Colors.red.shade300),
                          const SizedBox(height: 12),
                          Text(
                            'সদস্য তথ্য লোড করতে সমস্যা হয়েছে',
                            style: TextStyle(fontSize: 14, color: Colors.red.shade400, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Column(
                children: [
                  _buildFixedHeader(0),
                  Expanded(child: _buildEmptyState()),
                ],
              );
            }

            final members = snapshot.data!;
            _animateCount(members.length);

            return Column(
              children: [
                _buildFixedHeader(members.length),
                Expanded(
                  child: RefreshIndicator(
                    color: _navyLight,
                    backgroundColor: Colors.white,
                    onRefresh: () async {
                      setState(() {});
                      await Future.delayed(const Duration(milliseconds: 600));
                    },
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                      itemCount: members.length,
                      itemBuilder: (context, index) {
                        return _buildMemberCard(members[index], index, members.length);
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  FIXED HEADER
  // ═══════════════════════════════════════════
  Widget _buildFixedHeader(int count) {
    return FadeTransition(
      opacity: _headerFade,
      child: SlideTransition(
        position: _headerSlide,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Title Row ──
              Row(
                children: [
                  // Glowing Icon
                  AnimatedBuilder(
                    listenable: _pulseAnim,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnim.value,
                        child: Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.25), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: _navyAccent.withValues(alpha: 0.3 * _pulseAnim.value),
                                blurRadius: 12 * _pulseAnim.value,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.groups_rounded, color: Colors.white, size: 24),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'মেসের সদস্যবৃন্দ',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'মেসের সকল সদস্যদের তালিকা ও ব্যালেন্স',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.white.withValues(alpha: 0.65),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              // ── Stats Row ──
              Row(
                children: [
                  // Member Count Badge
                  AnimatedBuilder(
                    animation: _pulseAnim,
                    builder: (context, child) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.12 + 0.04 * _pulseAnim.value),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.2), width: 1),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_rounded, size: 16, color: Colors.white.withValues(alpha: 0.9)),
                            const SizedBox(width: 6),
                            Text(
                              '$_displayCount / 8',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'জন',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.7),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(width: 10),

                  // Admin Count
                  _buildHeaderStat(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'অ্যাডমিন',
                    color: const Color(0xFFF59E0B),
                  ),

                  const Spacer(),

                  // Decorative dots
                  Row(
                    children: List.generate(3, (i) {
                      return Container(
                        margin: const EdgeInsets.only(left: 4),
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15 + 0.1 * i),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderStat({required IconData icon, required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  MEMBER CARD
  // ═══════════════════════════════════════════
  Widget _buildMemberCard(Map<String, dynamic> member, int index, int total) {
    final double balance = member['netBalance'] as double? ?? 0.0;
    final bool isAdmin = member['role'] == 'admin';
    final bool isPositive = balance >= 0;
    final String name = member['name'] as String? ?? 'অজানা';
    final String email = member['email'] as String? ?? '';
    final int meals = member['meals'] as int? ?? 30;

    final accent = isAdmin ? _adminAccent : _accents[index % _accents.length];
    final delay = index * 70;

    return AnimatedBuilder(
      animation: _headerCtrl,
      builder: (context, child) {
        final t = Curves.easeOutCubic.transform(
          ((_headerCtrl.value * 900 - delay) / 500).clamp(0.0, 1.0),
        );
        return Transform.translate(
          offset: Offset(0, 30 * (1 - t)),
          child: Opacity(
            opacity: t,
            child: child,
          ),
        );
      },
      child: _TapScaleButton(
        onTap: () {},
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
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
          child: IntrinsicHeight(
            child: Row(
              children: [
                // ── Left Accent Stripe ──
                Container(
                  width: 5,
                  decoration: BoxDecoration(
                    color: isAdmin ? const Color(0xFFF59E0B) : accent.stripe,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    ),
                  ),
                ),

                // ── Card Content ──
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 16, 14),
                    child: Row(
                      children: [
                        // ── Glowing Avatar ──
                        _GlowingAvatar(
                          isAdmin: isAdmin,
                          accentColor: isAdmin ? const Color(0xFFF59E0B) : accent.icon,
                          pulseAnim: _pulseAnim,
                          name: name,
                        ),
                        const SizedBox(width: 14),

                        // ── Details ──
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Name + Admin Badge
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15,
                                        color: _navyDeep,
                                        letterSpacing: -0.2,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  if (isAdmin) ...[
                                    const SizedBox(width: 6),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                                        ),
                                        borderRadius: BorderRadius.circular(6),
                                        boxShadow: [
                                          BoxShadow(
                                            color: const Color(0x33F59E0B),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.verified_rounded, size: 10, color: Colors.white),
                                          SizedBox(width: 2),
                                          Text(
                                            'অ্যাডমিন',
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.3,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                              const SizedBox(height: 3),

                              // Email
                              Text(
                                email,
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 8),

                              // Meal Count
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: accent.bg,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.restaurant_rounded, size: 12, color: accent.icon),
                                    const SizedBox(width: 4),
                                    Text(
                                      'মিল: $meals',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: accent.icon,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 8),

                        // ── Balance ──
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Amount
                            Text(
                              isPositive
                                  ? '+ ৳${balance.toStringAsFixed(0)}'
                                  : '- ৳${balance.abs().toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: isPositive ? const Color(0xFF059669) : const Color(0xFFDC2626),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),

                            // Status Badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: isPositive
                                    ? const Color(0xFFD1FAE5)
                                    : const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isPositive
                                      ? const Color(0xFFA7F3D0)
                                      : const Color(0xFFFECACA),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: BoxDecoration(
                                      color: isPositive
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFDC2626),
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isPositive ? 'পাওনা' : 'দেনা',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      color: isPositive
                                          ? const Color(0xFF059669)
                                          : const Color(0xFFDC2626),
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  //  SHIMMER LOADING
  // ═══════════════════════════════════════════
  Widget _buildShimmerList() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: 5,
      itemBuilder: (context, index) {
        return AnimatedBuilder(
          animation: _shimmerCtrl,
          builder: (context, child) {
            final shimmerValue = _shimmerCtrl.value;
            final opacity = 0.3 + 0.3 * math.sin(shimmerValue * 2 * math.pi + index * 0.5);
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200.withValues(alpha: opacity),
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200.withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(7),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          width: 160,
                          height: 10,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200.withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          width: 70,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200.withValues(alpha: opacity),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        width: 70,
                        height: 18,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: 50,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200.withValues(alpha: opacity),
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  //  EMPTY STATE
  // ═══════════════════════════════════════════
  Widget _buildEmptyState() {
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
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: _navyLight.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: _navyLight.withValues(alpha: 0.15), width: 2),
                  ),
                  child: Icon(
                    Icons.person_off_rounded,
                    size: 42,
                    color: _navyLight.withValues(alpha: 0.5),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          const Text(
            'কোনো সদস্য পাওয়া যায়নি',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _navyDeep,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'মেসে এখনো কোনো সদস্য যোগ হয়নি',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
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

class _GlowingAvatar extends StatelessWidget {
  final bool isAdmin;
  final Color accentColor;
  final Animation<double> pulseAnim;
  final String name;

  const _GlowingAvatar({
    required this.isAdmin,
    required this.accentColor,
    required this.pulseAnim,
    required this.name,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return AnimatedBuilder(
      animation: pulseAnim,
      builder: (context, child) {
        return Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isAdmin
                  ? [const Color(0xFFFDE68A), const Color(0xFFF59E0B)]
                  : [accentColor.withValues(alpha: 0.2), accentColor.withValues(alpha: 0.08)],
            ),
            border: Border.all(
              color: isAdmin
                  ? const Color(0xFFF59E0B).withValues(alpha: 0.5)
                  : accentColor.withValues(alpha: 0.25),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.2 * pulseAnim.value),
                blurRadius: 10 * pulseAnim.value,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: isAdmin
                ? const Icon(Icons.admin_panel_settings_rounded, color: Color(0xFFD97706), size: 26)
                : Text(
              initial,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: accentColor,
              ),
            ),
          ),
        );
      },
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