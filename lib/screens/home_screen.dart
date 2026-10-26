import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import '../services/financial_service.dart';

// ==========================================
// 📱 Main Screen
// ==========================================
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FinancialService _financialService = FinancialService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _userName = 'লোড হচ্ছে...';
  String _userRole = 'member';
  String _userEmail = '';
  String? _photoUrl;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
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
        }
      } catch (e) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accent),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ১. Header Section (Clean Widget)
            _HeaderSection(
              userName: _userName,
              userRole: _userRole,
              photoUrl: _photoUrl,
              onLogout: () async => await _authService.signOut(),
            ),

            // ২. Financial Dashboard Section
            if (_userEmail.isNotEmpty)
              _FinancialDashboard(
                userEmail: _userEmail,
                financialService: _financialService,
              ),

            // ৩. Recent Transactions Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'সাম্প্রতিক কার্যক্রম',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  TextButton(
                    onPressed: () {}, // TODO: Navigate to all transactions
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.accent,
                    ),
                    child: const Text(
                      'সব দেখুন',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),

            // ৪. Recent Transactions List
            if (_userEmail.isNotEmpty)
              _RecentTransactions(firestore: _firestore),

            const SizedBox(height: 30), // Bottom padding
          ],
        ),
      ),
    );
  }
}

// ==========================================
// 🧩 Extracted Widgets (For Clean Architecture)
// ==========================================

/// [Top Header] - ব্যবহারকারীর প্রোফাইল এবং লোগো দেখানোর জন্য
class _HeaderSection extends StatelessWidget {
  final String userName;
  final String userRole;
  final String? photoUrl;
  final VoidCallback onLogout;

  const _HeaderSection({
    required this.userName,
    required this.userRole,
    this.photoUrl,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 60),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.maps_home_work_rounded,
                        color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mess Manager',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'একসাথে • সুন্দর • জীবন',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                onPressed: onLogout,
                icon: const Icon(Icons.power_settings_new_rounded,
                    color: Colors.white70, size: 28),
                tooltip: 'লগআউট',
              ),
            ],
          ),
          const SizedBox(height: 35),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: AppColors.background,
                  backgroundImage:
                  photoUrl != null ? NetworkImage(photoUrl!) : null,
                  child: photoUrl == null
                      ? const Icon(Icons.person_rounded,
                      size: 35, color: AppColors.primary)
                      : null,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'স্বাগতম, $userName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Text(
                        userRole.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                        ),
                      ),
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

/// [Financial Dashboard] - ব্যালেন্স এবং খরচের কার্ডগুলো
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
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 200,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.accent),
            ),
          );
        }

        final data = snapshot.data ?? {};
        final totalExpense = data['totalExpense'] ?? 0.0;
        final messCashBalance = data['messCashBalance'] ?? 0.0;
        final myNetBalance = data['myNetBalance'] ?? 0.0;
        final myMeals = data['myMeals'] ?? 0;
        final myAllocatedExpense = data['myAllocatedExpense'] ?? 0.0;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Transform.translate(
            offset: const Offset(0, -35), // Overlapping Effect
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _BalanceCard(
                        title: 'মেস ফান্ড ক্যাশ',
                        amount: messCashBalance,
                        icon: Icons.account_balance_wallet_rounded,
                        color: AppColors.success,
                        bgColor: const Color(0xFFD1FAE5),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _BalanceCard(
                        title: 'আমার ব্যালেন্স',
                        amount: myNetBalance,
                        icon: Icons.person_rounded,
                        color: myNetBalance >= 0
                            ? AppColors.accent
                            : AppColors.danger,
                        bgColor: myNetBalance >= 0
                            ? const Color(0xFFDBEAFE)
                            : const Color(0xFFFEE2E2),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _ExpenseCard(
                  totalExpense: totalExpense,
                  myAllocatedExpense: myAllocatedExpense,
                  myMeals: myMeals,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// [Small Balance Card] - ছোট কার্ডগুলো (Fund & Personal Balance)
class _BalanceCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _BalanceCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: bgColor, shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '৳ ${amount.toStringAsFixed(2)}',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// [Large Expense Card] - বড় নীল গ্রেডিয়েন্ট কার্ড
class _ExpenseCard extends StatelessWidget {
  final double totalExpense;
  final double myAllocatedExpense;
  final int myMeals;

  const _ExpenseCard({
    required this.totalExpense,
    required this.myAllocatedExpense,
    required this.myMeals,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], // Modern Blue Gradient
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.accent.withValues(alpha: 0.35),
            blurRadius: 24,
            offset: const Offset(0, 12),
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
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.analytics_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              const Text(
                'চলতি মাসের মোট খরচ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            '৳ ${totalExpense.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 38,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 26),

          // Stats Row with Glassmorphism Effect
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.pie_chart_rounded,
                    title: 'আমার ভাগে',
                    value: '৳ ${myAllocatedExpense.toStringAsFixed(0)}',
                  ),
                ),
                Container(
                  width: 1,
                  height: 45,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 20),
                    child: _MiniStat(
                      icon: Icons.restaurant_rounded,
                      title: 'আমার মিল',
                      value: '$myMeals টি',
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
}

/// [Mini Stat Component] - বড় কার্ডের ভেতরের ছোট ডাটা
class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _MiniStat({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Colors.white70, size: 16),
            const SizedBox(width: 6),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

/// [Recent Transactions Stream] - ফায়ারবেস থেকে সাম্প্রতিক খরচ
class _RecentTransactions extends StatelessWidget {
  final FirebaseFirestore firestore;

  const _RecentTransactions({required this.firestore});

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
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(color: AppColors.accent),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(35),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: const Column(
                children: [
                  Icon(Icons.receipt_long_rounded,
                      color: Color(0xFFCBD5E1), size: 50),
                  SizedBox(height: 16),
                  Text('এখনও কোনো লেনদেন হয়নি।',
                      style: TextStyle(
                          color: AppColors.textSecondary, fontSize: 15)),
                ],
              ),
            );
          }

          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.02),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: snapshot.data!.docs.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                indent: 75, // Align with text
                color: AppColors.border,
              ),
              itemBuilder: (context, index) {
                var doc = snapshot.data!.docs[index];
                Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

                List<dynamic> products = data['products'] ?? [];
                double amount = (data['totalAmountInPaisa'] ?? 0) / 100;
                String purchaser =
                (data['purchasedByEmail'] ?? '').toString().split('@')[0];

                // Dynamic colors for icons based on index
                final List<Color> iconColors = [
                  const Color(0xFF8B5CF6), // Purple
                  const Color(0xFFF59E0B), // Amber
                  const Color(0xFF06B6D4), // Cyan
                ];
                final List<Color> iconBgColors = [
                  const Color(0xFFEDE9FE),
                  const Color(0xFFFEF3C7),
                  const Color(0xFFCFFAFE),
                ];

                return ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  leading: Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: iconBgColors[index % 3],
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(Icons.shopping_basket_rounded,
                        color: iconColors[index % 3], size: 24),
                  ),
                  title: Text(
                    products.join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  subtitle: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.person_outline_rounded,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          purchaser,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  trailing: Text(
                    '- ৳${amount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: AppColors.danger,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      letterSpacing: -0.5,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}