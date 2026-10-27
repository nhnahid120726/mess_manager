import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RecurringBillsScreen extends StatefulWidget {
  const RecurringBillsScreen({super.key});

  @override
  State<RecurringBillsScreen> createState() => _RecurringBillsScreenState();
}

class _RecurringBillsScreenState extends State<RecurringBillsScreen> {
  final List<Map<String, dynamic>> _defaultBills = [
    {
      'title': 'বাসা ভাড়া / মেস ভাড়া',
      'amount': '৳ 12,000',
      'dueDate': 'প্রতি মাসের ৫ তারিখ',
      'category': 'Housing',
      'icon': Icons.home_rounded,
      'color': Colors.orange,
    },
    {
      'title': 'ইন্টারনেট ও ওয়াইফাই বিল',
      'amount': '৳ 1,000',
      'dueDate': 'প্রতি মাসের ১০ তারিখ',
      'category': 'Utilities',
      'icon': Icons.wifi_rounded,
      'color': Colors.blue,
    },
    {
      'title': 'বিদ্যুৎ ও গ্যাস বিল',
      'amount': '৳ 2,500',
      'dueDate': 'প্রতি মাসের ১৫ তারিখ',
      'category': 'Utilities',
      'icon': Icons.bolt_rounded,
      'color': Colors.amber,
    },
    {
      'title': 'মোবাইল রিচার্জ প্যাক',
      'amount': '৳ 500',
      'dueDate': 'প্রতি মাসের ১ তারিখ',
      'category': 'Mobile',
      'icon': Icons.smartphone_rounded,
      'color': Colors.teal,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('মাসিক নির্ধারিত বিল ও রিমাইন্ডার', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _defaultBills.length,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final bill = _defaultBills[index];

          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (bill['color'] as Color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(bill['icon'] as IconData, color: bill['color'] as Color, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(bill['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                      const SizedBox(height: 4),
                      Text('তারিখ: ${bill['dueDate']}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(bill['amount'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                    const SizedBox(height: 6),
                    ElevatedButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('${bill['title']} পরিশোধিত হিসেবে চিহ্নিত হয়েছে!'), backgroundColor: AppColors.success),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success.withValues(alpha: 0.15),
                        foregroundColor: AppColors.success,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text('পরিশোধিত', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
