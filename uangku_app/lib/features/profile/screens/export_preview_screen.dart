import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:uangku_app/core/models/transaction_model.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportPreviewScreen extends StatefulWidget {
  final DateTimeRange dateRange;
  final String exportFormat;
  final String userName;
  final List<TransactionModel> transactions;
  final Uint8List? lineChartImage;
  final Uint8List? pieChartImage;

  const ExportPreviewScreen({
    Key? key,
    required this.dateRange,
    required this.exportFormat,
    required this.userName,
    required this.transactions,
    this.lineChartImage,
    this.pieChartImage,
  }) : super(key: key);

  @override
  State<ExportPreviewScreen> createState() => _ExportPreviewScreenState();
}

class _ExportPreviewScreenState extends State<ExportPreviewScreen> {
  bool _isExporting = false;

  Future<void> _handleExport() async {
    setState(() => _isExporting = true);

    try {
      if (widget.exportFormat == 'PDF') {
        await _exportToPdf();
      } else {
        await _exportToCsv();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Export failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _exportToPdf() async {
    final pdf = pw.Document();
    
    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        width: 36,
                        height: 36,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#2962FF'),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        child: pw.Center(
                          child: pw.Text('U', style: pw.TextStyle(color: PdfColors.white, fontSize: 24, fontWeight: pw.FontWeight.bold)),
                        ),
                      ),
                      pw.SizedBox(width: 10),
                      pw.Text('Uangku', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                    ]
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey200,
                      borderRadius: pw.BorderRadius.circular(20),
                    ),
                    child: pw.Text('FINANCIAL REPORT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  ),
                ],
              ),
              pw.SizedBox(height: 30),
              
              // Info Box
              pw.Container(
                padding: const pw.EdgeInsets.all(16),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Exported by', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
                        pw.Text(widget.userName, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        pw.SizedBox(height: 10),
                        pw.Text('Export Date', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
                        pw.Text(dateFormat.format(DateTime.now()), style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Period', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
                        pw.Text('${dateFormat.format(widget.dateRange.start)} - ${dateFormat.format(widget.dateRange.end)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                        pw.SizedBox(height: 10),
                        pw.Text('Total Transactions', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 10)),
                        pw.Text('${widget.transactions.length} items', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      ],
                    ),
                  ]
                )
              ),
              pw.SizedBox(height: 30),
              
              // Table
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Description', 'Category', 'Type', 'Amount'],
                data: widget.transactions.map((tx) => [
                  DateFormat('yyyy-MM-dd').format(tx.date),
                  tx.title,
                  tx.category,
                  tx.isIncome ? 'Income' : 'Expense',
                  currencyFormat.format(tx.amount),
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 12),
                headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#2962FF')),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                cellStyle: const pw.TextStyle(fontSize: 11),
                cellAlignment: pw.Alignment.centerLeft,
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              ),
              
              if (widget.lineChartImage != null || widget.pieChartImage != null)
                pw.SizedBox(height: 30),
              
              if (widget.lineChartImage != null) ...[
                pw.Text('Income vs Expense Trend', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  child: pw.Image(pw.MemoryImage(widget.lineChartImage!), fit: pw.BoxFit.contain),
                ),
                pw.SizedBox(height: 20),
              ],

              if (widget.pieChartImage != null) ...[
                pw.Text('Spending by Category', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
                pw.SizedBox(height: 10),
                pw.Container(
                  width: double.infinity,
                  child: pw.Image(pw.MemoryImage(widget.pieChartImage!), fit: pw.BoxFit.contain),
                ),
              ],
            ];
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/UANGKU_Report.pdf');
    await file.writeAsBytes(bytes);

    // Share / Save to device
    await Share.shareXFiles([XFile(file.path)], text: 'Here is your financial report.');
  }

  Future<void> _exportToCsv() async {
    List<List<dynamic>> rows = [];
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);

    // Header metadata
    rows.add(['==============================================']);
    rows.add(['            UANGKU FINANCIAL REPORT           ']);
    rows.add(['==============================================']);
    rows.add(['Exported by:', widget.userName]);
    rows.add(['Export Date:', DateFormat('dd MMM yyyy HH:mm').format(DateTime.now())]);
    rows.add(['Date Range:', '${DateFormat('dd MMM yyyy').format(widget.dateRange.start)} - ${DateFormat('dd MMM yyyy').format(widget.dateRange.end)}']);
    rows.add(['Total Items:', widget.transactions.length.toString()]);
    rows.add(['']);
    rows.add(['==============================================']);
    rows.add(['             TRANSACTION HISTORY              ']);
    rows.add(['==============================================']);

    // Table Header
    rows.add(['Date', 'Time', 'Description', 'Category', 'Type', 'Amount (IDR)']);

    // Table Data
    for (var tx in widget.transactions) {
      rows.add([
        DateFormat('yyyy-MM-dd').format(tx.date),
        DateFormat('HH:mm:ss').format(tx.date),
        tx.title,
        tx.category,
        tx.isIncome ? 'Income' : 'Expense',
        tx.amount.toInt().toString(), // Use raw number for easier spreadsheet calculations
      ]);
    }

    // Add Summary Section
    rows.add(['']);
    rows.add(['==============================================']);
    rows.add(['                   SUMMARY                    ']);
    rows.add(['==============================================']);
    rows.add(['']);

    // Category Spending Summary
    Map<String, double> categorySums = {};
    for (var tx in widget.transactions) {
      if (!tx.isIncome) {
        categorySums[tx.category] = (categorySums[tx.category] ?? 0) + tx.amount;
      }
    }
    
    rows.add(['--- SPENDING BY CATEGORY ---']);
    rows.add(['Category', 'Total Amount (IDR)']);
    categorySums.forEach((category, amount) {
      rows.add([category, amount.toInt().toString()]);
    });

    rows.add(['']);

    // Income vs Expense Summary
    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in widget.transactions) {
      if (tx.isIncome) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }
    
    rows.add(['--- TOTAL SUMMARY ---']);
    rows.add(['Type', 'Total Amount (IDR)']);
    rows.add(['Total Income', totalIncome.toInt().toString()]);
    rows.add(['Total Expense', totalExpense.toInt().toString()]);
    rows.add(['Net Balance', (totalIncome - totalExpense).toInt().toString()]);


    String csv = rows.map((row) {
      return row.map((item) {
        String str = item.toString();
        if (str.contains(',') || str.contains('"') || str.contains('\n')) {
          str = '"${str.replaceAll('"', '""')}"';
        }
        return str;
      }).join(',');
    }).join('\n');

    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/UANGKU_Report.csv');
    await file.writeAsString(csv);

    // Share / Save to device
    await Share.shareXFiles([XFile(file.path)], text: 'Here is your financial CSV report.');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light grey background
      appBar: AppBar(
        title: const Text('Export Preview', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: _buildPaperPreview(),
              ),
            ),
          ),
          _buildBottomAction(),
        ],
      ),
    );
  }

  Widget _buildPaperPreview() {
    final dateFormat = DateFormat('dd MMM yyyy');
    final currencyFormat = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 800),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header / Logo
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Image.asset(
                      'assets/images/logo.png',
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback in case logo is missing
                        return Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2962FF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Center(
                            child: Text('U', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    const Flexible(
                      child: Text(
                        'Uangku',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 23,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Text(
                  widget.exportFormat == 'PDF' ? 'PDF REPORT' : 'CSV EXPORT',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11, color: Color(0xFF475569), letterSpacing: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Metadata Box
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Exported by', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(widget.userName, style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                      const SizedBox(height: 16),
                      const Text('Export Date', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(dateFormat.format(DateTime.now()), style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Period', style: TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text('${dateFormat.format(widget.dateRange.start)}\n${dateFormat.format(widget.dateRange.end)}', style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B), fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Transaction Table
          const Text('TRANSACTIONS', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF94A3B8), letterSpacing: 1)),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: const Color(0xFFE2E8F0)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  headingRowColor: MaterialStateProperty.all(const Color(0xFFF1F5F9)),
                  dataRowColor: MaterialStateProperty.resolveWith<Color>((Set<MaterialState> states) {
                    return Colors.white; // We'll alternate colors manually if needed
                  }),
                columnSpacing: 24,
                horizontalMargin: 20,
                headingTextStyle: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF475569), fontSize: 13),
                dataTextStyle: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w500),
                columns: const [
                  DataColumn(label: Text('Date')),
                  DataColumn(label: Text('Description')),
                  DataColumn(label: Text('Category')),
                  DataColumn(label: Text('Type')),
                  DataColumn(label: Text('Amount')),
                ],
                rows: widget.transactions.asMap().entries.map((entry) {
                  int idx = entry.key;
                  TransactionModel tx = entry.value;
                  String typeStr = tx.isIncome ? 'Income' : 'Expense';
                  return DataRow(
                    color: MaterialStateProperty.all(idx % 2 == 0 ? Colors.white : const Color(0xFFF8FAFC)),
                    cells: [
                      DataCell(Text(DateFormat('dd MMM').format(tx.date))),
                      DataCell(Text(tx.title, style: const TextStyle(fontWeight: FontWeight.bold))),
                      DataCell(Text(tx.category)),
                      DataCell(
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: tx.isIncome ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            typeStr, 
                            style: TextStyle(
                              fontSize: 11, 
                              fontWeight: FontWeight.bold,
                              color: tx.isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626)
                            ),
                          ),
                        ),
                      ),
                      DataCell(Text(currencyFormat.format(tx.amount))),
                    ],
                  );
                }).toList(),
              ),
            ),
            ),
          ),
          if (widget.exportFormat == 'PDF' && (widget.lineChartImage != null || widget.pieChartImage != null))
            const SizedBox(height: 32),
          
          if (widget.exportFormat == 'PDF' && widget.lineChartImage != null) ...[
            const Text('Income vs Expense Trend', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Image.memory(widget.lineChartImage!, fit: BoxFit.contain),
            ),
            const SizedBox(height: 24),
          ],

          if (widget.exportFormat == 'PDF' && widget.pieChartImage != null) ...[
            const Text('Spending by Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black87)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: Image.memory(widget.pieChartImage!, fit: BoxFit.contain),
            ),
          ],
          
          const SizedBox(height: 40),
          const Center(
            child: Text(
              'End of Report',
              style: TextStyle(color: Colors.black38, fontSize: 12, fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomAction() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isExporting ? null : () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  side: const BorderSide(color: Colors.grey),
                ),
                child: const Text('Cancel', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _isExporting ? null : _handleExport,
                icon: _isExporting 
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Icon(widget.exportFormat == 'PDF' ? Icons.picture_as_pdf : Icons.insert_drive_file, color: Colors.white, size: 20),
                label: Text(
                  _isExporting ? 'Exporting...' : 'Save Document',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
