import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();

  bool _isLoading = false;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Colors
  static const Color primary = Color(0xFF5B5FEF);
  static const Color secondary = Color(0xFF8E54E9);
  static const Color cyan = Color(0xFF00C9A7);
  static const Color teal = Color(0xFF00BFA6);
  static const Color dark = Color(0xFF20264A);
  static const Color muted = Color(0xFF7B8199);
  static const Color background = Color(0xFFF5F5FF);

  static const LinearGradient mainGradient = LinearGradient(
    colors: [
      Color(0xFF00C9A7),
      Color(0xFF4776E6),
      Color(0xFF8E54E9),
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // =========================================
  // GOOGLE SIGN IN
  // =========================================

  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final userCredential =
      await _authService.signInWithGoogle();

      if (userCredential != null &&
          userCredential.user != null) {
        final bool isAuthorized =
        await _authService.checkAndCreateUserProfile(
          userCredential.user!,
        );

        if (!isAuthorized) {
          await _authService.signOut();

          if (mounted) {
            _showMessage(
              'মেসে সর্বোচ্চ ৮ জন সদস্যের সীমা পূর্ণ হয়ে গেছে! নতুন অ্যাকাউন্ট যুক্ত করা সম্ভব নয়।',
              isError: true,
            );
          }
        }
      } else {
        if (mounted) {
          _showMessage('Sign-in failed or canceled.');
        }
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Something went wrong. Please try again.',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // =========================================
  // SNACKBAR
  // =========================================

  void _showMessage(
      String message, {
        bool isError = false,
      }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.info_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        backgroundColor:
        isError ? const Color(0xFFE53935) : primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // =========================================
  // MAIN UI
  // =========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          _buildBackground(),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: SlideTransition(
                          position: _slideAnimation,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 23,
                              vertical: 30,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 430,
                              ),
                              child: Column(
                                mainAxisAlignment:
                                MainAxisAlignment.center,
                                children: [
                                  _buildTopBadge(),

                                  const SizedBox(height: 25),

                                  _buildLogo(),

                                  const SizedBox(height: 24),

                                  _buildAppTitle(),

                                  const SizedBox(height: 35),

                                  _buildLoginCard(),

                                  const SizedBox(height: 18),

                                  _buildSecurityCard(),

                                  const SizedBox(height: 25),

                                  _buildFooter(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // BACKGROUND
  // =========================================

  Widget _buildBackground() {
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned(
            top: -110,
            right: -100,
            child: _glowCircle(
              size: 290,
              color: secondary,
              opacity: 0.13,
            ),
          ),

          Positioned(
            top: 250,
            left: -110,
            child: _glowCircle(
              size: 220,
              color: cyan,
              opacity: 0.11,
            ),
          ),

          Positioned(
            bottom: -110,
            right: -70,
            child: _glowCircle(
              size: 230,
              color: primary,
              opacity: 0.09,
            ),
          ),

          Positioned(
            top: 130,
            left: 42,
            child: _dot(cyan, 8),
          ),

          Positioned(
            top: 220,
            right: 35,
            child: _dot(secondary, 7),
          ),

          Positioned(
            bottom: 170,
            left: 50,
            child: _dot(primary, 6),
          ),
        ],
      ),
    );
  }

  Widget _glowCircle({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: opacity),
      ),
    );
  }

  Widget _dot(Color color, double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.35),
        shape: BoxShape.circle,
      ),
    );
  }

  // =========================================
  // TOP BADGE
  // =========================================

  Widget _buildTopBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: primary.withValues(alpha: 0.10),
        ),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.06),
            blurRadius: 15,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: teal,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          const Text(
            'SMART MESS MANAGEMENT',
            style: TextStyle(
              color: primary,
              fontSize: 9,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // =========================================
  // APP LOGO
  // =========================================

  Widget _buildLogo() {
    return Container(
      width: 130,
      height: 130,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        gradient: mainGradient,
        borderRadius: BorderRadius.circular(38),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.25),
            blurRadius: 35,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(34),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(29),
          child: Image.asset(
            'assets/images/mess_logo.png',
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                decoration: const BoxDecoration(
                  gradient: mainGradient,
                ),
                child: const Icon(
                  Icons.account_balance_wallet_rounded,
                  size: 60,
                  color: Colors.white,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // =========================================
  // APP TITLE
  // =========================================

  Widget _buildAppTitle() {
    return Column(
      children: [
        const Text(
          'Mess Management',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            letterSpacing: -1,
            color: dark,
          ),
        ),

        const SizedBox(height: 9),

        ShaderMask(
          shaderCallback: (bounds) {
            return mainGradient.createShader(
              Rect.fromLTWH(
                0,
                0,
                bounds.width,
                bounds.height,
              ),
            );
          },
          child: const Text(
            'Smart Living • Simple Management',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ),

        const SizedBox(height: 13),

        Container(
          width: 45,
          height: 4,
          decoration: BoxDecoration(
            gradient: mainGradient,
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }

  // =========================================
  // LOGIN CARD
  // =========================================

  Widget _buildLoginCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: const Color(0xFFEAEAFF),
        ),
        boxShadow: [
          BoxShadow(
            color: dark.withValues(alpha: 0.07),
            blurRadius: 35,
            offset: const Offset(0, 15),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome badge
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFEEEDFF),
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.waving_hand_rounded,
                  size: 16,
                  color: primary,
                ),
                SizedBox(width: 7),
                Text(
                  'WELCOME BACK',
                  style: TextStyle(
                    color: primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          const Text(
            'Login to your account',
            style: TextStyle(
              fontSize: 23,
              fontWeight: FontWeight.w900,
              color: dark,
              letterSpacing: -0.5,
            ),
          ),

          const SizedBox(height: 9),

          const Text(
            'Manage your mess expenses, members and daily accounts in one place.',
            style: TextStyle(
              fontSize: 13,
              height: 1.7,
              color: muted,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 25),

          _buildGoogleButton(),

          const SizedBox(height: 22),

          Row(
            children: [
              Expanded(
                child: Divider(
                  color: primary.withValues(alpha: 0.12),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'AUTHORIZED ACCESS',
                  style: TextStyle(
                    color: muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: primary.withValues(alpha: 0.12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =========================================
  // GOOGLE BUTTON
  // =========================================

  Widget _buildGoogleButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: double.infinity,
      height: 60,
      decoration: BoxDecoration(
        gradient: mainGradient,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: primary.withValues(alpha: 0.27),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _isLoading ? null : _handleGoogleSignIn,
          borderRadius: BorderRadius.circular(18),
          child: Center(
            child: _isLoading
                ? const SizedBox(
              height: 25,
              width: 25,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2.5,
              ),
            )
                : Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: const Text(
                    'G',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF4285F4),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                const Text(
                  'Continue with Google',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),

                const SizedBox(width: 10),

                const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 19,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // =========================================
  // SECURITY CARD
  // =========================================

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFE6FFF6),
            Color(0xFFEEFAFF),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFD7F5EA),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: teal.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: teal,
              size: 25,
            ),
          ),

          const SizedBox(width: 13),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Secure Member Access',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF175B50),
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Only authorized mess members can access this application.',
                  style: TextStyle(
                    fontSize: 11,
                    height: 1.6,
                    color: Color(0xFF62847D),
                  ),
                ),
              ],
            ),
          ),

          const Icon(
            Icons.lock_rounded,
            color: teal,
            size: 20,
          ),
        ],
      ),
    );
  }

  // =========================================
  // FOOTER
  // =========================================

  Widget _buildFooter() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_rounded,
              size: 14,
              color: Color(0xFF969BB2),
            ),

            const SizedBox(width: 7),

            Flexible(
              child: Text(
                'Secure Login • Mess Management App',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: muted.withValues(alpha: 0.85),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        Text(
          'SMART  •  SIMPLE  •  CONNECTED',
          style: TextStyle(
            fontSize: 9,
            color: primary.withValues(alpha: 0.55),
            fontWeight: FontWeight.w800,
            letterSpacing: 1.3,
          ),
        ),
      ],
    );
  }
}