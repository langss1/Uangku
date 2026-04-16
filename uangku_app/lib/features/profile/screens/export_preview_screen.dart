import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportPreviewScreen extends StatefulWidget {
  final DateTimeRange dateRange;
  final String exportFormat;
  final String userName;

  const ExportPreviewScreen({
    Key? key,
    required this.dateRange,
    required this.exportFormat,
    required this.userName,
  }) : super(key: key);

  @override
  State<ExportPreviewScreen> createState() => _ExportPreviewScreenState();
}

class _ExportPreviewScreenState extends State<ExportPreviewScreen> {
  bool _isExporting = false;

  // Dummy transactions data for preview and export
  final List<Map<String, dynamic>> _dummyTransactions = [
    {'date': '2024-03-12', 'desc': 'Grocery Store', 'cat': 'Food', 'type': 'Expense', 'amount': 150000},
    {'date': '2024-03-14', 'desc': 'Salary', 'cat': 'Income', 'type': 'Income', 'amount': 5000000},
    {'date': '2024-03-15', 'desc': 'Electric Bill', 'cat': 'Utilities', 'type': 'Expense', 'amount': 300000},
    {'date': '2024-03-18', 'desc': 'Movie Ticket', 'cat': 'Entertainment', 'type': 'Expense', 'amount': 85000},
    {'date': '2024-03-20', 'desc': 'Freelance', 'cat': 'Income', 'type': 'Income', 'amount': 1200000},
  ];

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
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Header
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('UANGKU', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                  pw.Text('FINANCIAL REPORT', style: pw.TextStyle(fontSize: 18, color: PdfColors.grey700)),
                ],
              ),
              pw.SizedBox(height: 20),
              
              // Info
              pw.Text('Exported by: ${widget.userName}'),
              pw.Text('Export Date: ${dateFormat.format(DateTime.now())}'),
              pw.Text('Date Range: ${dateFormat.format(widget.dateRange.start)} - ${dateFormat.format(widget.dateRange.end)}'),
              pw.SizedBox(height: 30),
              
              // Table
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Description', 'Category', 'Type', 'Amount'],
                data: _dummyTransactions.map((tx) => [
                  tx['date'],
                  tx['desc'],
                  tx['cat'],
                  tx['type'],
                  currencyFormat.format(tx['amount']),
                ]).toList(),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.blue600),
                rowDecoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
                ),
                cellAlignment: pw.Alignment.centerLeft,
              ),
            ],
          );
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
    rows.add(['UANGKU Financial Report']);
    rows.add(['Exported by:', widget.userName]);
    rows.add(['Export Date:', DateFormat('dd MMM yyyy').format(DateTime.now())]);
    rows.add(['Date Range:', '${DateFormat('dd MMM yyyy').format(widget.dateRange.start)} - ${DateFormat('dd MMM yyyy').format(widget.dateRange.end)}']);
    rows.add([]);

    // Table Header
    rows.add(['Date', 'Description', 'Category', 'Type', 'Amount']);

    // Table Data
    for (var tx in _dummyTransactions) {
      rows.add([
        tx['date'],
        tx['desc'],
        tx['cat'],
        tx['type'],
        currencyFormat.format(tx['amount']),
      ]);
    }

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
              Row(
                children: [
                  const Icon(Icons.payments, color: Color(0xFF2962FF), size: 32),
                  const SizedBox(width: 8),
                  const Text(
                    'UANGKU',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF2962FF)),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  widget.exportFormat == 'PDF' ? 'PDF REPORT' : 'CSV EXPORT',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54),
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Metadata
          Text('Exported by: ${widget.userName}', style: const TextStyle(fontSize: 14, color: Colors.black87)),
          const SizedBox(height: 4),
          Text('Export Date: ${dateFormat.format(DateTime.now())}', style: const TextStyle(fontSize: 13, color: Colors.black87)),
          const SizedBox(height: 4),
          Text('Date Range: ${dateFormat.format(widget.dateRange.start)} - ${dateFormat.format(widget.dateRange.end)}', style: const TextStyle(fontSize: 13, color: Colors.black54)),
          
          const SizedBox(height: 32),
          
          // Transaction Table
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DataTable(
              headingRowColor: MaterialStateProperty.all(const Color(0xFFF8FAFC)),
              columnSpacing: 16,
              horizontalMargin: 12,
              columns: const [
                DataColumn(label: Text('Date', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Type', style: TextStyle(fontWeight: FontWeight.bold))),
                DataColumn(label: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold))),
              ],
              rows: _dummyTransactions.map((tx) {
                return DataRow(
                  cells: [
                    DataCell(Text(tx['date'], style: const TextStyle(fontSize: 12))),
                    DataCell(Text(tx['desc'], style: const TextStyle(fontSize: 12))),
                    DataCell(
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: tx['type'] == 'Income' ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          tx['type'], 
                          style: TextStyle(
                            fontSize: 10, 
                            color: tx['type'] == 'Income' ? const Color(0xFF059669) : const Color(0xFFDC2626)
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(currencyFormat.format(tx['amount']), style: const TextStyle(fontSize: 12))),
                  ],
                );
              }).toList(),
            ),
          ),
          
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
