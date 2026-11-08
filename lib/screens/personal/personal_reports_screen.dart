import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';

import '../../core/constants/app_colors.dart';
import '../../models/personal_transaction_model.dart';
import '../../services/personal_finance_service.dart';

class PersonalReportsScreen extends StatefulWidget {
  const PersonalReportsScreen({super.key});

  @override
  State<PersonalReportsScreen> createState() => _PersonalReportsScreenState();
}

class _PersonalReportsScreenState extends State<PersonalReportsScreen> {
  final PersonalFinanceService _financeService = PersonalFinanceService();
  List<PersonalTransactionModel> _latestTxs = [];
  final GlobalKey _reportKey = GlobalKey();
  bool _isCapturing = false;

  Future<void> _downloadCsvReport() async {
    try {
      final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
      final monthlyTxs = _latestTxs
          .where((t) => DateFormat('yyyy-MM').format(t.transactionDate) == currentMonth)
          .toList();

      if (monthlyTxs.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('এই মাসে ডাউনলোড করার মতো কোনো লেনদেন নেই!'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      StringBuffer csvContent = StringBuffer();
      csvContent.writeln('ID,Date,Type,Amount (BDT),Category,Description,Status');

      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
      for (var tx in monthlyTxs) {
        String dateStr = dateFormat.format(tx.transactionDate);
        String type = tx.type;
        double amount = tx.amountInTaka;
        String category = '"${tx.categoryName.replaceAll('"', '""')}"';
        String desc = '"${tx.description.replaceAll('"', '""')}"';
        String status = tx.status;

        csvContent.writeln('${tx.id},$dateStr,$type,$amount,$category,$desc,$status');
      }

      final directory = await getApplicationDocumentsDirectory();
      final String monthStr = DateFormat('yyyy_MM').format(DateTime.now());
      final String filePath = '${directory.path}/personal_financial_report_$monthStr.csv';

      final File file = File(filePath);
      await file.writeAsString(csvContent.toString());

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 26),
              SizedBox(width: 10),
              Text('CSV রিপোর্ট ডাউনলোড সফল!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ফাইলটি ডিভাইসের নিচের ফোল্ডারে সেভ করা হয়েছে:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: SelectableText(
                  filePath,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(height: 12),
              Text('মোট লেনদেন: ${monthlyTxs.length} টি', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: csvContent.toString()));
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('CSV ডাটা ক্লিপবোর্ডে কপি করা হয়েছে!'),
                    backgroundColor: AppColors.success,
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              label: const Text('কপি করুন'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('ঠিক আছে'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('CSV ডাউনলোড ব্যর্থ হয়েছে: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Future<void> _downloadImageReport() async {
    try {
      setState(() => _isCapturing = true);
      await Future.delayed(const Duration(milliseconds: 120)); // Allow widget render

      RenderRepaintBoundary boundary = _reportKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await getApplicationDocumentsDirectory();
      final String monthStr = DateFormat('yyyy_MM').format(DateTime.now());
      final String filePath = '${directory.path}/personal_financial_summary_$monthStr.png';

      final File file = File(filePath);
      await file.writeAsBytes(pngBytes);

      setState(() => _isCapturing = false);

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.image_rounded, color: AppColors.success, size: 26),
              SizedBox(width: 10),
              Text('ইমেজ রিপোর্ট ডাউনলোড সফল!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ভিজ্যুয়াল রিপোর্ট ইমেজটি ডিভাইসের নিচের ফোল্ডারে সেভ হয়েছে:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.border),
                ),
                child: SelectableText(
                  filePath,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text('ঠিক আছে'),
            ),
          ],
        ),
      );
    } catch (e) {
      setState(() => _isCapturing = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('ইমেজ ডাউনলোড ব্যর্থ হয়েছে: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    String currentMonthName = DateFormat('MMMM yyyy').format(DateTime.now());

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('আর্থিক রিপোর্ট ও বিশ্লেষণ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.primary),
            tooltip: 'CSV রিপোর্ট ডাউনলোড',
            onPressed: _downloadCsvReport,
          ),
        ],
      ),
      body: StreamBuilder<List<PersonalTransactionModel>>(
        stream: _financeService.getTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.accent));
          }

          _latestTxs = snapshot.data ?? [];
          final currentMonth = DateFormat('yyyy-MM').format(DateTime.now());
          final monthlyTxs = _latestTxs.where((t) => DateFormat('yyyy-MM').format(t.transactionDate) == currentMonth).toList();

          double totalIncome = 0.0;
          double totalExpense = 0.0;
          Map<String, double> categoryExpenses = {};

          for (var tx in monthlyTxs) {
            if (tx.type == 'income') {
              totalIncome += tx.amountInTaka;
            } else if (tx.type == 'expense') {
              totalExpense += tx.amountInTaka;
              categoryExpenses[tx.categoryName] = (categoryExpenses[tx.categoryName] ?? 0.0) + tx.amountInTaka;
            } else if (tx.type == 'refund') {
              totalExpense -= tx.amountInTaka;
            }
          }

          double netCashFlow = totalIncome - totalExpense;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ============================================================
                // 📸 DEDICATED VISUAL REPORT EXPORT & IMAGE DOWNLOAD SECTION
                // ============================================================
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withValues(alpha: 0.12),
                        AppColors.accent.withValues(alpha: 0.06),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.06),
                        blurRadius: 15,
                        offset: const Offset(0, 6),
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
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ভিজ্যুয়াল রিপোর্ট এক্সপোর্ট ও ডাউনলোড',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'ডেটাবেস থেকে আপনার আর্থিক সারাংশ ইমেজ বা CSV হিসেবে সেভ করুন',
                                  style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.surface,
                                foregroundColor: AppColors.primary,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                  side: const BorderSide(color: AppColors.primary, width: 1.2),
                                ),
                              ),
                              onPressed: _downloadCsvReport,
                              icon: const Icon(Icons.table_chart_rounded, size: 18),
                              label: const Text('CSV ফাইল', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: _isCapturing ? null : _downloadImageReport,
                              icon: _isCapturing
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : const Icon(Icons.image_rounded, size: 18),
                              label: Text(_isCapturing ? 'তৈরি হচ্ছে...' : 'ইমেজ (PNG)', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Period Title Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('রিপোর্টের সময়কাল', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 4),
                          Text(currentMonthName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      const Icon(Icons.calendar_month_rounded, color: AppColors.primary, size: 28),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ============================================================
                // 📊 REPAINT BOUNDARY WRAPPED CARD FOR IMAGE SNAPSHOT
                // ============================================================
                RepaintBoundary(
                  key: _reportKey,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: AppColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('ক্যাশ ফ্লো সারসংক্ষেপ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                            Text(currentMonthName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _ReportMetric(
                                title: 'সর্বমোট আয়',
                                amount: totalIncome,
                                color: AppColors.success,
                              ),
                            ),
                            Container(width: 1, height: 40, color: AppColors.border),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.only(left: 16),
                                child: _ReportMetric(
                                  title: 'সর্বমোট খরচ',
                                  amount: totalExpense,
                                  color: AppColors.danger,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 30, color: AppColors.border),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('নিট সঞ্চয় / ক্যাশ ফ্লো:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                            Text(
                              '৳${netCashFlow.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 20,
                                color: netCashFlow >= 0 ? AppColors.success : AppColors.danger,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Top Spending Categories
                const Text('সর্বোচ্চ খরচের ক্যাটাগরি', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                const SizedBox(height: 12),

                if (categoryExpenses.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(child: Text('এই মাসে কোনো খরচের রেকর্ড নেই।')),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: categoryExpenses.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final entry = categoryExpenses.entries.elementAt(index);
                      final percent = totalExpense > 0 ? (entry.value / totalExpense * 100) : 0.0;

                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(Icons.pie_chart_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(entry.key, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary)),
                                  const SizedBox(height: 4),
                                  Text('মোট খরচের ${percent.toStringAsFixed(1)}%', style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                ],
                              ),
                            ),
                            Text('৳${entry.value.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                          ],
                        ),
                      );
                    },
                  ),

                const SizedBox(height: 24),

                // ============================================================
                // 📋 LINE-BY-LINE DETAILED TRANSACTION & DEPOSIT HISTORY
                // ============================================================
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('লেনদেন ও জমার বিস্তারিত ইতিহাস', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                    Text('(${monthlyTxs.length} টি)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 12),

                if (monthlyTxs.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Center(child: Text('এই মাসে কোনো লেনদেন বা জমার রেকর্ড নেই।')),
                  )
                else
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: monthlyTxs.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final tx = monthlyTxs[index];
                      final isIncome = tx.type == 'income' || tx.type == 'refund';
                      final amountColor = isIncome ? AppColors.success : AppColors.danger;
                      final sign = isIncome ? '+' : '-';
                      final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(tx.transactionDate);

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: amountColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                color: amountColor,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    tx.categoryName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    tx.description.isNotEmpty ? tx.description : 'বিবরণ নেই',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    dateStr,
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '$sign৳${tx.amountInTaka.toStringAsFixed(0)}',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: amountColor),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  final String title;
  final double amount;
  final Color color;

  const _ReportMetric({
    required this.title,
    required this.amount,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('৳${amount.toStringAsFixed(0)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }
}
