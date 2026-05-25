import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';

class TransactionSuccessScreen extends StatelessWidget {
  final VoidCallback onViewHistory;
  final VoidCallback onAddAnother;

  const TransactionSuccessScreen({
    super.key,
    required this.onViewHistory,
    required this.onAddAnother,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'Transaction Saved',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: context.isDarkMode ? Colors.grey[800] : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.close, color: context.textPrimary, size: 16),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primaryBlue.withOpacity(0.3),
                    spreadRadius: 5,
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 50),
            ),
            const SizedBox(height: 48),
            Text(
              'Transaction Saved',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: context.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Your transaction has been recorded\nsuccessfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: context.textSecondary,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onViewHistory,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  'View Transaction History',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: OutlinedButton(
                onPressed: onAddAnother,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Add Another Transaction',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.primaryBlue),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
