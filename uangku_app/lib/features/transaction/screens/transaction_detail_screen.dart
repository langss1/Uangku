import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/models/transaction_model.dart';
import 'package:uangku_app/core/data/transaction_data.dart';
import 'package:uangku_app/features/transaction/screens/add_transaction_screen.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class TransactionDetailScreen extends StatelessWidget {
  final String transactionId;

  const TransactionDetailScreen({super.key, required this.transactionId});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<List<TransactionModel>>(
      valueListenable: TransactionData().transactionsNotifier,
      builder: (context, transactions, _) {
        final txIndex = transactions.indexWhere((t) => t.id == transactionId);
        if (txIndex == -1) {
          // Transaction not found or deleted
          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            body: const Center(child: Text("Transaction not found")),
          );
        }
        
        final tx = transactions[txIndex];

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
              'Transaction Detail',
              style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.more_vert, color: AppColors.textDark),
                onPressed: () {},
              ),
            ],
          ),
          body: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: tx.bgColor,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(tx.icon, color: tx.iconColor, size: 36),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '${tx.isIncome ? '' : '-'}${_formatLongCurrency(tx.amount)}',
                    style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tx.isIncome ? 'Income' : 'Expense',
                    style: const TextStyle(
                      fontSize: 16,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Details Box
                  Container(
                    padding: const EdgeInsets.all(24),
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
                        const Text(
                          'Transaction Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDark,
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildDetailRow(
                          icon: Icons.category, // using generic if category icon not used
                          iconBgColor: tx.bgColor,
                          iconColor: tx.iconColor,
                          label: 'Category',
                          value: tx.category,
                          originalIcon: tx.icon,
                        ),
                        const Divider(height: 32, color: Color(0xFFF1F5F9)),
                        _buildDetailRow(
                          icon: Icons.calendar_today,
                          iconBgColor: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF3B82F6),
                          label: 'Date',
                          value: DateFormat('dd MMM yyyy').format(tx.date),
                        ),
                        const Divider(height: 32, color: Color(0xFFF1F5F9)),
                        _buildDetailRow(
                          icon: Icons.access_time,
                          iconBgColor: const Color(0xFFEFF6FF),
                          iconColor: const Color(0xFF3B82F6),
                          label: 'Time',
                          value: DateFormat('HH:mm').format(tx.date),
                        ),
                        const Divider(height: 32, color: Color(0xFFF1F5F9)),
                        _buildDetailRow(
                          icon: Icons.note,
                          iconBgColor: const Color(0xFFF1F5F9),
                          iconColor: const Color(0xFF64748B),
                          label: 'Note',
                          value: tx.note.isNotEmpty ? tx.note : '-',
                        ),
                        if (tx.imagePath != null) ...[
                          const Divider(height: 32, color: Color(0xFFF1F5F9)),
                          const Text(
                            'Attachment',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.textLight,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(
                              File(tx.imagePath!),
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Action Buttons
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AddTransactionScreen(
                              transactionToEdit: tx,
                              onBack: () => Navigator.pop(context),
                            ),
                          ),
                        ).then((_) {
                          // The edit saves to global logic. This screen auto updates via ValueListenable.
                        });
                      },
                      icon: const Icon(Icons.edit, color: Colors.white, size: 20),
                      label: const Text(
                        'Edit Transaction',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        _showDeleteConfirmation(context, tx.id);
                      },
                      icon: const Icon(Icons.delete, color: Color(0xFFEF4444), size: 20),
                      label: const Text(
                        'Delete Transaction',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFFEF4444)),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFFECACA), width: 1.5),
                        backgroundColor: const Color(0xFFFEF2F2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              TransactionData().removeTransaction(id);
              Navigator.pop(ctx); // Close dialog
              Navigator.pop(context); // Go back to previous screen
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatLongCurrency(double amount) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
    return format.format(amount);
  }

  Widget _buildDetailRow({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String label,
    required String value,
    IconData? originalIcon,
  }) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: iconBgColor,
            shape: BoxShape.circle,
          ),
          child: Icon(originalIcon ?? icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textDark,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
