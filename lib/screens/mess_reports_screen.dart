import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/constants/app_colors.dart';
import '../models/deposit_model.dart';
import '../models/expense_model.dart';
import '../services/financial_service.dart';
import '../services/auth_service.dart';

class MessReportsScreen extends StatefulWidget {
  const MessReportsScreen({super.key});

  @override
  State<MessReportsScreen> createState() => _MessReportsScreenState();
}

class _MessReportsScreenState extends State<MessReportsScreen> {
  final FinancialService _financialService = FinancialService();
  final AuthService _authService = AuthService();
  List<DepositModel> _latestDeposits = [];
  List<ExpenseModel> _latestExpenses = [];
  final GlobalKey _reportKey = GlobalKey();
  bool _isCapturing = false;

  Future<Directory?> _getDownloadDirectory() async {
    try {
      if (Platform.isAndroid) {
        final directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists()) {
          return directory;
        }
      }
      return await getExternalStorageDirectory() ?? await getApplicationDocumentsDirectory();
    } catch (_) {
      return await getApplicationDocumentsDirectory();
    }
  }

  Future<void> _downloadCsvReport() async {
    try {
      if (_latestDeposits.isEmpty && _latestExpenses.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ডাউনলোড করার মতো কোনো ব্যক্তিগত মেস ডাটা নেই!'),
            backgroundColor: AppColors.danger,
          ),
        );
        return;
      }

      StringBuffer csvContent = StringBuffer();
      csvContent.writeln('=== MY MESS DEPOSITS ===');
      csvContent.writeln('ID,MonthId,MemberEmail,Amount (BDT),PaymentMethod,Status,CreatedAt');

      final dateFormat = DateFormat('yyyy-MM-dd HH:mm');
      for (var d in _latestDeposits) {
        csvContent.writeln('${d.id},${d.monthId},${d.memberEmail},${d.amountInTaka},${d.paymentMethod},${d.status},${dateFormat.format(d.createdAt)}');
      }

      csvContent.writeln('\n=== MY MESS EXPENSE SHARES ===');
      csvContent.writeln('ID,MonthId,Date,Products,TotalAmount (BDT),PurchasedBy,PaidBy,PaymentSource');
      for (var e in _latestExpenses) {
        String prods = '"${e.products.join(', ').replaceAll('"', '""')}"';
        csvContent.writeln('${e.id},${e.monthId},${e.date},$prods,${e.totalAmountInTaka},${e.purchasedByEmail},${e.paidByEmail},${e.paymentSource}');
      }

      final directory = await _getDownloadDirectory();
      final String monthStr = DateFormat('yyyy_MM').format(DateTime.now());
      final String filePath = '${directory?.path ?? (await getApplicationDocumentsDirectory()).path}/my_mess_report_$monthStr.csv';

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
              Text('CSV ফাইল ডাউনলোড সফল!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('ফাইলটি ফোনের ডাউনলোড ফোল্ডারে সেভ হয়েছে:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
              Text('আপনার ডিপোজিট: ${_latestDeposits.length} টি | খরচ সংশ্লিষ্ট: ${_latestExpenses.length} টি', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
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
      await Future.delayed(const Duration(milliseconds: 150));

      RenderRepaintBoundary boundary = _reportKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      Uint8List pngBytes = byteData!.buffer.asUint8List();

      final directory = await _getDownloadDirectory();
      final String monthStr = DateFormat('yyyy_MM').format(DateTime.now());
      final String filePath = '${directory?.path ?? (await getApplicationDocumentsDirectory()).path}/my_mess_financial_summary_$monthStr.png';

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
              Text('ইমেজ (PNG) ডাউনলোড সফল!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('রিপোর্টের ইমেজটি সরাসরি ফোনের ডাউনলোড ফোল্ডারে সেভ হয়েছে:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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

  Future<void> _downloadPdfReport() async {
    try {
      final pdf = pw.Document();

      // Load Bengali font from assets
      final fontDataRegular = await rootBundle.load('assets/fonts/NotoSansBengali-Regular.ttf');
      final fontDataBold = await rootBundle.load('assets/fonts/NotoSansBengali-Bold.ttf');
      
      final bengaliFontRegular = pw.Font.ttf(fontDataRegular);
      final bengaliFontBold = pw.Font.ttf(fontDataBold);

      final currentMonthName = DateFormat('MMMM yyyy').format(DateTime.now());
      final currentUserEmail = _authService.currentUser?.email?.toLowerCase().trim() ?? '';

      double totalMyDeposits = _latestDeposits
          .where((d) => d.status == 'confirmed')
          .fold(0.0, (acc, d) => acc + d.amountInTaka);

      double totalMyExpenseShare = 0.0;
      for (var e in _latestExpenses) {
        List<String> shared = e.sharedBetweenEmails.map((s) => s.toLowerCase().trim()).toList();
        if (shared.isEmpty) {
          totalMyExpenseShare += e.totalAmountInTaka / 8;
        } else if (shared.contains(currentUserEmail)) {
          totalMyExpenseShare += e.totalAmountInTaka / shared.length;
        }
      }
      double myNetBalance = totalMyDeposits - totalMyExpenseShare;

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(36),
          theme: pw.ThemeData.withFont(
            base: bengaliFontRegular,
            bold: bengaliFontBold,
          ),
          footer: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.centerRight,
              margin: const pw.EdgeInsets.only(top: 20),
              child: pw.Text(
                'পৃষ্ঠা ${context.pageNumber} / ${context.pagesCount}',
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
              ),
            );
          },
          build: (pw.Context context) {
            return [
              // Top Branding / Header
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.indigo900,
                  borderRadius: pw.BorderRadius.circular(12),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('মেস ম্যানেজার রিপোর্ট', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold, color: PdfColors.white)),
                        pw.SizedBox(height: 4),
                        pw.Text('সময়কাল: $currentMonthName', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey200)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('ব্যক্তিগত আর্থিক বিবরণী', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey300)),
                        pw.SizedBox(height: 2),
                        pw.Text(DateFormat('dd MMM yyyy').format(DateTime.now()), style: const pw.TextStyle(fontSize: 11, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),

              // Financial Summary Cards
              pw.Row(
                children: [
                  _buildPdfSummaryCard('আমার মোট জমা', '৳${totalMyDeposits.toStringAsFixed(0)}', PdfColors.green800, PdfColors.green50),
                  pw.SizedBox(width: 12),
                  _buildPdfSummaryCard('আমার খরচের অংশ', '৳${totalMyExpenseShare.toStringAsFixed(0)}', PdfColors.red800, PdfColors.red50),
                  pw.SizedBox(width: 12),
                  _buildPdfSummaryCard('নিট ব্যালেন্স', '৳${myNetBalance.toStringAsFixed(0)}', myNetBalance >= 0 ? PdfColors.green800 : PdfColors.red800, myNetBalance >= 0 ? PdfColors.green50 : PdfColors.red50),
                ],
              ),
              pw.SizedBox(height: 25),

              // Deposits Table
              pw.Text('আমার জমার বিস্তারিত ইতিহাস (${_latestDeposits.length} টি)', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
              pw.SizedBox(height: 8),
              _latestDeposits.isEmpty
                  ? pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
                      child: pw.Text('এই সময়ে কোনো জমার রেকর্ড পাওয়া যায়নি।', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                    )
                  : pw.TableHelper.fromTextArray(
                      headers: ['তারিখ ও সময়', 'পেমেন্ট মাধ্যম', 'স্ট্যাটাস', 'পরিমাণ (টাকা)'],
                      data: _latestDeposits.map((d) => [
                        DateFormat('dd MMM yyyy, hh:mm a').format(d.createdAt),
                        d.paymentMethod,
                        d.status == 'confirmed' ? 'অনুমোদিত' : d.status,
                        '৳${d.amountInTaka.toStringAsFixed(0)}',
                      ]).toList(),
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
                      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
                      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                      cellStyle: const pw.TextStyle(fontSize: 11, color: PdfColors.grey900),
                      cellAlignment: pw.Alignment.centerLeft,
                      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
              pw.SizedBox(height: 25),

              // Expenses Table
              pw.Text('আমার বাজার খরচের অংশ (${_latestExpenses.length} টি)', style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
              pw.SizedBox(height: 8),
              _latestExpenses.isEmpty
                  ? pw.Container(
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
                      child: pw.Text('এই সময়ে কোনো বাজার খরচের রেকর্ড পাওয়া যায়নি।', style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
                    )
                  : pw.TableHelper.fromTextArray(
                      headers: ['তারিখ', 'পণ্যসমূহ', 'ক্রেতা', 'উৎস', 'আমার অংশ (টাকা)'],
                      data: _latestExpenses.map((e) {
                        List<String> shared = e.sharedBetweenEmails.map((s) => s.toLowerCase().trim()).toList();
                        double share = shared.isEmpty ? e.totalAmountInTaka / 8 : (shared.contains(currentUserEmail) ? e.totalAmountInTaka / shared.length : 0.0);
                        return [
                          e.date,
                          e.products.join(', '),
                          e.purchasedByEmail,
                          e.paymentSource == 'mess_fund' ? 'মেস ফান্ড' : 'ব্যক্তিগত',
                          '৳${share.toStringAsFixed(0)}',
                        ];
                      }).toList(),
                      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 11),
                      headerDecoration: const pw.BoxDecoration(color: PdfColors.indigo800),
                      rowDecoration: const pw.BoxDecoration(border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5))),
                      cellStyle: const pw.TextStyle(fontSize: 11, color: PdfColors.grey900),
                      cellAlignment: pw.Alignment.centerLeft,
                      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    ),
            ];
          },
        ),
      );

      final directory = await _getDownloadDirectory();
      final String monthStr = DateFormat('yyyy_MM').format(DateTime.now());
      final String filePath = '${directory?.path ?? (await getApplicationDocumentsDirectory()).path}/my_mess_report_$monthStr.pdf';

      final File file = File(filePath);
      await file.writeAsBytes(await pdf.save());

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.picture_as_pdf_rounded, color: AppColors.success, size: 26),
              SizedBox(width: 10),
              Text('A4 PDF রিপোর্ট ডাউনলোড সফল!', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('A4 সাইজ বাংলা PDF ফাইলটি ফোনের ডাউনলোড ফোল্ডারে সেভ হয়েছে:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF ডাউনলোড ব্যর্থ হয়েছে: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  pw.Widget _buildPdfSummaryCard(String title, String value, PdfColor textColor, PdfColor bgColor) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(12),
        decoration: pw.BoxDecoration(
          color: bgColor,
          borderRadius: pw.BorderRadius.circular(10),
          border: pw.Border.all(color: textColor.withAlpha(50)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(title, style: pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: textColor)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String currentMonthName = DateFormat('MMMM yyyy').format(DateTime.now());
    final currentUserEmail = _authService.currentUser?.email?.toLowerCase().trim() ?? '';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('আমার মেস রিপোর্ট ও হিসাব', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded, color: AppColors.primary),
            tooltip: 'A4 PDF ডাউনলোড',
            onPressed: _downloadPdfReport,
          ),
        ],
      ),
      body: StreamBuilder<List<DepositModel>>(
        stream: _financialService.getMonthlyDeposits(),
        builder: (context, depositSnapshot) {
          return StreamBuilder<List<ExpenseModel>>(
            stream: _financialService.getMonthlyExpenses(),
            builder: (context, expenseSnapshot) {
              if (depositSnapshot.connectionState == ConnectionState.waiting && !depositSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator(color: AppColors.accent));
              }

              final allDeposits = depositSnapshot.data ?? [];
              final allExpenses = expenseSnapshot.data ?? [];

              // Filter strictly for the logged-in user
              _latestDeposits = allDeposits
                  .where((d) => d.memberEmail.toLowerCase().trim() == currentUserEmail)
                  .toList();

              _latestExpenses = allExpenses
                  .where((e) =>
                      e.paidByEmail.toLowerCase().trim() == currentUserEmail ||
                      e.purchasedByEmail.toLowerCase().trim() == currentUserEmail ||
                      e.sharedBetweenEmails.map((s) => s.toLowerCase().trim()).contains(currentUserEmail))
                  .toList();

              double totalMyDeposits = _latestDeposits
                  .where((d) => d.status == 'confirmed')
                  .fold(0.0, (acc, d) => acc + d.amountInTaka);

              double totalMyExpenseShare = 0.0;
              for (var e in _latestExpenses) {
                List<String> shared = e.sharedBetweenEmails.map((s) => s.toLowerCase().trim()).toList();
                if (shared.isEmpty) {
                  totalMyExpenseShare += e.totalAmountInTaka / 8;
                } else if (shared.contains(currentUserEmail)) {
                  totalMyExpenseShare += e.totalAmountInTaka / shared.length;
                }
              }

              double myNetBalance = totalMyDeposits - totalMyExpenseShare;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ============================================================
                    // 📸 PERSONAL MESS REPORT EXPORT & IMAGE/PDF DOWNLOAD SECTION
                    // ============================================================
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1E3A8A).withValues(alpha: 0.12),
                            const Color(0xFF2563EB).withValues(alpha: 0.06),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFF1E3A8A).withValues(alpha: 0.3), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF1E3A8A).withValues(alpha: 0.06),
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
                                  color: const Color(0xFF1E3A8A),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.picture_as_pdf_rounded, color: Colors.white, size: 22),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'রিপোর্ট এক্সপোর্ট ও ডাউনলোড',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.textPrimary),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'A4 সাইজ বাংলা PDF, ইমেজ (PNG) অথবা CSV ফরম্যাটে তাৎক্ষণিক ডাউনলোড করুন',
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
                                    backgroundColor: const Color(0xFF1E3A8A),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  onPressed: _downloadPdfReport,
                                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                                  label: const Text('A4 PDF', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.surface,
                                    foregroundColor: const Color(0xFF1E3A8A),
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: const BorderSide(color: Color(0xFF1E3A8A), width: 1.2),
                                    ),
                                  ),
                                  onPressed: _isCapturing ? null : _downloadImageReport,
                                  icon: _isCapturing
                                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Color(0xFF1E3A8A), strokeWidth: 2))
                                      : const Icon(Icons.image_rounded, size: 18),
                                  label: Text(_isCapturing ? 'তৈরি...' : 'ইমেজ', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.surface,
                                    foregroundColor: Colors.grey.shade700,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                      side: BorderSide(color: Colors.grey.shade300, width: 1.2),
                                    ),
                                  ),
                                  onPressed: _downloadCsvReport,
                                  icon: const Icon(Icons.table_chart_rounded, size: 18),
                                  label: const Text('CSV', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
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
                          const Icon(Icons.calendar_month_rounded, color: Color(0xFF1E3A8A), size: 28),
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
                                const Text('আমার মেস আর্থিক সারাংশ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                                Text(currentMonthName, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _ReportMetric(
                                    title: 'আমার মোট জমা',
                                    amount: totalMyDeposits,
                                    color: AppColors.success,
                                  ),
                                ),
                                Container(width: 1, height: 40, color: AppColors.border),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 16),
                                    child: _ReportMetric(
                                      title: 'আমার খরচের অংশ',
                                      amount: totalMyExpenseShare,
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
                                const Text('আমার নিট ব্যালেন্স:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary)),
                                Text(
                                  '৳${myNetBalance.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                    color: myNetBalance >= 0 ? AppColors.success : AppColors.danger,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ============================================================
                    // 📋 MY DEPOSIT HISTORY
                    // ============================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('আমার জমার বিস্তারিত ইতিহাস', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                        Text('(${_latestDeposits.length} টি)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_latestDeposits.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(child: Text('আপনার কোনো জমার রেকর্ড পাওয়া যায়নি।')),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _latestDeposits.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final dep = _latestDeposits[index];
                          final isConfirmed = dep.status == 'confirmed';
                          final statusColor = isConfirmed ? AppColors.success : AppColors.warning;
                          final dateStr = DateFormat('dd MMM yyyy, hh:mm a').format(dep.createdAt);

                          return Container(
                            padding: const EdgeInsets.all(14),
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
                                    color: AppColors.success.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.arrow_downward_rounded, color: AppColors.success, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'মেসে টাকা জমা',
                                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'মাধ্যম: ${dep.paymentMethod} • স্ট্যাটাস: ${dep.status}',
                                        style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.bold),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateStr,
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '+৳${dep.amountInTaka.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.success),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 24),

                    // ============================================================
                    // 🛒 MY EXPENSE SHARES HISTORY
                    // ============================================================
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('আমার বাজার খরচের অংশ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textPrimary)),
                        Text('(${_latestExpenses.length} টি)', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    if (_latestExpenses.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: const Center(child: Text('আপনার কোনো বাজার খরচের রেকর্ড পাওয়া যায়নি।')),
                      )
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _latestExpenses.length,
                        separatorBuilder: (context, index) => const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          final exp = _latestExpenses[index];
                          final dateStr = exp.date;
                          final productsStr = exp.products.join(', ');

                          List<String> shared = exp.sharedBetweenEmails.map((s) => s.toLowerCase().trim()).toList();
                          double myShare = 0.0;
                          if (shared.isEmpty) {
                            myShare = exp.totalAmountInTaka / 8;
                          } else if (shared.contains(currentUserEmail)) {
                            myShare = exp.totalAmountInTaka / shared.length;
                          }

                          return Container(
                            padding: const EdgeInsets.all(14),
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
                                    color: AppColors.danger.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Icon(Icons.shopping_basket_rounded, color: AppColors.danger, size: 22),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        productsStr.isNotEmpty ? productsStr : 'বাজার খরচ',
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimary),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        'ক্রেতা: ${exp.purchasedByEmail} • উৎস: ${exp.paymentSource}',
                                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        dateStr,
                                        style: TextStyle(fontSize: 10, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  '-৳${myShare.toStringAsFixed(0)}',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.danger),
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
