
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/auth_service.dart';
import 'admin_panel_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Firebase Authentication এবং Firestore সার্ভিস
  final AuthService _authService = AuthService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ব্যবহারকারীর তথ্য রাখার ভেরিয়েবল
  String _userName = 'Loading...';
  String _userEmail = '';
  String _userRole = 'member';
  String? _photoUrl;

  bool _isLoading = true;
  String? _errorMessage;

  // Home Screen-এর সঙ্গে মিল রেখে আধুনিক কালার প্যালেট
  static const Color primary = Color(0xFF087F8C);
  static const Color primaryDark = Color(0xFF075E68);
  static const Color accent = Color(0xFF42D6A4);
  static const Color dark = Color(0xFF173B55);
  static const Color muted = Color(0xFF7186A5);
  static const Color pageBg = Color(0xFFF3F7FC);
  static const Color danger = Color(0xFFE94B64);

  @override
  void initState() {
    super.initState();

    // স্ক্রিন চালু হলে Firebase থেকে ব্যবহারকারীর তথ্য লোড হবে
    _fetchUserData();
  }

  // ==========================================
  // ১. Firebase থেকে প্রোফাইলের তথ্য সংগ্রহ
  // ==========================================
  Future<void> _fetchUserData() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final user = _authService.currentUser;

      // লগইন করা ব্যবহারকারী না থাকলে ডিফল্ট তথ্য দেখানো হবে
      if (user == null || user.email == null) {
        if (!mounted) return;

        setState(() {
          _userName = 'Guest User';
          _userEmail = '';
          _userRole = 'member';
          _photoUrl = null;
          _isLoading = false;
        });
        return;
      }

      // Firebase Auth থেকে ইমেইল ও প্রোফাইল ছবি নেওয়া
      final email = user.email!;
      final photo = user.photoURL;
      final displayName = user.displayName;

      // আগের ডেটাবেজ স্ট্রাকচার অপরিবর্তিত:
      // members collection-এর document ID হলো ব্যবহারকারীর email
      final DocumentSnapshot<Map<String, dynamic>> doc =
      await _firestore.collection('members').doc(email).get();

      final data = doc.data();

      // Firestore-এ তথ্য থাকলে সেখান থেকে নাম ও role নেওয়া হবে
      // তথ্য না থাকলে Firebase Auth-এর নাম ব্যবহার করা হবে
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
    } catch (e) {
      // ডেটা লোড করতে সমস্যা হলে অ্যাপ বন্ধ না করে error দেখানো হবে
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _errorMessage = 'প্রোফাইল লোড করা যায়নি। আবার চেষ্টা করুন।';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Firebase Auth থেকে নিরাপত্তা ও লগইন সংক্রান্ত তথ্য
    final user = _authService.currentUser;

    final String firebaseUid = user?.uid ?? 'N/A';
    final bool isEmailVerified = user?.emailVerified ?? false;

    // Google বা অন্য login provider-এর তথ্য
    String provider = 'Unknown';
    String providerUid = 'N/A';

    if (user != null && user.providerData.isNotEmpty) {
      final providerInfo = user.providerData.first;

      provider = providerInfo.providerId;
    }

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        top: false,
        child: _isLoading
            ? _buildLoadingView()
            : _errorMessage != null
            ? _buildErrorView()
            : RefreshIndicator(
          color: primary,
          onRefresh: _fetchUserData,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ২. প্রোফাইল হেডার ও ব্যবহারকারীর পরিচিতি
                _buildProfileHeader(),

                const SizedBox(height: 26),

                // নিচের সব তথ্য কার্ডের জন্য একই horizontal spacing
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ৩. অ্যাকাউন্টের সাধারণ তথ্য
                      _buildSectionTitle(
                        'অ্যাকাউন্টের তথ্য',
                        'আপনার অ্যাকাউন্টের বিস্তারিত',
                        Icons.account_circle_rounded,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        children: [
                          _buildInfoTile(
                            icon: Icons.login_rounded,
                            iconColor: const Color(0xFF4285F4),
                            iconBg: const Color(0xFFEAF1FF),
                            title: 'লগইন মাধ্যম',
                            subtitle: provider == 'google.com'
                                ? 'গুগল অ্যাকাউন্ট'
                                : provider,
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            icon: Icons.fingerprint_rounded,
                            iconColor: primary,
                            iconBg: const Color(0xFFE6F6F6),
                            title: 'ফায়ারবেস আইডি',
                            subtitle: firebaseUid,
                          ),
                          _buildDivider(),
                          _buildInfoTile(
                            icon: Icons.tag_rounded,
                            iconColor: const Color(0xFF8E54E9),
                            iconBg: const Color(0xFFF3E8FF),
                            title: 'গুগল আইডি',
                            subtitle: providerUid,
                          ),
                        ],
                      ),

                      const SizedBox(height: 26),

                      // ৪. ইমেইল ভেরিফিকেশন ও নিরাপত্তার তথ্য
                      _buildSectionTitle(
                        'নিরাপত্তা',
                        'অ্যাকাউন্টের নিরাপত্তা',
                        Icons.shield_rounded,
                      ),
                      const SizedBox(height: 12),

                      _buildInfoCard(
                        children: [
                          _buildInfoTile(
                            icon: isEmailVerified
                                ? Icons.mark_email_read_rounded
                                : Icons.mark_email_unread_rounded,
                            iconColor: isEmailVerified
                                ? const Color(0xFF0BAA78)
                                : danger,
                            iconBg: isEmailVerified
                                ? const Color(0xFFE8FBF3)
                                : const Color(0xFFFFEEF1),
                            title: 'ইমেইল ভেরিফিকেশন',
                            subtitle: isEmailVerified
                                ? 'ভেরিফায়েড অ্যাকাউন্ট'
                                : 'ভেরিফাই করা হয়নি',
                            trailing: _buildStatusBadge(
                              isEmailVerified
                                  ? 'ভেরিফায়েড'
                                  : 'আনভেরিফায়েড',
                              isEmailVerified
                                  ? const Color(0xFF0BAA78)
                                  : danger,
                              isEmailVerified
                                  ? const Color(0xFFE8FBF3)
                                  : const Color(0xFFFFEEF1),
                            ),
                          ),
                        ],
                      ),

                      // ৫. শুধু Admin-এর জন্য Admin Control Panel
                      if (_userRole == 'admin') ...[
                        const SizedBox(height: 26),
                        _buildSectionTitle(
                          'অ্যাডমিন কন্ট্রোল',
                          'মেস পরিচালনার সেটিংস',
                          Icons.admin_panel_settings_rounded,
                        ),
                        const SizedBox(height: 12),
                        _buildAdminCard(),
                      ],

                      const SizedBox(height: 28),

                      // ৬. নিরাপদভাবে সাইন আউট করার বাটন
                      _buildLogoutButton(),

                      const SizedBox(height: 22),

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
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ৭. প্রোফাইল হেডার ডিজাইন
  // ==========================================
  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 65, 24, 32),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryDark, primary, accent],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Column(
        children: [
          // প্রোফাইল ছবির চারপাশে সাদা বর্ডার
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFE7F5F5),
              child: ClipOval(
                child: _photoUrl != null && _photoUrl!.isNotEmpty
                    ? Image.network(
                  _photoUrl!,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    // ছবি লোড না হলে ডিফল্ট আইকন দেখাবে
                    return const SizedBox(
                      width: 96,
                      height: 96,
                      child: Icon(
                        Icons.person_rounded,
                        size: 54,
                        color: primary,
                      ),
                    );
                  },
                )
                    : const SizedBox(
                  width: 96,
                  height: 96,
                  child: Icon(
                    Icons.person_rounded,
                    size: 54,
                    color: primary,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ব্যবহারকারীর নাম
          Text(
            _userName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
            ),
          ),

          const SizedBox(height: 7),

          // ব্যবহারকারীর ইমেইল
          Text(
            _userEmail,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withOpacity(0.88),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),

          const SizedBox(height: 16),

          // Member অথবা Admin পরিচিতি ব্যাজ
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withOpacity(0.45),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _userRole == 'admin'
                      ? Icons.admin_panel_settings_rounded
                      : Icons.verified_user_rounded,
                  size: 17,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  _userRole.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ৮. প্রতিটি সেকশনের শিরোনাম
  // ==========================================
  Widget _buildSectionTitle(
      String title,
      String subtitle,
      IconData icon,
      ) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: primary.withOpacity(0.09),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: primary,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: dark,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                style: const TextStyle(
                  color: muted,
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

  // ==========================================
  // ৯. সাদা rounded information card
  // ==========================================
  Widget _buildInfoCard({required List<Widget> children}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: const Color(0xFFE8EEF5),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173B55).withOpacity(0.035),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  // ==========================================
  // ১০. তথ্য দেখানোর reusable ListTile
  // ==========================================
  Widget _buildInfoTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 7,
      ),
      minLeadingWidth: 0,
      horizontalTitleGap: 13,
      leading: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          color: iconBg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: iconColor,
          size: 22,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          color: muted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 5),
        child: Text(
          subtitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: dark,
            fontSize: 13,
            fontWeight: FontWeight.w700,
            height: 1.4,
          ),
        ),
      ),
      trailing: trailing,
    );
  }

  // তথ্যের মাঝখানে হালকা Divider
  Widget _buildDivider() {
    return const Divider(
      height: 1,
      thickness: 1,
      color: Color(0xFFF0F3F7),
      indent: 72,
      endIndent: 16,
    );
  }

  // ==========================================
  // ১১. ইমেইল ভেরিফিকেশনের status badge
  // ==========================================
  Widget _buildStatusBadge(
      String label,
      Color color,
      Color background,
      ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            label == 'Verified'
                ? Icons.check_circle_rounded
                : Icons.warning_rounded,
            size: 13,
            color: color,
          ),
          const SizedBox(width: 4),
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

  // ==========================================
  // ১২. Admin Control Panel
  // ==========================================
  Widget _buildAdminCard() {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          // আগের AdminPanelScreen navigation অপরিবর্তিত
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const AdminPanelScreen(),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: const Color(0xFFE8EEF5),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFEEF1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.admin_panel_settings_rounded,
                  color: danger,
                  size: 27,
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
                        color: dark,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'মিল ও জমার হিসাব পরিচালনা',
                      style: TextStyle(
                        color: muted,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                color: muted,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ১৩. Logout Button
  // ==========================================
  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton.icon(
        // আগের AuthService signOut ফাংশন ব্যবহার করা হয়েছে
        onPressed: () async {
          try {
            await _authService.signOut();
          } catch (e) {
            if (!mounted) return;

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Sign out করা যায়নি। আবার চেষ্টা করুন।'),
              ),
            );
          }
        },
        icon: const Icon(Icons.logout_rounded, size: 21),
        label: const Text(
          'লগআউট করুন',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: danger,
          backgroundColor: Colors.white,
          side: const BorderSide(
            color: Color(0xFFFFD8DF),
            width: 1.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  // ==========================================
  // ১৪. ডেটা লোড হওয়ার সময় Loading UI
  // ==========================================
  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(22),
            ),
            child: const Center(
              child: CircularProgressIndicator(
                color: primary,
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'Loading profile...',
            style: TextStyle(
              color: dark,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'আপনার তথ্য লোড হচ্ছে',
            style: TextStyle(
              color: muted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ১৫. ডেটা লোডে সমস্যা হলে Error UI
  // ==========================================
  Widget _buildErrorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEEF1),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: danger,
                size: 38,
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'প্রোফাইল লোড করা যায়নি',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: dark,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'আবার চেষ্টা করুন।',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: muted,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _fetchUserData,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 13,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
