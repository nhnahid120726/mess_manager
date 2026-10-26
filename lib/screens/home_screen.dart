
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/auth_service.dart';
import '../services/financial_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();
  final FinancialService _financialService = FinancialService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _userName = 'Loading...';
  String _userRole = '';
  String _userEmail = '';
  String? _photoUrl;

  static const Color primary = Color(0xFF087F8C);
  static const Color dark = Color(0xFF173B55);
  static const Color muted = Color(0xFF7186A5);
  static const Color pageBg = Color(0xFFF3F7FF);

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // আগের User Data Fetching Logic অপরিবর্তিত
  void _fetchUserData() async {
    final user = _authService.currentUser;

    if (user != null && user.email != null) {
      _userEmail = user.email!;

      DocumentSnapshot doc =
      await _firestore.collection('members').doc(user.email).get();

      if (doc.exists && mounted) {
        setState(() {
          _userName = doc['name'] ?? user.displayName ?? 'User';
          _userRole = doc['role'] ?? 'member';
          _photoUrl = user.photoURL;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ১. ছবির মতো Colorful Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF087F8C),
                      Color(0xFF00A99D),
                      Color(0xFF42D6A4),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(36),
                    bottomRight: Radius.circular(36),
                  ),
                ),
                child: Row(
                  children: [
                    // নিজের App Logo থাকলে সেটি দেখাবে
                    Container(
                      width: 58,
                      height: 58,
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.17),
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Image.asset(
                        'assets/images/mess_logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.home_work_rounded,
                            color: Colors.white,
                            size: 42,
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mess Manager',
                            style: TextStyle(
                              fontSize: 23,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                              letterSpacing: -0.5,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'একসাথে • সুন্দর • জীবন',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFFD8FFFA),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // আগের Logout Action
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF006779),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: IconButton(
                        tooltip: 'লগআউট',
                        onPressed: () async {
                          await _authService.signOut();
                        },
                        icon: const Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 27,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ২. User Profile Card
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF087D8A),
                        Color(0xFF079F9D),
                        Color(0xFF29C99A),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF009E9B).withOpacity(0.19),
                        blurRadius: 22,
                        offset: const Offset(0, 9),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 3,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 40,
                          backgroundColor: Colors.white,
                          backgroundImage: _photoUrl != null
                              ? NetworkImage(_photoUrl!)
                              : null,
                          child: _photoUrl == null
                              ? const Icon(
                            Icons.person_rounded,
                            size: 48,
                            color: primary,
                          )
                              : null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'স্বাগতম, $_userName',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'মেস ম্যানেজারে আপনাকে স্বাগতম!',
                              style: TextStyle(
                                color: Color(0xFFD9FFFA),
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 7,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.14),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.35),
                                ),
                                borderRadius: BorderRadius.circular(30),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.person_outline_rounded,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 7),
                                  Flexible(
                                    child: Text(
                                      _userRole.toUpperCase(),
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('👋', style: TextStyle(fontSize: 30)),
                    ],
                  ),
                ),
              ),

              // ৩. আগের Financial Summary Stream
              if (_userEmail.isNotEmpty)
                StreamBuilder<Map<String, dynamic>>(
                  stream:
                  _financialService.getFinancialSummary(_userEmail),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: CircularProgressIndicator(
                            color: primary,
                          ),
                        ),
                      );
                    }

                    final data = snapshot.data ?? {};

                    double totalExpense =
                        data['totalExpense'] ?? 0.0;
                    double messCashBalance =
                        data['messCashBalance'] ?? 0.0;
                    double myNetBalance =
                        data['myNetBalance'] ?? 0.0;
                    int myMeals = data['myMeals'] ?? 0;

                    return Padding(
                      padding: const EdgeInsets.fromLTRB(18, 24, 18, 0),
                      child: Column(
                        children: [
                          // ৪. Balance Cards
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: _buildBalanceCard(
                                  title: 'মেস ফান্ডের বর্তমান ক্যাশ',
                                  amount:
                                  '৳ ${messCashBalance.toStringAsFixed(2)}',
                                  icon: Icons.account_balance_wallet_rounded,
                                  color: const Color(0xFF0BB77A),
                                  iconBg: const Color(0xFFBDF5DF),
                                  background: const Color(0xFFEFFFF7),
                                  positive: true,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildBalanceCard(
                                  title: 'আমার বর্তমান ব্যালেন্স',
                                  amount:
                                  '৳ ${myNetBalance.toStringAsFixed(2)}',
                                  icon: Icons.person_rounded,
                                  color: const Color(0xFFFF4058),
                                  iconBg: const Color(0xFFFFD4DC),
                                  background: const Color(0xFFFFF1F4),
                                  positive: myNetBalance >= 0,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ৫. Blue Gradient Expense Card
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(19),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFF394DE5),
                                  Color(0xFF287FF5),
                                  Color(0xFF42A5F5),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(29),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF3979F0)
                                      .withOpacity(0.24),
                                  blurRadius: 24,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 55,
                                      height: 55,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFFFFB93F),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.shopping_cart_rounded,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                    const SizedBox(width: 13),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'মোট খরচ',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                          SizedBox(height: 4),
                                          Text(
                                            '(চলতি মাস)',
                                            style: TextStyle(
                                              color: Color(0xFFE3EBFF),
                                              fontSize: 13,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 9,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white.withOpacity(0.16),
                                        borderRadius:
                                        BorderRadius.circular(25),
                                        border: Border.all(
                                          color: Colors.white.withOpacity(0.2),
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.calendar_month_rounded,
                                            color: Colors.white,
                                            size: 15,
                                          ),
                                          SizedBox(width: 5),
                                          Text(
                                            'চলতি মাস',
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          SizedBox(width: 3),
                                          Icon(
                                            Icons.keyboard_arrow_down_rounded,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 22),

                                Text(
                                  '৳ ${totalExpense.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: -0.7,
                                  ),
                                ),

                                const SizedBox(height: 21),

                                // Allocated Expense এবং Total Meals
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 17,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.95),
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 43,
                                              height: 43,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFC9F5E9),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons
                                                    .account_balance_wallet_rounded,
                                                color: Color(0xFF078F92),
                                                size: 23,
                                              ),
                                            ),
                                            const SizedBox(width: 9),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'আমার ভাগে পড়া খরচ',
                                                    maxLines: 2,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: muted,
                                                      fontWeight:
                                                      FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 7),
                                                  FittedBox(
                                                    fit: BoxFit.scaleDown,
                                                    alignment:
                                                    Alignment.centerLeft,
                                                    child: Text(
                                                      '৳ ${(data['myAllocatedExpense'] ?? 0.0).toStringAsFixed(2)}',
                                                      style: const TextStyle(
                                                        color: Color(0xFF078F92),
                                                        fontSize: 19,
                                                        fontWeight:
                                                        FontWeight.w900,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 54,
                                        margin: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                        ),
                                        color: const Color(0xFFDCE5F4),
                                      ),
                                      Expanded(
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 43,
                                              height: 43,
                                              decoration: const BoxDecoration(
                                                color: Color(0xFFE9DFFF),
                                                shape: BoxShape.circle,
                                              ),
                                              child: const Icon(
                                                Icons.restaurant_rounded,
                                                color: Color(0xFF7444E8),
                                                size: 23,
                                              ),
                                            ),
                                            const SizedBox(width: 9),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                                children: [
                                                  const Text(
                                                    'আমার মোট মিল',
                                                    maxLines: 2,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: muted,
                                                      fontWeight:
                                                      FontWeight.w700,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 7),
                                                  Text(
                                                    '$myMeals',
                                                    style: const TextStyle(
                                                      color: Color(0xFF7444E8),
                                                      fontSize: 20,
                                                      fontWeight:
                                                      FontWeight.w900,
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
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

              // ৬. Recent Activity Heading
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 29, 22, 15),
                child: Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      color: Color(0xFF08B78A),
                      size: 31,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'সাম্প্রতিক কার্যক্রম',
                        style: TextStyle(
                          color: dark,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.4,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDDF7F2),
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: const Row(
                        children: [
                          Text(
                            'সর্বশেষ ৩টি',
                            style: TextStyle(
                              color: Color(0xFF008C83),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(width: 5),
                          Icon(
                            Icons.chevron_right_rounded,
                            color: Color(0xFF008C83),
                            size: 17,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ৭. আগের Recent Activity Firestore Query
              if (_userEmail.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 24),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: _firestore
                        .collection('expenses')
                        .orderBy('createdAt', descending: true)
                        .limit(3)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(25),
                            child: CircularProgressIndicator(
                              color: primary,
                            ),
                          ),
                        );
                      }

                      if (!snapshot.hasData ||
                          snapshot.data!.docs.isEmpty) {
                        return Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(30),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const Column(
                            children: [
                              Icon(
                                Icons.receipt_long_rounded,
                                color: Color(0xFFA7B8CF),
                                size: 42,
                              ),
                              SizedBox(height: 10),
                              Text(
                                'এখনও কোনো লেনদেন হয়নি।',
                                style: TextStyle(color: muted),
                              ),
                            ],
                          ),
                        );
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(25),
                          border: Border.all(
                            color: const Color(0xFFE5EDF9),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF234D80)
                                  .withOpacity(0.045),
                              blurRadius: 20,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          children: snapshot.data!.docs.map((doc) {
                            Map<String, dynamic> data =
                            doc.data() as Map<String, dynamic>;

                            List<dynamic> products = data['products'] ?? [];
                            double amount =
                                (data['totalAmountInPaisa'] ?? 0) / 100;
                            String purchaser =
                            (data['purchasedByEmail'] ?? '')
                                .toString()
                                .split('@')[0];

                            final int index =
                            snapshot.data!.docs.indexOf(doc);

                            final List<Color> iconColors = [
                              const Color(0xFF078F92),
                              const Color(0xFFFF4260),
                              const Color(0xFF6545E8),
                            ];

                            final List<Color> iconBackgrounds = [
                              const Color(0xFFC8F5E9),
                              const Color(0xFFFFDDE4),
                              const Color(0xFFE6E2FF),
                            ];

                            final List<IconData> icons = [
                              Icons.account_balance_wallet_rounded,
                              Icons.person_rounded,
                              Icons.restaurant_rounded,
                            ];

                            return Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 1,
                                    vertical: 5,
                                  ),
                                  leading: Container(
                                    width: 47,
                                    height: 47,
                                    decoration: BoxDecoration(
                                      color: iconBackgrounds[index % 3],
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      icons[index % 3],
                                      color: iconColors[index % 3],
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    products.join(', '),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: dark,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 7),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.calendar_month_rounded,
                                          size: 13,
                                          color: Color(0xFF8CA2C0),
                                        ),
                                        const SizedBox(width: 5),
                                        Expanded(
                                          child: Text(
                                            'কিনেছেন: $purchaser',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 10,
                                              color: muted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        '- ৳ ${amount.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                          color: Color(0xFFFF4058),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      const Icon(
                                        Icons.chevron_right_rounded,
                                        color: Color(0xFF9DB0CA),
                                        size: 21,
                                      ),
                                    ],
                                  ),
                                ),
                                if (index < snapshot.data!.docs.length - 1)
                                  const Divider(
                                    height: 1,
                                    indent: 60,
                                    color: Color(0xFFECF1F8),
                                  ),
                              ],
                            );
                          }).toList(),
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

  // Balance Card — শুধু UI Helper
  Widget _buildBalanceCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required Color iconBg,
    required Color background,
    required bool positive,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 17, 12, 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.white, background],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: color.withOpacity(0.09),
        ),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.07),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 30,
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: color,
                  size: 23,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF536987),
            ),
          ),
          const SizedBox(height: 9),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              amount,
              style: TextStyle(
                fontSize: 25,
                fontWeight: FontWeight.w900,
                color: color == const Color(0xFF0BB77A)
                    ? const Color(0xFF075A64)
                    : color,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(
                positive
                    ? Icons.arrow_upward_rounded
                    : Icons.arrow_downward_rounded,
                color: color,
                size: 17,
              ),
              const SizedBox(width: 3),
              Text(
                positive ? '+12%' : '-8%',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 12,
                ),
              ),
              const SizedBox(width: 7),
              const Expanded(
                child: Text(
                  'গত মাসের তুলনায়',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: muted,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
