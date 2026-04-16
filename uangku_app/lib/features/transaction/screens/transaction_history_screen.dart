import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/models/transaction_model.dart';
import 'package:uangku_app/core/data/transaction_data.dart';
import 'package:uangku_app/features/transaction/screens/transaction_detail_screen.dart';
import 'package:intl/intl.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  DateTime? _selectedDate;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Transactions',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month, color: AppColors.primaryBlue),
            onPressed: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: AppColors.primaryBlue, // header background color
                        onPrimary: Colors.white, // header text color
                        onSurface: AppColors.textDark, // body text color
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primaryBlue, // button text color
                        ),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _selectedDate = picked;
                });
              }
            },
          ),
          if (_selectedDate != null)
            IconButton(
              icon: const Icon(Icons.clear, color: Colors.redAccent),
              onPressed: () {
                setState(() {
                  _selectedDate = null;
                });
              },
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ValueListenableBuilder<List<TransactionModel>>(
        valueListenable: TransactionData().transactionsNotifier,
        builder: (context, transactions, child) {
          
          // Apply calendar filter
          var filteredTransactions = transactions;
          if (_selectedDate != null) {
            filteredTransactions = transactions.where((tx) {
              return tx.date.year == _selectedDate!.year &&
                     tx.date.month == _selectedDate!.month &&
                     tx.date.day == _selectedDate!.day;
            }).toList();
          }

          double totalIncome = 0;
          double totalExpense = 0;
          for (var tx in filteredTransactions) {
            if (tx.isIncome) {
              totalIncome += tx.amount;
            } else {
              totalExpense += tx.amount;
            }
          }

          // Group by date
          final groupedTransactions = <String, List<TransactionModel>>{};
          for (var tx in filteredTransactions) {
            String dateKey;
            final now = DateTime.now();
            final today = DateTime(now.year, now.month, now.day);
            final yesterday = today.subtract(const Duration(days: 1));
            final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);

            if (txDate == today) {
              dateKey = 'Today';
            } else if (txDate == yesterday) {
              dateKey = 'Yesterday';
            } else {
              dateKey = DateFormat('MMM dd, yyyy').format(tx.date);
            }

            if (!groupedTransactions.containsKey(dateKey)) {
              groupedTransactions[dateKey] = [];
            }
            groupedTransactions[dateKey]!.add(tx);
          }
          
          final sortedKeys = groupedTransactions.keys.toList();

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Filter Active Indicator
                  if (_selectedDate != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.event_available, size: 16, color: AppColors.primaryBlue),
                            const SizedBox(width: 8),
                            Text(
                              'Showing transactions for: ${DateFormat('MMM dd, yyyy').format(_selectedDate!)}',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  // Summary Cards
                  Row(
                    children: [
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'INCOME',
                          amount: _formatCurrency(totalIncome),
                          isIncome: true,
                          dateFilterActive: _selectedDate != null,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildSummaryCard(
                          title: 'EXPENSE',
                          amount: _formatCurrency(totalExpense),
                          isIncome: false,
                          dateFilterActive: _selectedDate != null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  if (filteredTransactions.isEmpty)
                     Center(
                       child: Padding(
                         padding: const EdgeInsets.only(top: 40.0),
                         child: Column(
                           children: [
                             Icon(Icons.receipt_long, size: 64, color: Colors.grey[300]),
                             const SizedBox(height: 16),
                             Text(
                               'No transactions found',
                               style: TextStyle(color: Colors.grey[500], fontSize: 16),
                             ),
                           ],
                         ),
                       ),
                     ),

                  // List
                  ...sortedKeys.map((dateKey) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dateKey,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...groupedTransactions[dateKey]!.map((tx) {
                          return _buildTransactionItem(context, tx);
                        }).toList(),
                        const SizedBox(height: 24),
                      ],
                    );
                  }).toList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  String _formatCurrency(double amount) {
    if (amount >= 1000000) {
      return 'Rp ${(amount / 1000000).toStringAsFixed(1)}M';
    } else if (amount >= 1000) {
      return 'Rp ${(amount / 1000).toStringAsFixed(1)}K';
    }
    return 'Rp ${amount.toStringAsFixed(0)}';
  }
  
  String _formatLongCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  Widget _buildSummaryCard({required String title, required String amount, required bool isIncome, required bool dateFilterActive}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isIncome ? const Color(0xFFD1FAE5) : const Color(0xFFFEE2E2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            amount,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            dateFilterActive ? 'On this date' : 'This month',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, TransactionModel tx) {
    final timeFormat = DateFormat('hh:mm a');
    final timeString = timeFormat.format(tx.date);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TransactionDetailScreen(transactionId: tx.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.01),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
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
                      fontWeight: FontWeight.w700,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${tx.category} • $timeString',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '${tx.isIncome ? '+' : '-'}${_formatLongCurrency(tx.amount)}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: tx.isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
