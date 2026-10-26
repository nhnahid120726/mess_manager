
import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // আগের AuthService — Firebase Logic পরিবর্তন করা হয়নি।
  final AuthService _authService = AuthService();

  // Login চলাকালীন Loading দেখাবে।
  bool _isLoading = false;

  // Google Sign-In এবং Authorization Logic।
  Future<void> _handleGoogleSignIn() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // আগের Google Sign-In Function।
      final userCredential = await _authService.signInWithGoogle();

      if (userCredential != null && userCredential.user != null) {
        // আগের Firebase User Authorization Check।
        final bool isAuthorized =
        await _authService.checkAndCreateUserProfile(
          userCredential.user!,
        );

        if (!isAuthorized) {
          // অনুমোদিত সদস্য না হলে Sign Out হবে।
          await _authService.signOut();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Access Denied. You are not an authorized member of this mess.',
                ),
                backgroundColor: Color(0xFFE53935),
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        }
      } else {
        // Login বাতিল বা ব্যর্থ হলে।
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Sign-in failed or canceled.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      // Login-এর সময় Error হলে অ্যাপ ক্র্যাশ না করে বার্তা দেখাবে।
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Something went wrong. Please try again.'),
            backgroundColor: Color(0xFFE53935),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      // সব অবস্থায় Loading বন্ধ হবে।
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI-এর জন্য Color Palette।
    const Color primary = Color(0xFF5B5FEF);
    const Color teal = Color(0xFF00BFA6);
    const Color dark = Color(0xFF20264A);
    const Color muted = Color(0xFF7B8199);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5FF),

      // SafeArea: Status Bar-এর নিচ থেকে UI শুরু হবে।
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Stack(
                  children: [
                    // =====================================
                    // ১. COLORFUL BACKGROUND DECORATIONS
                    // =====================================

                    Positioned(
                      top: -100,
                      right: -90,
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF9B8AFF)
                              .withOpacity(0.13),
                        ),
                      ),
                    ),

                    Positioned(
                      top: 210,
                      left: -100,
                      child: Container(
                        width: 190,
                        height: 190,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: teal.withOpacity(0.10),
                        ),
                      ),
                    ),

                    // =====================================
                    // ২. MAIN LOGIN CONTENT
                    // =====================================

                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 30,
                        ),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(
                            maxWidth: 430,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // =================================
                              // ৩. APP LOGO
                              // =================================

                              Container(
                                width: 124,
                                height: 124,
                                padding: const EdgeInsets.all(9),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFF00C9A7),
                                      Color(0xFF4776E6),
                                      Color(0xFF8E54E9),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(35),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primary.withOpacity(0.25),
                                      blurRadius: 28,
                                      offset: const Offset(0, 12),
                                    ),
                                  ],
                                ),

                                // নিজের PNG Logo এখানে ব্যবহার হবে।
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(27),
                                  child: Image.asset(
                                    'assets/images/mess_logo.png',
                                    fit: BoxFit.contain,
                                    errorBuilder:
                                        (context, error, stackTrace) {
                                      // Logo পাওয়া না গেলে বিকল্প আইকন।
                                      return const Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 64,
                                        color: Colors.white,
                                      );
                                    },
                                  ),
                                ),
                              ),

                              const SizedBox(height: 25),

                              // =================================
                              // ৪. APP NAME
                              // =================================

                              const Text(
                                'Mess Management',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 29,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: -0.8,
                                  color: dark,
                                ),
                              ),

                              const SizedBox(height: 9),

                              // Subtitle।
                              const Text(
                                'Smart Living • Simple Management',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: muted,
                                  fontWeight: FontWeight.w500,
                                  letterSpacing: 0.3,
                                ),
                              ),

                              const SizedBox(height: 34),

                              // =================================
                              // ৫. LOGIN CARD
                              // =================================

                              Container(
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
                                      color: const Color(0xFF34366B)
                                          .withOpacity(0.08),
                                      blurRadius: 35,
                                      offset: const Offset(0, 15),
                                    ),
                                  ],
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    // Welcome Badge।
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 7,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFEEEDFF),
                                        borderRadius:
                                        BorderRadius.circular(30),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.waving_hand_rounded,
                                            size: 16,
                                            color: Color(0xFF7771E8),
                                          ),
                                          SizedBox(width: 7),
                                          Text(
                                            'WELCOME BACK',
                                            style: TextStyle(
                                              color: Color(0xFF625BD7),
                                              fontSize: 10,
                                              fontWeight: FontWeight.w800,
                                              letterSpacing: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    const SizedBox(height: 20),

                                    const Text(
                                      'Login to your account',
                                      style: TextStyle(
                                        fontSize: 23,
                                        fontWeight: FontWeight.w800,
                                        color: dark,
                                        letterSpacing: -0.5,
                                      ),
                                    ),

                                    const SizedBox(height: 9),

                                    const Text(
                                      'Manage your mess expenses, members '
                                          'and daily accounts in one place.',
                                      style: TextStyle(
                                        fontSize: 13,
                                        height: 1.7,
                                        color: muted,
                                      ),
                                    ),

                                    const SizedBox(height: 27),

                                    // =================================
                                    // ৬. GOOGLE SIGN-IN BUTTON
                                    // =================================

                                    SizedBox(
                                      width: double.infinity,
                                      height: 58,
                                      child: ElevatedButton(
                                        onPressed: _isLoading
                                            ? null
                                            : _handleGoogleSignIn,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: primary,
                                          disabledBackgroundColor:
                                          primary.withOpacity(0.7),
                                          foregroundColor: Colors.white,
                                          elevation: 5,
                                          shadowColor:
                                          primary.withOpacity(0.3),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                            BorderRadius.circular(17),
                                          ),
                                        ),
                                        child: _isLoading
                                            ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child:
                                          CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            color: Colors.white,
                                          ),
                                        )
                                            : Row(
                                          mainAxisAlignment:
                                          MainAxisAlignment.center,
                                          children: [
                                            // Google G Badge।
                                            Container(
                                              width: 31,
                                              height: 31,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius:
                                                BorderRadius
                                                    .circular(10),
                                              ),
                                              child: const Text(
                                                'G',
                                                style: TextStyle(
                                                  fontSize: 21,
                                                  fontWeight:
                                                  FontWeight.w900,
                                                  color: Color(
                                                    0xFF4285F4,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            const Text(
                                              'Continue with Google',
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight:
                                                FontWeight.w700,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            const Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 19,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),

                                    const SizedBox(height: 22),

                                    // =================================
                                    // ৭. SECURITY INFORMATION CARD
                                    // =================================

                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(15),
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFE6FFF6),
                                            Color(0xFFEEFAFF),
                                          ],
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(18),
                                        border: Border.all(
                                          color: const Color(0xFFD7F5EA),
                                        ),
                                      ),
                                      child: const Row(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Icon(
                                            Icons.verified_user_rounded,
                                            color: Color(0xFF00A884),
                                            size: 25,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  'Secure Member Access',
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w800,
                                                    color: Color(0xFF175B50),
                                                  ),
                                                ),
                                                SizedBox(height: 5),
                                                Text(
                                                  'Only authorized mess members '
                                                      'can access this application.',
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    height: 1.6,
                                                    color: Color(0xFF62847D),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 25),

                              // =================================
                              // ৮. FOOTER
                              // =================================

                              const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.lock_rounded,
                                    size: 14,
                                    color: Color(0xFF969BB2),
                                  ),
                                  SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      'Secure Login • Mess Management App',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF969BB2),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 10),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
