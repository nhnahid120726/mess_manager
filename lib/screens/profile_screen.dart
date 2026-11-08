import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import 'admin_panel_screen.dart';
import 'mess_reports_screen.dart';

/// ============================================================================
/// 👤 প্রোফাইল স্ক্রিন (ProfileScreen) — Premium Edition
/// ============================================================================
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _userName = 'Loading...';
  String _userEmail = '';
  String _userRole = 'member';
  String? _photoUrl;

  bool _isLoading = true;
  String? _errorMessage;

  // HomeScreen/MarketScreen-এর সাথে ম্যাচিং Navy Blue প্যালেট
  static const Color navyDeep = Color(0xFF0F172A);
  static const Color navyMid = Color(0xFF1E3A8A);
  static const Color navyLight = Color(0xFF2563EB);

  static const Color dark = AppColors.textPrimary;
  static const Color muted = AppColors.textSecondary;
  static const Color pageBg = AppColors.background;
  static const Color danger = AppColors.danger;

  // অ্যানিমেশন কন্ট্রোলার
  late AnimationController _headerAnimController;
  late AnimationController _contentAnimController;
  late Animation<double> _headerFadeAnim;
  late Animation<double> _contentFadeAnim;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _fetchUserData();
  }

  void _setupAnimations() {
    _headerAnimController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _contentAnimController = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _headerFadeAnim = CurvedAnimation(
      parent: _headerAnimController,
      curve: Curves.easeOut,
    );
    _contentFadeAnim = CurvedAnimation(
      parent: _contentAnimController,
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _headerAnimController.dispose();
    _contentAnimController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = _authService.currentUser;

      if (user == null || user.email == null) {
        if (!mounted) return;
        setState(() {
          _userName = 'Guest User';
          _userEmail = '';
          _userRole = 'member';
          _photoUrl = null;
          _isLoading = false;
        });
        _startAnimations();
        return;
      }

      final email = user.email!;
      final photo = user.photoURL;
      final displayName = user.displayName;

      final DocumentSnapshot<Map<String, dynamic>> doc =
      await _firestore.collection('members').doc(email).get();

      final data = doc.data();
      final name = data?['name']?.toString().trim();
      final role = data?['role']?.toString().trim();

      if (!mounted) return;

      setState(() {
        _userEmail = email;
        _userName = (name != null && name.isNotEmpty)
            ? name
            : ((displayName != null && displayName.isNotEmpty)
            ? displayName
            : 'User');
        _userRole = (role != null && role.isNotEmpty)
            ? role.toLowerCase()
            : 'member';
        _photoUrl = photo;
        _isLoading = false;
      });
      _startAnimations();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'প্রোফাইল লোড করা যায়নি। আবার চেষ্টা করুন।';
      });
      _startAnimations();
    }
  }

  void _startAnimations() {
    _headerAnimController.forward();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _contentAnimController.forward();
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = _authService.currentUser;
    final String firebaseUid = user?.uid ?? 'N/A';
    final bool isEmailVerified = user?.emailVerified ?? false;

    String provider = 'Unknown';
    String providerUid = 'N/A';
    if (user != null && user.providerData.isNotEmpty) {
      final providerInfo = user.providerData.first;
      provider = providerInfo.providerId;
    }

    return Scaffold(
      backgroundColor: pageBg,
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage != null
          ? _buildErrorView()
          : RefreshIndicator(
        color: navyLight,
        backgroundColor: Colors.white,
        strokeWidth: 2.5,
        onRefresh: () async {
          _headerAnimController.reset();
          _contentAnimController.reset();
          await _fetchUserData();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          padding: const EdgeInsets.only(bottom: 110),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ১. প্রোফাইল হেডার
              FadeTransition(
                opacity: _headerFadeAnim,
                child: _buildProfileHeader(),
              ),

              const SizedBox(height: 24),

              // ২. কন্টেন্ট সেকশন
              FadeTransition(
                opacity: _contentFadeAnim,
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // অ্যাকাউন্ট তথ্য সেকশন
                      _SectionTitle(
                        title: 'অ্যাকাউন্টের তথ্য',
                        subtitle: 'আপনার অ্যাকাউন্টের বিস্তারিত',
                        icon: Icons.account_circle_rounded,
                        iconColor: navyLight,
                        bgColor: const Color(0xFFDBEAFE),
                      ),
                      const SizedBox(height: 12),

                      _InfoCard(
                        children: [
                          _AnimatedInfoTile(
                            index: 0,
                            icon: Icons.login_rounded,
                            iconColor: const Color(0xFF4285F4),
                            iconBg: const Color(0xFFDBEAFE),
                            title: 'লগইন মাধ্যম',
                            subtitle: provider == 'google.com'
                                ? 'গুগল অ্যাকাউন্ট'
                                : provider,
                          ),
                          const _InfoDivider(),
                          _AnimatedInfoTile(
                            index: 1,
                            icon: Icons.fingerprint_rounded,
                            iconColor: const Color(0xFF8B5CF6),
                            iconBg: const Color(0xFFEDE9FE),
                            title: 'ফায়ারবেস আইডি',
                            subtitle: firebaseUid,
                          ),
                          const _InfoDivider(),
                          _AnimatedInfoTile(
                            index: 2,
                            icon: Icons.tag_rounded,
                            iconColor: const Color(0xFF06B6D4),
                            iconBg: const Color(0xFFCFFAFE),
                            title: 'গুগল আইডি',
                            subtitle: providerUid,
                          ),
                          const _InfoDivider(),
                          _AnimatedActionTile(
                            index: 3,
                            icon: Icons.receipt_long_rounded,
                            iconColor: const Color(0xFF1E3A8A),
                            iconBg: const Color(0xFFDBEAFE),
                            title: 'আমার মেস রিপোর্ট ও CSV/ইমেজ',
                            subtitle:
                            'আমার জমা ও বাজার খরচের বিস্তারিত ইতিহাস',
                            onTap: () {
                              Navigator.push(
                                context,
                                PageRouteBuilder(
                                  pageBuilder: (_, _, _) =>
                                  const MessReportsScreen(),
                                  transitionsBuilder:
                                      (_, anim, _, child) {
                                    return FadeTransition(
                                      opacity: anim,
                                      child: SlideTransition(
                                        position: Tween<Offset>(
                                          begin: const Offset(0.1, 0),
                                          end: Offset.zero,
                                        ).animate(CurvedAnimation(
                                          parent: anim,
                                          curve: Curves.easeOutCubic,
                                        )),
                                        child: child,
                                      ),
                                    );
                                  },
                                ),
                              );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // নিরাপত্তা সেকশন
                      _SectionTitle(
                        title: 'নিরাপত্তা',
                        subtitle: 'অ্যাকাউন্টের নিরাপত্তা তথ্য',
                        icon: Icons.shield_rounded,
                        iconColor: const Color(0xFF10B981),
                        bgColor: const Color(0xFFD1FAE5),
                      ),
                      const SizedBox(height: 12),

                      _InfoCard(
                        children: [
                          _AnimatedInfoTile(
                            index: 4,
                            icon: isEmailVerified
                                ? Icons.mark_email_read_rounded
                                : Icons.mark_email_unread_rounded,
                            iconColor: isEmailVerified
                                ? const Color(0xFF10B981)
                                : danger,
                            iconBg: isEmailVerified
                                ? const Color(0xFFD1FAE5)
                                : const Color(0xFFFEE2E2),
                            title: 'ইমেইল ভেরিফিকেশন',
                            subtitle: isEmailVerified
                                ? 'ভেরিফায়েড অ্যাকাউন্ট'
                                : 'ভেরিফাই করা হয়নি',
                            trailing: _StatusBadge(
                              label: isEmailVerified
                                  ? 'ভেরিফায়েড'
                                  : 'আনভেরিফায়েড',
                              isPositive: isEmailVerified,
                            ),
                          ),
                        ],
                      ),

                      // অ্যাডমিন কন্ট্রোল প্যানেল (শুধুমাত্র অ্যাডমিনের জন্য)
                      if (_userRole == 'admin') ...[
                        const SizedBox(height: 24),
                        _SectionTitle(
                          title: 'অ্যাডমিন কন্ট্রোল',
                          subtitle: 'মেস পরিচালনার সেটিংস',
                          icon: Icons.admin_panel_settings_rounded,
                          iconColor: danger,
                          bgColor: const Color(0xFFFEE2E2),
                        ),
                        const SizedBox(height: 12),
                        _AdminCard(
                          onTap: () {
                            Navigator.push(
                              context,
                              PageRouteBuilder(
                                pageBuilder: (_, _, _) =>
                                const AdminPanelScreen(),
                                transitionsBuilder:
                                    (_, anim, _, child) {
                                  return FadeTransition(
                                    opacity: anim,
                                    child: SlideTransition(
                                      position: Tween<Offset>(
                                        begin: const Offset(0, 0.1),
                                        end: Offset.zero,
                                      ).animate(CurvedAnimation(
                                        parent: anim,
                                        curve: Curves.easeOutCubic,
                                      )),
                                      child: child,
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ],

                      const SizedBox(height: 28),

                      // লগআউট বাটন
                      _LogoutButton(
                        onTap: () => _handleLogout(context),
                      ),

                      const SizedBox(height: 20),

                      // অ্যাপের ভার্সন
                      const Center(
                        child: Text(
                          'MESS MANAGER  •  VERSION 1.0.1',
                          style: TextStyle(
                            color: muted,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),
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

  Future<void> _handleLogout(BuildContext context) async {
    // লগআউট কনফার্মেশন ডায়ালগ
    final confirm = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Logout',
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 300),
      transitionBuilder: (_, anim, _, child) {
        return ScaleTransition(
          scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
          child: FadeTransition(opacity: anim, child: child),
        );
      },
      pageBuilder: (ctx, _, _) {
        return Center(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
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
                      color: danger,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'লগ আউট করবেন?',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: dark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'আপনি কি সত্যিই লগ আউট করতে চান?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: muted),
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: _DialogButton(
                          label: 'বাতিল',
                          isPrimary: false,
                          onTap: () => Navigator.pop(ctx, false),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _DialogButton(
                          label: 'লগ আউট',
                          isPrimary: true,
                          onTap: () => Navigator.pop(ctx, true),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );

    if (confirm == true) {
      try {
        await _authService.signOut();
      } catch (e) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sign out করা যায়নি। আবার চেষ্টা করুন।'),
          ),
        );
      }
    }
  }

  // ==========================================
  // প্রোফাইল হেডার
  // ==========================================
  Widget _buildProfileHeader() {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topInset + 20, 24, 32),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [navyDeep, navyMid, navyLight],
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
            color: navyMid.withValues(alpha: 0.35),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        children: [
          // ডেকোরেটিভ সার্কেলস
          Positioned(
            right: -30,
            top: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Positioned(
            left: -20,
            bottom: 40,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: 40,
            bottom: 20,
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
            children: [
              // টাইটেল বার
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'প্রোফাইল',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  _GlassIconButton(
                    icon: Icons.refresh_rounded,
                    onTap: _fetchUserData,
                    tooltip: 'রিফ্রেশ',
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // অ্যানিমেটেড গ্লোয়িং অ্যাভাটার
              _GlowingAvatar(photoUrl: _photoUrl),

              const SizedBox(height: 18),

              // নাম
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(milliseconds: 700),
                curve: Curves.easeOutCubic,
                builder: (_, val, child) {
                  return Opacity(
                    opacity: val,
                    child: Transform.translate(
                      offset: Offset(0, 15 * (1 - val)),
                      child: child,
                    ),
                  );
                },
                child: Text(
                  _userName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 25,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // ইমেইল
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.email_rounded,
                    size: 13,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      _userEmail,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // রোল ব্যাজ
              _RoleBadge(role: _userRole),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // লোডিং ভিউ
  // ==========================================
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _PulsingLogo(),
          const SizedBox(height: 20),
          const Text(
            'প্রোফাইল লোড হচ্ছে...',
            style: TextStyle(
              color: dark,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'আপনার তথ্য লোড হচ্ছে',
            style: TextStyle(
              color: muted.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // এরর ভিউ
  // ==========================================
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeOutBack,
          builder: (_, val, child) => Transform.scale(scale: val, child: child),
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: const Color(0xFFFFDADA)),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withValues(alpha: 0.08),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 70,
                  height: 70,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFEEEE), Color(0xFFFEE2E2)],
                    ),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: const Icon(
                    Icons.cloud_off_rounded,
                    color: danger,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'প্রোফাইল লোড করা যায়নি',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: dark,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _errorMessage ?? 'আবার চেষ্টা করুন।',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: muted.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 20),
                _TapScaleButton(
                  onTap: _fetchUserData,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 13),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [navyMid, navyLight],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: navyLight.withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.refresh_rounded,
                            color: Colors.white, size: 19),
                        SizedBox(width: 7),
                        Text(
                          'আবার চেষ্টা করুন',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
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
}

// ============================================================================
// 🧊 গ্লাস আইকন বাটন
// ============================================================================

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
  bool _p = false;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: widget.tooltip,
      child: GestureDetector(
        onTapDown: (_) => setState(() => _p = true),
        onTapUp: (_) {
          setState(() => _p = false);
          widget.onTap();
        },
        onTapCancel: () => setState(() => _p = false),
        child: AnimatedScale(
          scale: _p ? 0.88 : 1.0,
          duration: const Duration(milliseconds: 100),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: _p ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(13),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
            child: Icon(widget.icon, color: Colors.white, size: 18),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 🌟 গ্লোয়িং অ্যাভাটার
// ============================================================================

class _GlowingAvatar extends StatefulWidget {
  final String? photoUrl;
  const _GlowingAvatar({this.photoUrl});

  @override
  State<_GlowingAvatar> createState() => _GlowingAvatarState();
}

class _GlowingAvatarState extends State<_GlowingAvatar>
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
      builder: (_, child) {
        final glow = 0.2 + (_glowController.value * 0.25);
        return Container(
          padding: const EdgeInsets.all(5),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(
              color: Colors.white.withValues(alpha: glow + 0.3),
              width: 2.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF60A5FA).withValues(alpha: glow),
                blurRadius: 25,
                spreadRadius: 3,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 22,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: child,
        );
      },
      child: CircleAvatar(
        radius: 48,
        backgroundColor: const Color(0xFFE0E7FF),
        child: ClipOval(
          child: widget.photoUrl != null && widget.photoUrl!.isNotEmpty
              ? Image.network(
            widget.photoUrl!,
            width: 96,
            height: 96,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox(
              width: 96,
              height: 96,
              child: Icon(Icons.person_rounded,
                  size: 52, color: _ProfileScreenState.navyLight),
            ),
          )
              : const SizedBox(
            width: 96,
            height: 96,
            child: Icon(Icons.person_rounded,
                size: 52, color: _ProfileScreenState.navyLight),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 🏷️ রোল ব্যাজ
// ============================================================================

class _RoleBadge extends StatelessWidget {
  final String role;
  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isAdmin = role == 'admin';
    final isWalletOnly = role == 'wallet_only';

    final IconData icon = isAdmin
        ? Icons.admin_panel_settings_rounded
        : (isWalletOnly
        ? Icons.account_balance_wallet_rounded
        : Icons.verified_user_rounded);

    final String label = isWalletOnly ? 'WALLET USER' : role.toUpperCase();

    final List<Color> bgGradient = isAdmin
        ? [const Color(0xFFFBBF24), const Color(0xFFF59E0B)]
        : [
      Colors.white.withValues(alpha: 0.2),
      Colors.white.withValues(alpha: 0.1),
    ];

    final Color textColor =
    isAdmin ? const Color(0xFF78350F) : Colors.white;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutBack,
      builder: (_, val, child) => Transform.scale(scale: val, child: child),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: bgGradient),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: isAdmin
                ? const Color(0xFFFBBF24).withValues(alpha: 0.5)
                : Colors.white.withValues(alpha: 0.4),
          ),
          boxShadow: isAdmin
              ? [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: textColor),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 📝 সেকশন টাইটেল
// ============================================================================

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;

  const _SectionTitle({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _ProfileScreenState.dark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: _ProfileScreenState.muted.withValues(alpha: 0.85),
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// 💳 ইনফো কার্ড কন্টেইনার
// ============================================================================

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EEF5)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Column(children: children),
      ),
    );
  }
}

// ============================================================================
// 🎬 অ্যানিমেটেড ইনফো টাইল
// ============================================================================

class _AnimatedInfoTile extends StatefulWidget {
  final int index;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const _AnimatedInfoTile({
    required this.index,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  State<_AnimatedInfoTile> createState() => _AnimatedInfoTileState();
}

class _AnimatedInfoTileState extends State<_AnimatedInfoTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      widget.iconBg,
                      widget.iconBg.withValues(alpha: 0.5),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: widget.iconColor, size: 22),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        color: _ProfileScreenState.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.subtitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: _ProfileScreenState.dark,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              if (widget.trailing != null) ...[
                const SizedBox(width: 8),
                widget.trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 🎯 অ্যানিমেটেড অ্যাকশন টাইল (ট্যাপযোগ্য)
// ============================================================================

class _AnimatedActionTile extends StatefulWidget {
  final int index;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AnimatedActionTile({
    required this.index,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  State<_AnimatedActionTile> createState() => _AnimatedActionTileState();
}

class _AnimatedActionTileState extends State<_AnimatedActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0.1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Future.delayed(Duration(milliseconds: 80 * widget.index), () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: GestureDetector(
          onTapDown: (_) => setState(() => _pressed = true),
          onTapUp: (_) {
            setState(() => _pressed = false);
            widget.onTap();
          },
          onTapCancel: () => setState(() => _pressed = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            color: _pressed
                ? widget.iconBg.withValues(alpha: 0.3)
                : Colors.transparent,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        widget.iconBg,
                        widget.iconBg.withValues(alpha: 0.5),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(widget.icon, color: widget.iconColor, size: 22),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.title,
                        style: const TextStyle(
                          color: _ProfileScreenState.dark,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.1,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        widget.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: _ProfileScreenState.muted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: widget.iconBg.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 12,
                    color: widget.iconColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 🏷️ স্ট্যাটাস ব্যাজ
// ============================================================================

class _StatusBadge extends StatelessWidget {
  final String label;
  final bool isPositive;

  const _StatusBadge({required this.label, required this.isPositive});

  @override
  Widget build(BuildContext context) {
    final Color color =
    isPositive ? const Color(0xFF059669) : _ProfileScreenState.danger;
    final Color bg = isPositive
        ? const Color(0xFFD1FAE5)
        : const Color(0xFFFEE2E2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// ━━━ ডিভাইডার
// ============================================================================

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 72, right: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        color: const Color(0xFFF1F5F9).withValues(alpha: 0.8),
      ),
    );
  }
}

// ============================================================================
// 👑 অ্যাডমিন কার্ড
// ============================================================================

class _AdminCard extends StatefulWidget {
  final VoidCallback onTap;
  const _AdminCard({required this.onTap});

  @override
  State<_AdminCard> createState() => _AdminCardState();
}

class _AdminCardState extends State<_AdminCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  bool _pressed = false;

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
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: AnimatedBuilder(
          animation: _pulseController,
          builder: (_, child) {
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFEE2E2), Color(0xFFFEF2F2)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFFFECACA).withValues(
                    alpha: 0.5 + _pulseController.value * 0.3,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: _ProfileScreenState.danger.withValues(
                      alpha: 0.1 + _pulseController.value * 0.08,
                    ),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: child,
            );
          },
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'অ্যাডমিন কন্ট্রোল প্যানেল',
                      style: TextStyle(
                        color: _ProfileScreenState.dark,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'মিল ও জমার হিসাব পরিচালনা',
                      style: TextStyle(
                        color: _ProfileScreenState.muted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: _ProfileScreenState.danger,
                  size: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// 🚪 লগআউট বাটন
// ============================================================================

class _LogoutButton extends StatefulWidget {
  final VoidCallback onTap;
  const _LogoutButton({required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
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
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 150),
        child: Container(
          width: double.infinity,
          height: 56,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _pressed
                  ? const Color(0xFFFECACA)
                  : const Color(0xFFFFD8DF),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _ProfileScreenState.danger.withValues(alpha: 0.06),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.logout_rounded,
                size: 21,
                color: _ProfileScreenState.danger,
              ),
              SizedBox(width: 10),
              Text(
                'লগআউট করুন',
                style: TextStyle(
                  color: _ProfileScreenState.danger,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================================
// ⏳ পালসিং লোগো (লোডিং)
// ============================================================================

class _PulsingLogo extends StatefulWidget {
  @override
  State<_PulsingLogo> createState() => _PulsingLogoState();
}

class _PulsingLogoState extends State<_PulsingLogo>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, child) {
        return Transform.scale(scale: 0.85 + (_c.value * 0.15), child: child);
      },
      child: Container(
        width: 68,
        height: 68,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [
              _ProfileScreenState.navyDeep,
              _ProfileScreenState.navyMid,
              _ProfileScreenState.navyLight,
            ],
          ),
          borderRadius: BorderRadius.circular(22),
          boxShadow: [
            BoxShadow(
              color: _ProfileScreenState.navyMid.withValues(alpha: 0.4),
              blurRadius: 22,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: const Icon(Icons.person_rounded,
            color: Colors.white, size: 32),
      ),
    );
  }
}

// ============================================================================
// 🔘 ট্যাপ স্কেল বাটন (রিইউজেবল)
// ============================================================================

class _TapScaleButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  const _TapScaleButton({required this.onTap, required this.child});

  @override
  State<_TapScaleButton> createState() => _TapScaleButtonState();
}

class _TapScaleButtonState extends State<_TapScaleButton> {
  bool _p = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) {
        setState(() => _p = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedScale(
        scale: _p ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: widget.child,
      ),
    );
  }
}

// ============================================================================
// 🔘 ডায়ালগ বাটন
// ============================================================================

class _DialogButton extends StatefulWidget {
  final String label;
  final bool isPrimary;
  final VoidCallback onTap;

  const _DialogButton({
    required this.label,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_DialogButton> createState() => _DialogButtonState();
}

class _DialogButtonState extends State<_DialogButton> {
  bool _p = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _p = true),
      onTapUp: (_) {
        setState(() => _p = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _p = false),
      child: AnimatedScale(
        scale: _p ? 0.93 : 1.0,
        duration: const Duration(milliseconds: 120),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? const LinearGradient(
              colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
            )
                : null,
            color: widget.isPrimary ? null : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(14),
            boxShadow: widget.isPrimary
                ? [
              BoxShadow(
                color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ]
                : null,
          ),
          child: Center(
            child: Text(
              widget.label,
              style: TextStyle(
                color: widget.isPrimary
                    ? Colors.white
                    : _ProfileScreenState.dark,
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

// ============================================================================
// AnimatedBuilder হেল্পার
// ============================================================================

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