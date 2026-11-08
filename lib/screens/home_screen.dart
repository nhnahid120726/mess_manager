import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/financial_service.dart';
import 'market_screen.dart';

/// ============================================================================
/// 🏠 মেস ম্যানেজার ড্যাশবোর্ড স্ক্রিন (HomeScreen)
/// ============================================================================
class HomeScreen extends StatefulWidget {
  final VoidCallback? onToggleModule;

  const HomeScreen({super.key, this.onToggleModule});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with AutomaticKeepAliveClientMixin<HomeScreen>, TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FinancialService _financialService = FinancialService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _userName = 'লোড হচ্ছে...';
  String _userRole = 'member';
  String _userEmail = '';
  String? _photoUrl;
  bool _isLoading = true;

  late AnimationController _headerAnimController;
  late AnimationController _cardsAnimController;
  late AnimationController _listAnimController;

  late Animation<double> _headerSlideAnim;
  late Animation<double> _headerFadeAnim;
  late Animation<double> _cardsFadeAnim;
  late Animation<double> _cardsSlideAnim;
  late Animation<double> _listFadeAnim;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchUserData();
  }

  void _setupAnimations() {
    // হেডার অ্যানিমেশন
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 900),
      vsync: this,
    );
    _headerSlideAnim = Tween<double>(begin: -60, end: 0).animate(
      CurvedAnimation(parent: _headerAnimController, curve: Curves.easeOutCubic),
    );
    _headerFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _headerAnimController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    // কার্ড অ্যানিমেশন
    _cardsAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _cardsFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _cardsAnimController, curve: Curves.easeOut),
    );
    _cardsSlideAnim = Tween<double>(begin: 40, end: 0).animate(
      CurvedAnimation(parent: _cardsAnimController, curve: Curves.easeOutCubic),
    );

    // লিস্ট অ্যানিমেশন
    _listAnimController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );
    _listFadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _listAnimController, curve: Curves.easeOut),
    );
  }

  void _startAnimations() {
    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _cardsAnimController.forward();
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) _listAnimController.forward();
    });
  }

  Future<void> _fetchUserData() async {
    final user = _authService.currentUser;
    if (user != null && user.email != null) {
      try {
        DocumentSnapshot doc =
        await _firestore.collection('members').doc(user.email).get();
        if (doc.exists && mounted) {
          setState(() {
            _userEmail = user.email!;
            _userName = doc['name'] ?? user.displayName ?? 'ব্যবহারকারী';
            _userRole = doc['role'] ?? 'member';
            _photoUrl = user.photoURL;
            _isLoading = false;
          });
          _startAnimations();
        }
      } catch (e) {
        if (mounted) {
          setState(() => _isLoading = false);
          _startAnimations();
        }
      }
    }
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _cardsAnimController.dispose();
    _listAnimController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildPulsingLoader(),
              const SizedBox(height: 20),
              const Text(
                'ড্যাশবোর্ড লোড হচ্ছে...',
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.surface,
        strokeWidth: 2.5,
        displacement: 60,
        onRefresh: () async {
          _headerAnimController.reset();
          _cardsAnimController.reset();
          _listAnimController.reset();
          await _fetchUserData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ১. অ্যানিমেটেড হেডার সেকশন
              AnimatedBuilder(
                animation: _headerAnimController,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _headerSlideAnim.value),
                    child: Opacity(
                      opacity: _headerFadeAnim.value,
                      child: child,
                    ),
                  );
                },
                child: _HeaderSection(
                  userName: _userName,
                  userRole: _userRole,
                  photoUrl: _photoUrl,
                  onLogout: () => _showLogoutDialog(context),
                  onToggleModule: widget.onToggleModule,
                ),
              ),

              // ২. অ্যানিমেটেড ফাইন্যান্সিয়াল ড্যাশবোর্ড
              if (_userEmail.isNotEmpty)
                AnimatedBuilder(
                  animation: _cardsAnimController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, _cardsSlideAnim.value),
                      child: Opacity(
                        opacity: _cardsFadeAnim.value,
                        child: child,
                      ),
                    );
                  },
                  child: _FinancialDashboard(
                    userEmail: _userEmail,
                    financialService: _financialService,
                  ),
                ),

              // ৩. অ্যানিমেটেড সাম্প্রতিক বাজার সেকশন
              AnimatedBuilder(
                animation: _listAnimController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _listFadeAnim.value,
                    child: child,
                  );
                },
                child: Column(
                  children: [
                    _RecentMarketHeader(
                      onViewAll: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const MarketScreen(),
                          ),
                        );
                      },
                    ),
                    if (_userEmail.isNotEmpty)
                      _RecentTransactions(firestore: _firestore),
                  ],
                ),
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPulsingLoader() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeInOut,
      builder: (context, value, child) {
        return Transform.scale(scale: value, child: child);
      },
      onEnd: () {},
      child: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1E3A8A), Color(0xFF2563EB)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: const Icon(
          Icons.maps_home_work_rounded,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Logout',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Center(
          child: ScaleTransition(
            scale: CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
            child: FadeTransition(
              opacity: animation,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 36),
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.15),
                      blurRadius: 30,
                      offset: const Offset(0, 15),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Icon(
                          Icons.logout_rounded,
                          color: AppColors.danger,
                          size: 28,
                        ),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'লগ আউট করবেন?',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'আপনি কি সত্যিই লগ আউট করতে চান?',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: _AnimatedDialogButton(
                              label: 'বাতিল',
                              isPrimary: false,
                              onTap: () => Navigator.pop(context),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _AnimatedDialogButton(
                              label: 'লগ আউট',
                              isPrimary: true,
                              onTap: () async {
                                Navigator.pop(context);
                                await _authService.signOut();
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        );
      },
    );
  }
}

// ============================================================================
// 🧩 সকল উইজেট কম্পোনেন্ট (Extracted Widgets)
// ============================================================================

/// ডায়ালগ বাটন অ্যানিমেটেড
class _AnimatedDialogButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _AnimatedDialogButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_AnimatedDialogButton> createState() => _AnimatedDialogButtonState();
}

class _AnimatedDialogButtonState extends State<_AnimatedDialogButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeInOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? const LinearGradient(
              colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
            )
                : null,
            color: widget.isPrimary ? null : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.isPrimary
                ? [
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.isPrimary ? Colors.white : AppColors.textPrimary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 👤 [Header Section] — প্রোফাইল, গ্রিটিং ও মডিউল সুইচার
class _HeaderSection extends StatelessWidget {
  final String userName;
  final String userRole;
  final String? photoUrl;
  final VoidCallback onLogout;
  final VoidCallback? onToggleModule;

  const _HeaderSection({
    required this.userName,
    required this.userRole,
    this.photoUrl,
    required this.onLogout,
    this.onToggleModule,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'শুভ রাত্রি';
    if (hour < 12) return 'সুপ্রভাত';
    if (hour < 17) return 'শুভ অপরাহ্ন';
    if (hour < 20) return 'শুভ সন্ধ্যা';
    return 'শুভ রাত্রি';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 5) return Icons.nightlight_round;
    if (hour < 12) return Icons.wb_sunny_rounded;
    if (hour < 17) return Icons.wb_cloudy_rounded;
    if (hour < 20) return Icons.wb_twilight_rounded;
    return Icons.nightlight_round;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(20, topInset + 14, 20, 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
            Color(0xFF2563EB),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.5, 1.0],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // টপ বার — লোগো ও লগ আউট
          Row(
            children: [
              _GlassIconBox(
                icon: Icons.maps_home_work_rounded,
                size: 42,
                iconSize: 21,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mess Manager',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: Color(0xFF4ADE80),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        const Text(
                          'মেসের সব হিসাব, এক জায়গায়',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              _GlassIconButton(
                icon: Icons.notifications_none_rounded,
                onTap: () {},
                tooltip: 'নোটিফিকেশন',
              ),
              const SizedBox(width: 8),
              _GlassIconButton(
                icon: Icons.logout_rounded,
                onTap: onLogout,
                tooltip: 'লগ আউট',
              ),
            ],
          ),

          const SizedBox(height: 28),

          // প্রোফাইল সেকশন
          Row(
            children: [
              // প্রোফাইল অ্যাভাটার — অ্যানিমেটেড বর্ডার
              _AnimatedAvatar(photoUrl: photoUrl),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _getGreetingIcon(),
                          color: const Color(0xFFFBBF24),
                          size: 15,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _getGreeting(),
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFFCBD5E1),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 6),
                    _RoleBadge(role: userRole),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // ব্যক্তিগত ওয়ালেট সুইচার বাটন
              _ModuleSwitcher(onTap: onToggleModule),
            ],
          ),
        ],
      ),
    );
  }
}

/// গ্লাস মর্ফিজম আইকন বক্স
class _GlassIconBox extends StatelessWidget {
  final IconData icon;
  final double size;
  final double iconSize;

  const _GlassIconBox({
    required this.icon,
    this.size = 42,
    this.iconSize = 21,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Icon(icon, color: Colors.white, size: iconSize),
    );
  }
}

/// গ্লাস মর্ফিজম আইকন বাটন
class _GlassIconButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  const _GlassIconButton({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  @override
  State<_GlassIconButton> createState() => _GlassIconButtonState();
}

class _GlassIconButtonState extends State<_GlassIconButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: Tooltip(
        message: widget.tooltip,
        child: AnimatedScale(
          scale: _pressed ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _pressed ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 19),
          ),
        ),
      ),
    );
  }
}

/// অ্যানিমেটেড প্রোফাইল অ্যাভাটার (গ্লোইং বর্ডার)
class _AnimatedAvatar extends StatefulWidget {
  final String? photoUrl;
  const _AnimatedAvatar({this.photoUrl});

  @override
  State<_AnimatedAvatar> createState() => _AnimatedAvatarState();
}

class _AnimatedAvatarState extends State<_AnimatedAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowController,
      builder: (context, child) {
        final glowOpacity = 0.15 + (_glowController.value * 0.2);
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withValues(alpha: glowOpacity + 0.15),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF60A5FA).withValues(alpha: glowOpacity),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: child,
        );
      },
      child: CircleAvatar(
        radius: 28,
        backgroundColor: const Color(0xFFE0E7FF),
        backgroundImage:
        widget.photoUrl != null ? NetworkImage(widget.photoUrl!) : null,
        child: widget.photoUrl == null
            ? const Icon(Icons.person_rounded, size: 28, color: Color(0xFF3B82F6))
            : null,
      ),
    );
  }
}

/// রোল ব্যাজ — গ্লাস ইফেক্ট
class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isManager = role.toLowerCase() == 'manager';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isManager
              ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
              : [Colors.white.withValues(alpha: 0.15), Colors.white.withValues(alpha: 0.08)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isManager
              ? const Color(0xFFFBBF24).withValues(alpha: 0.5)
              : Colors.white.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isManager) ...[
            const Icon(Icons.star_rounded, size: 11, color: Color(0xFF78350F)),
            const SizedBox(width: 3),
          ],
          Text(
            role.toUpperCase(),
            style: TextStyle(
              color: isManager ? const Color(0xFF78350F) : Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

/// মডিউল সুইচার বাটন (ব্যক্তিগত ওয়ালেটে যাওয়ার বাটন)
class _ModuleSwitcher extends StatefulWidget {
  final VoidCallback? onTap;
  const _ModuleSwitcher({this.onTap});

  @override
  State<_ModuleSwitcher> createState() => _ModuleSwitcherState();
}

class _ModuleSwitcherState extends State<_ModuleSwitcher>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null) return const SizedBox.shrink();

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.9 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (context, child) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withValues(alpha: 0.12 + _pulseController.value * 0.06),
                    Colors.white.withValues(alpha: 0.06 + _pulseController.value * 0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.white.withValues(
                    alpha: 0.15 + _pulseController.value * 0.1,
                  ),
                ),
              ),
              child: child,
            );
          },
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_balance_wallet_rounded,
                  color: Colors.white, size: 22),
              SizedBox(height: 5),
              Text(
                'ব্যক্তিগত',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 📊 [Financial Dashboard] — ক্যাশ, ব্যালেন্স ও খরচ
class _FinancialDashboard extends StatelessWidget {
  final String userEmail;
  final FinancialService financialService;

  const _FinancialDashboard({
    required this.userEmail,
    required this.financialService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>>(
      stream: financialService.getFinancialSummary(userEmail),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            !snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 2.5,
              ),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final totalExpense = (data['totalExpense'] ?? 0.0) as double;
        final messCashBalance = (data['messCashBalance'] ?? 0.0) as double;
        final myNetBalance = (data['myNetBalance'] ?? 0.0) as double;
        final todayExpense = (data['todayExpense'] ?? 0.0) as double;
        final myTodayAllocatedExpense =
        (data['myTodayAllocatedExpense'] ?? 0.0) as double;
        final myAllocatedExpense =
        (data['myAllocatedExpense'] ?? 0.0) as double;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
          child: Column(
            children: [
              // দুইটি ব্যালেন্স কার্ড
              Row(
                children: [
                  Expanded(
                    child: _BalanceCard(
                      title: 'মেস ফান্ড ক্যাশ',
                      amount: messCashBalance,
                      icon: Icons.account_balance_wallet_rounded,
                      iconColor: const Color(0xFF059669),
                      bgGradient: const [Color(0xFFD1FAE5), Color(0xFFECFDF5)],
                      borderColor: const Color(0xFFA7F3D0),
                      trendIcon: Icons.trending_up_rounded,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _BalanceCard(
                      title: 'আমার ব্যালেন্স',
                      amount: myNetBalance,
                      icon: Icons.person_rounded,
                      iconColor: myNetBalance >= 0
                          ? const Color(0xFF2563EB)
                          : AppColors.danger,
                      bgGradient: myNetBalance >= 0
                          ? const [Color(0xFFDBEAFE), Color(0xFFEFF6FF)]
                          : const [Color(0xFFFEE2E2), Color(0xFFFEF2F2)],
                      borderColor: myNetBalance >= 0
                          ? const Color(0xFFBFDBFE)
                          : const Color(0xFFFECACA),
                      trendIcon: myNetBalance >= 0
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // বড় এক্সপেন্স কার্ড
              _ExpenseCard(
                totalExpense: totalExpense,
                myAllocatedExpense: myAllocatedExpense,
                todayExpense: todayExpense,
                myTodayAllocatedExpense: myTodayAllocatedExpense,
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 💳 [Balance Card] — ছোট ব্যালেন্স কার্ড (গ্রেডিয়েন্ট ব্যাকগ্রাউন্ড)
class _BalanceCard extends StatefulWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color iconColor;
  final List<Color> bgGradient;
  final Color borderColor;
  final IconData trendIcon;

  const _BalanceCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.iconColor,
    required this.bgGradient,
    required this.borderColor,
    required this.trendIcon,
  });

  @override
  State<_BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<_BalanceCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeInOut,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: widget.borderColor.withValues(alpha: 0.5)),
            boxShadow: [
              BoxShadow(
                color: widget.iconColor.withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: widget.bgGradient,
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(widget.icon, color: widget.iconColor, size: 19),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: widget.iconColor.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      widget.trendIcon,
                      color: widget.iconColor.withValues(alpha: 0.6),
                      size: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: _AnimatedCounter(
                  amount: widget.amount,
                  color: widget.amount < 0
                      ? AppColors.danger
                      : AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// অ্যানিমেটেড কাউন্টার টেক্সট — সংখ্যা পরিবর্তনে স্মুথ ট্রানজিশন
class _AnimatedCounter extends StatelessWidget {
  final double amount;
  final Color color;

  const _AnimatedCounter({required this.amount, required this.color});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: amount),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Text(
          '৳ ${value.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: color,
            letterSpacing: -0.5,
          ),
        );
      },
    );
  }
}

/// 📈 [Expense Card] — চলতি মাসের মোট খরচ (প্রিমিয়াম ডিজাইন)
class _ExpenseCard extends StatelessWidget {
  final double totalExpense;
  final double myAllocatedExpense;
  final double todayExpense;
  final double myTodayAllocatedExpense;

  const _ExpenseCard({
    required this.totalExpense,
    required this.myAllocatedExpense,
    required this.todayExpense,
    required this.myTodayAllocatedExpense,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F172A),
            Color(0xFF1E3A8A),
            Color(0xFF1D4ED8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E3A8A).withValues(alpha: 0.35),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ডেকোরেটিভ সার্কেল
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: 30,
            bottom: -10,
            child: Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.03),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // টাইটেল বার
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.analytics_rounded,
                        color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'চলতি মাসের মোট খরচ',
                          style: TextStyle(
                            color: Color(0xFFCBD5E1),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'সকল সদস্যের মোট ব্যয়',
                          style: TextStyle(
                            color: Color(0xFF94A3B8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.arrow_outward_rounded,
                            color: Color(0xFF4ADE80), size: 12),
                        SizedBox(width: 3),
                        Text(
                          'Live',
                          style: TextStyle(
                            color: Color(0xFF4ADE80),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),

              // মোট অ্যামাউন্ট
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: totalExpense),
                duration: const Duration(milliseconds: 1500),
                curve: Curves.easeOutCubic,
                builder: (context, value, _) {
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '৳ ${value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -1.0,
                        height: 1.1,
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),

              // মিনি স্ট্যাট গ্রিড
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border:
                  Border.all(color: Colors.white.withValues(alpha: 0.08)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _MiniStatChip(
                            icon: Icons.pie_chart_rounded,
                            label: 'আমার মোট ভাগ',
                            value: '৳ ${myAllocatedExpense.toStringAsFixed(2)}',
                            chipColor: const Color(0xFF8B5CF6),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _MiniStatChip(
                            icon: Icons.shopping_bag_rounded,
                            label: 'আজকের বাজার',
                            value: '৳ ${todayExpense.toStringAsFixed(2)}',
                            chipColor: const Color(0xFFF59E0B),
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(
                        height: 1,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    _MiniStatChip(
                      icon: Icons.today_rounded,
                      label: 'আজ আমার ভাগ',
                      value:
                      '৳ ${myTodayAllocatedExpense.toStringAsFixed(2)}',
                      chipColor: const Color(0xFF06B6D4),
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
}

/// 📌 [Mini Stat Chip] — কালারফুল চিপ ডিজাইন
class _MiniStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color chipColor;

  const _MiniStatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.chipColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: chipColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Icon(icon, color: chipColor, size: 12),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFFCBD5E1),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
            ),
          ),
        ),
      ],
    );
  }
}

/// সাম্প্রতিক বাজার হেডার
class _RecentMarketHeader extends StatelessWidget {
  final VoidCallback onViewAll;
  const _RecentMarketHeader({required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 16, 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFEDE9FE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFF7C3AED),
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'সাম্প্রতিক বাজার',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'মেসের সর্বশেষ কেনাকাটার হিসাব',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.8),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          _ViewAllButton(onTap: onViewAll),
        ],
      ),
    );
  }
}

/// "সব দেখুন" বাটন
class _ViewAllButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ViewAllButton({required this.onTap});

  @override
  State<_ViewAllButton> createState() => _ViewAllButtonState();
}

class _ViewAllButtonState extends State<_ViewAllButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.92 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE)),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'সব দেখুন',
                style: TextStyle(
                  color: Color(0xFF2563EB),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward_rounded,
                  size: 14, color: Color(0xFF2563EB)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🛒 [Recent Transactions] — রিয়েল-টাইম সাম্প্রতিক বাজার স্ট্রিম
class _RecentTransactions extends StatelessWidget {
  final FirebaseFirestore firestore;
  const _RecentTransactions({required this.firestore});

  // প্রতিটি আইটেমের জন্য ইউনিক কালার সেট
  static const List<_TransactionTheme> _themes = [
    _TransactionTheme(
      icon: Icons.shopping_basket_rounded,
      iconColor: Color(0xFF8B5CF6),
      bgColor: Color(0xFFEDE9FE),
      accentColor: Color(0xFFA78BFA),
    ),
    _TransactionTheme(
      icon: Icons.local_grocery_store_rounded,
      iconColor: Color(0xFFF59E0B),
      bgColor: Color(0xFFFEF3C7),
      accentColor: Color(0xFFFBBF24),
    ),
    _TransactionTheme(
      icon: Icons.storefront_rounded,
      iconColor: Color(0xFF06B6D4),
      bgColor: Color(0xFFCFFAFE),
      accentColor: Color(0xFF22D3EE),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: StreamBuilder<QuerySnapshot>(
        stream: firestore
            .collection('expenses')
            .orderBy('createdAt', descending: true)
            .limit(3)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting &&
              !snapshot.hasData) {
            return _buildShimmerLoader();
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState();
          }

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.04),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: ListView.separated(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: snapshot.data!.docs.length,
                separatorBuilder: (context, itemIndex) => Padding(
                  key: ValueKey('sep_$itemIndex'),
                  padding: const EdgeInsets.only(left: 74),
                  child: Divider(
                    height: 1,
                    color: const Color(0xFFE2E8F0).withValues(alpha: 0.7),
                  ),
                ),
                itemBuilder: (context, index) {
                  final doc = snapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;
                  final theme = _themes[index % _themes.length];

                  return _TransactionTile(
                    data: data,
                    theme: theme,
                    index: index,
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildShimmerLoader() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: List.generate(
          3,
              (i) => Padding(
            padding: EdgeInsets.only(bottom: i < 2 ? 16 : 0),
            child: Row(
              children: [
                _ShimmerBox(width: 46, height: 46, borderRadius: 16),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _ShimmerBox(
                          width: 120, height: 12, borderRadius: 6),
                      const SizedBox(height: 8),
                      _ShimmerBox(
                          width: 80, height: 10, borderRadius: 5),
                    ],
                  ),
                ),
                _ShimmerBox(width: 60, height: 14, borderRadius: 7),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.receipt_long_rounded,
              color: Color(0xFFCBD5E1),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'এখনও কোনো বাজারের হিসাব নেই',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'নতুন কেনাকাটা যোগ হলে এখানে দেখা যাবে',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// ট্রানজেকশন থিম ডেটা ক্লাস
class _TransactionTheme {
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
  final Color accentColor;

  const _TransactionTheme({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    required this.accentColor,
  });
}

/// প্রতিটি ট্রানজেকশন আইটেম — অ্যানিমেটেড টাইল
class _TransactionTile extends StatefulWidget {
  final Map<String, dynamic> data;
  final _TransactionTheme theme;
  final int index;

  const _TransactionTile({
    required this.data,
    required this.theme,
    required this.index,
  });

  @override
  State<_TransactionTile> createState() => _TransactionTileState();
}

class _TransactionTileState extends State<_TransactionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _slideController;
  late Animation<Offset> _slideAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _slideController = AnimationController(
      duration: Duration(milliseconds: 500 + (widget.index * 100)),
      vsync: this,
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOut),
    );

    Future.delayed(Duration(milliseconds: widget.index * 120), () {
      if (mounted) _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = widget.data['products'] as List<dynamic>? ?? [];
    final amount = ((widget.data['totalAmountInPaisa'] ?? 0) as num) / 100;
    final purchaser =
    (widget.data['purchasedByEmail'] ?? '').toString().split('@')[0];

    // তারিখ ফরম্যাট
    String dateStr = '';
    if (widget.data['createdAt'] != null) {
      final timestamp = widget.data['createdAt'] as Timestamp;
      final date = timestamp.toDate();
      final now = DateTime.now();
      final diff = now.difference(date);

      if (diff.inMinutes < 60) {
        dateStr = '${diff.inMinutes} মিনিট আগে';
      } else if (diff.inHours < 24) {
        dateStr = '${diff.inHours} ঘণ্টা আগে';
      } else if (diff.inDays < 7) {
        dateStr = '${diff.inDays} দিন আগে';
      } else {
        dateStr = '${date.day}/${date.month}/${date.year}';
      }
    }

    return SlideTransition(
      position: _slideAnim,
      child: FadeTransition(
        opacity: _fadeAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // আইকন
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: widget.theme.bgColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(widget.theme.icon,
                    color: widget.theme.iconColor, size: 21),
              ),
              const SizedBox(width: 12),

              // তথ্য
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      products.isEmpty ? 'বাজারের খরচ' : products.join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Icon(Icons.person_outline_rounded,
                            size: 12,
                            color:
                            AppColors.textSecondary.withValues(alpha: 0.7)),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            purchaser.isEmpty ? 'সদস্য' : purchaser,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.8),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        if (dateStr.isNotEmpty) ...[
                          Container(
                            width: 3,
                            height: 3,
                            decoration: BoxDecoration(
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.4),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            dateStr,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.textSecondary
                                  .withValues(alpha: 0.65),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),

              // অ্যামাউন্ট
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: const Color(0xFFFECACA).withValues(alpha: 0.6)),
                ),
                child: Text(
                  '-৳${amount.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: Color(0xFFDC2626),
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    letterSpacing: -0.3,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// শিমার লোডিং বক্স
class _ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double borderRadius;

  const _ShimmerBox({
    required this.width,
    required this.height,
    required this.borderRadius,
  });

  @override
  State<_ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<_ShimmerBox>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(widget.borderRadius),
            color: Color.lerp(
              const Color(0xFFE2E8F0),
              const Color(0xFFF1F5F9),
              _controller.value,
            ),
          ),
        );
      },
    );
  }
}

/// AnimatedBuilder হেল্পার (Flutter-এর AnimatedBuilder-এর মতো)
class AnimatedBuilder extends AnimatedWidget {
  final Widget Function(BuildContext context, Widget? child) builder;
  final Widget? child;

  const AnimatedBuilder({
    super.key,
    required Animation<double> animation,
    required this.builder,
    this.child,
  }) : super(listenable: animation);

  @override
  Widget build(BuildContext context) {
    return builder(context, child);
  }
}