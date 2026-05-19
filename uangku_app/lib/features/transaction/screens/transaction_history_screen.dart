import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/models/transaction_model.dart';
import 'package:uangku_app/core/data/transaction_data.dart';
import 'package:uangku_app/features/transaction/screens/transaction_detail_screen.dart';
import 'package:uangku_app/features/transaction/screens/add_transaction_screen.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  DateTime? _selectedFilterDate;

  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions) {
    if (_selectedFilterDate == null) {
      final now = DateTime.now();
      return transactions.where((tx) {
        return tx.date.year == now.year && tx.date.month == now.month;
      }).toList();
    }
    
    return transactions.where((tx) {
      return tx.date.year == _selectedFilterDate!.year &&
             tx.date.month == _selectedFilterDate!.month &&
             tx.date.day == _selectedFilterDate!.day;
    }).toList();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedFilterDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primaryBlue,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedFilterDate = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(''),
        centerTitle: true,
        actions: [
          if (_selectedFilterDate != null)
            IconButton(
              icon: const Icon(Icons.filter_alt_off, color: Colors.white),
              onPressed: () {
                setState(() {
                  _selectedFilterDate = null;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.calendar_month, color: Colors.white),
            onPressed: _pickDate,
          ),
        ],
      ),
      body: ValueListenableBuilder<List<TransactionModel>>(
        valueListenable: TransactionData().transactionsNotifier,
        builder: (context, transactions, child) {
          final filteredTx = _filterTransactions(transactions);
          return Column(
            children: [
              _buildTopSection(filteredTx),
              Expanded(
                child: _buildTransactionList(filteredTx),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddTransactionScreen(
                onBack: () => Navigator.pop(context),
              ),
            ),
          );
        },
        backgroundColor: AppColors.primaryBlue,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTopSection(List<TransactionModel> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;
    for (var tx in transactions) {
      if (tx.isIncome) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }
    double totalBalance = totalIncome - totalExpense;
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.only(top: 12, bottom: 16, left: 24, right: 24),
      decoration: const BoxDecoration(
        color: AppColors.primaryBlue,
      ),
      child: Column(
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            format.format(totalBalance),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_selectedFilterDate != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                DateFormat('dd MMM yyyy').format(_selectedFilterDate!),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                DateFormat('MMMM yyyy').format(DateTime.now()),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Income', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      format.format(totalIncome),
                      style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 32,
                color: Colors.white24,
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text('Expense', style: TextStyle(color: Colors.white70, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      format.format(totalExpense),
                      style: const TextStyle(color: Color(0xFFFECACA), fontSize: 18, fontWeight: FontWeight.bold),
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

  Widget _buildTransactionList(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return Container(
        color: context.scaffoldBackgroundColor,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_outlined,
                  size: 64,
                  color: Colors.grey[400],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Belum Ada Transaksi',
                style: TextStyle(
                  color: const Color(0xFF475569),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Transaksi Anda akan muncul di sini.',
                style: TextStyle(
                  color: const Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group by date
    final groupedTransactions = <String, List<TransactionModel>>{};
    for (var tx in transactions) {
      String dateKey;
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final yesterday = today.subtract(const Duration(days: 1));
      final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);

      if (txDate == today) {
        dateKey = 'Today\n${DateFormat('MMMM yyyy').format(tx.date)}';
      } else if (txDate == yesterday) {
        dateKey = 'Yesterday\n${DateFormat('MMMM yyyy').format(tx.date)}';
      } else {
        dateKey = '${DateFormat('EEEE').format(tx.date)}\n${DateFormat('MMMM yyyy').format(tx.date)}';
      }

      final fullDateKey = '${tx.date.year}${tx.date.month.toString().padLeft(2, '0')}${tx.date.day.toString().padLeft(2, '0')}|${tx.date.day.toString().padLeft(2, '0')}|$dateKey';
      
      if (!groupedTransactions.containsKey(fullDateKey)) {
        groupedTransactions[fullDateKey] = [];
      }
      groupedTransactions[fullDateKey]!.add(tx);
    }

    final sortedKeys = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // sort descending roughly

    return Container(
      color: context.scaffoldBackgroundColor,
      child: ListView.builder(
        padding: const EdgeInsets.only(top: 16, bottom: 100),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final key = sortedKeys[index];
          final parts = key.split('|');
          final dayStr = parts[1];
          final descStr = parts[2];
          final dayTxs = groupedTransactions[key]!;

          double dayTotal = 0;
          for (var tx in dayTxs) {
            if (tx.isIncome) dayTotal += tx.amount;
            else dayTotal -= tx.amount;
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Date Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    Text(
                      dayStr,
                      style: TextStyle(color: context.textPrimary, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        descStr,
                        style: TextStyle(color: context.textSecondary, fontSize: 12),
                      ),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(dayTotal),
                      style: TextStyle(color: context.textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Divider(color: context.borderColor, height: 1),
              // Items
              ...dayTxs.map((tx) => _buildTransactionItem(context, tx)).toList(),
              Divider(color: context.borderColor, height: 1),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel tx) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(transactionId: tx.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: tx.bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(tx.icon, color: tx.iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tx.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (tx.imagePath != null) ...[
                        Icon(Icons.image, size: 14, color: context.textSecondary),
                        const SizedBox(width: 4),
                      ],
                      Expanded(
                        child: Text(
                          tx.note.isNotEmpty ? tx.note : tx.category,
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(tx.amount),
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: tx.isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
