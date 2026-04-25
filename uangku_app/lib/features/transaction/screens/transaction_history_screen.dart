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

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this, initialIndex: 1);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<TransactionModel> _filterTransactions(List<TransactionModel> transactions, int tabIndex) {
    final now = DateTime.now();
    return transactions.where((tx) {
      if (tabIndex == 0) {
        // Bulan Lalu
        final lastMonth = DateTime(now.year, now.month - 1);
        return tx.date.year == lastMonth.year && tx.date.month == lastMonth.month;
      } else if (tabIndex == 1) {
        // Bulan Ini
        return tx.date.year == now.year && tx.date.month == now.month;
      } else {
        // Masa Depan
        final nextMonth = DateTime(now.year, now.month + 1);
        return tx.date.year == nextMonth.year && tx.date.month == nextMonth.month;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.language, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text(
              'Total',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {},
          ),
        ],
      ),
      body: ValueListenableBuilder<List<TransactionModel>>(
        valueListenable: TransactionData().transactionsNotifier,
        builder: (context, transactions, child) {
          return Column(
            children: [
              _buildTopSection(transactions),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTransactionList(_filterTransactions(transactions, 0)),
                    _buildTransactionList(_filterTransactions(transactions, 1)),
                    _buildTransactionList(_filterTransactions(transactions, 2)),
                  ],
                ),
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
        backgroundColor: AppColors.primaryBlue, // Primary matching the design
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Widget _buildTopSection(List<TransactionModel> transactions) {
    return AnimatedBuilder(
      animation: _tabController,
      builder: (context, child) {
        final filteredTx = _filterTransactions(transactions, _tabController.index);
        
        double totalIncome = 0;
        double totalExpense = 0;
        for (var tx in filteredTx) {
          if (tx.isIncome) {
            totalIncome += tx.amount;
          } else {
            totalExpense += tx.amount;
          }
        }
        double totalBalance = totalIncome - totalExpense;
        final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

        return Container(
          padding: const EdgeInsets.only(top: 16, bottom: 0),
          decoration: const BoxDecoration(
            color: AppColors.primaryBlue,
          ),
          child: Column(
            children: [
              const Text(
                'Saldo',
                style: TextStyle(color: Colors.white70, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                format.format(totalBalance),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              
              // Tabs
              TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white54,
                tabs: const [
                  Tab(text: 'BULAN LALU'),
                  Tab(text: 'BULAN INI'),
                  Tab(text: 'MASA DEPAN'),
                ],
              ),
              
              // Summary breakdown
              Container(
                color: Colors.white.withOpacity(0.12), // Slightly lighter background
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pemasukan', style: TextStyle(color: Colors.white, fontSize: 16)),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(totalIncome),
                          style: const TextStyle(color: Color(0xFFD1FAE5), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Pengeluaran', style: TextStyle(color: Colors.white, fontSize: 16)),
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(totalExpense),
                          style: const TextStyle(color: Color(0xFFFECACA), fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Divider(color: Colors.white24, height: 1),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(totalBalance),
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTransactionList(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return Container(
        color: Colors.white,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text(
                'Tidak ada transaksi',
                style: TextStyle(color: Colors.grey[500], fontSize: 16),
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
        dateKey = 'Hari ini\n${DateFormat('MMMM yyyy').format(tx.date)}';
      } else if (txDate == yesterday) {
        dateKey = 'Kemarin\n${DateFormat('MMMM yyyy').format(tx.date)}';
      } else {
        dateKey = '${DateFormat('EEEE').format(tx.date)}\n${DateFormat('MMMM yyyy').format(tx.date)}';
      }

      final fullDateKey = '${tx.date.day.toString().padLeft(2, '0')}|$dateKey';
      
      if (!groupedTransactions.containsKey(fullDateKey)) {
        groupedTransactions[fullDateKey] = [];
      }
      groupedTransactions[fullDateKey]!.add(tx);
    }

    final sortedKeys = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a)); // sort descending roughly

    return Container(
      color: Colors.white,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
        itemCount: sortedKeys.length,
        itemBuilder: (context, index) {
          final key = sortedKeys[index];
          final parts = key.split('|');
          final dayStr = parts[0];
          final descStr = parts[1];
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
                      style: const TextStyle(color: AppColors.textDark, fontSize: 32, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        descStr,
                        style: const TextStyle(color: Color(0xFF64748B), fontSize: 12),
                      ),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(dayTotal),
                      style: const TextStyle(color: AppColors.textDark, fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
              // Items
              ...dayTxs.map((tx) => _buildTransactionItem(context, tx)).toList(),
              const Divider(color: Color(0xFFF1F5F9), height: 1),
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
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tx.note.isNotEmpty ? tx.note : tx.category,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF64748B),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
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
