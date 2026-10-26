import 'package:flutter/material.dart';
import '../services/financial_service.dart';

class MembersScreen extends StatefulWidget {
  const MembersScreen({super.key});

  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
  final FinancialService _financialService = FinancialService();

  static const Color primary = Color(0xFF087F8C);
  static const Color dark = Color(0xFF173B55);
  static const Color muted = Color(0xFF7186A5);
  static const Color pageBg = Color(0xFFF3F7FF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        title: const Text('মেসের সদস্যবৃন্দ', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 22)),
        backgroundColor: Colors.white,
        foregroundColor: dark,
        elevation: 0,
        centerTitle: false,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _financialService.getAllMembersBalances(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primary));
          }

          if (snapshot.hasError) {
             return const Center(child: Text('Error loading members.', style: TextStyle(color: Colors.red)));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('কোনো সদস্য পাওয়া যায়নি।', style: TextStyle(fontSize: 16, color: muted)),
            );
          }

          final members = snapshot.data!;

          return Column(
            children: [
              // Summary Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.groups_rounded, color: primary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('মোট সদস্য', style: TextStyle(fontSize: 12, color: muted, fontWeight: FontWeight.w600)),
                        Text(
                          '${members.length} / 8',
                          style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: dark),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Member List
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    final double balance = member['netBalance'];
                    final bool isAdmin = member['role'] == 'admin';
                    final bool isPositive = balance >= 0;
                    
                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            // Avatar
                            Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: isAdmin ? const Color(0xFFFFEBF0) : const Color(0xFFF3F7FF),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                isAdmin ? Icons.admin_panel_settings_rounded : Icons.person_rounded, 
                                color: isAdmin ? const Color(0xFFFF4058) : primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            // Details
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          member['name'],
                                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: dark),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (isAdmin) ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFFF4058),
                                            borderRadius: BorderRadius.circular(6),
                                          ),
                                          child: const Text('অ্যাডমিন', style: TextStyle(fontSize: 8, color: Colors.white, fontWeight: FontWeight.bold)),
                                        ),
                                      ]
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(member['email'], style: const TextStyle(color: muted, fontSize: 11, fontWeight: FontWeight.w500)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      const Icon(Icons.restaurant_rounded, size: 12, color: muted),
                                      const SizedBox(width: 4),
                                      Text(
                                        'মিল সংখ্যা: ${member['meals'] ?? 30}',
                                        style: const TextStyle(fontSize: 11, color: muted, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  )
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Balance
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  isPositive ? '+ ৳ ${balance.toStringAsFixed(0)}' : '- ৳ ${balance.abs().toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900, 
                                    fontSize: 18, 
                                    color: isPositive ? const Color(0xFF0BB77A) : const Color(0xFFFF4058)
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isPositive ? const Color(0xFFEFFFF7) : const Color(0xFFFFF1F4),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    isPositive ? 'পাওনা' : 'দেনা',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: isPositive ? const Color(0xFF0BB77A) : const Color(0xFFFF4058),
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
