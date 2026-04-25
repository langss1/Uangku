import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/models/budget_model.dart';
import 'package:uangku_app/core/data/budget_data.dart';
import 'package:uangku_app/features/budget/screens/add_budget_screen.dart';
import 'package:intl/intl.dart';

class BudgetDetailScreen extends StatelessWidget {
  final BudgetModel budget;
  final double spent;

  const BudgetDetailScreen({super.key, required this.budget, required this.spent});

  @override
  Widget build(BuildContext context) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    final remaining = budget.amount - spent;
    
    double progress = budget.amount > 0 ? spent / budget.amount : 0;
    if (progress > 1.0) progress = 1.0;

    final now = DateTime.now();
    final totalDays = budget.endDate.difference(budget.startDate).inDays;
    final passedDays = now.difference(budget.startDate).inDays;
    double timeProgress = totalDays > 0 ? passedDays / totalDays : 0;
    if (timeProgress < 0) timeProgress = 0;
    if (timeProgress > 1.0) timeProgress = 1.0;

    final daysLeft = budget.endDate.difference(now).inDays;

    final recommendedDaily = totalDays > 0 ? budget.amount / totalDays : budget.amount;
    final actualDaily = passedDays > 0 ? spent / passedDays : spent;

    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Budget Details',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined, color: AppColors.textDark),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddBudgetScreen(existingBudget: budget)),
              );
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.textDark),
            onPressed: () {
              BudgetData().removeBudget(budget.id);
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Info
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: budget.bgColor,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(budget.icon, color: budget.iconColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        budget.category,
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Text(
                    format.format(budget.amount),
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Spent', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            format.format(spent),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Remaining', style: TextStyle(color: Color(0xFF64748B), fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            format.format(remaining < 0 ? 0 : remaining),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.textDark),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Progress Bar
                  LayoutBuilder(
                    builder: (context, constraints) {
                      return Stack(
                        clipBehavior: Clip.none,
                        alignment: Alignment.centerLeft,
                        children: [
                          Container(
                            width: double.infinity,
                            height: 8,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Container(
                            width: constraints.maxWidth * progress,
                            height: 8,
                            decoration: BoxDecoration(
                              color: AppColors.primaryBlue,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          Positioned(
                            left: constraints.maxWidth * timeProgress - 1,
                            top: -4,
                            child: Container(
                              width: 2,
                              height: 16,
                              color: const Color(0xFF94A3B8),
                            ),
                          ),
                          Positioned(
                            left: constraints.maxWidth * timeProgress - 20,
                            top: 14,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'Today',
                                style: TextStyle(fontSize: 10, color: Color(0xFF64748B)),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 40),
                  // Dates Info
                  Row(
                    children: [
                      const Icon(Icons.calendar_month, color: Color(0xFF94A3B8), size: 24),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${DateFormat('dd/MM/yyyy').format(budget.startDate)} - ${DateFormat('dd/MM/yyyy').format(budget.endDate)}',
                            style: const TextStyle(fontSize: 16, color: AppColors.textDark),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${daysLeft > 0 ? daysLeft : 0} days left',
                            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Line Chart & Details
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dummy Line Chart
                  SizedBox(
                    height: 150,
                    width: double.infinity,
                    child: CustomPaint(
                      painter: SimpleChartPainter(
                        maxAmount: budget.amount,
                        spentAmount: spent,
                        timeProgress: timeProgress,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(DateFormat('dd/MM/yyyy').format(budget.startDate), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                      Text(DateFormat('dd/MM/yyyy').format(budget.endDate), style: const TextStyle(fontSize: 10, color: Color(0xFF94A3B8))),
                    ],
                  ),
                  const SizedBox(height: 32),
                  _buildDetailRow('Recommended daily spending', format.format(recommendedDaily)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Spending projection', format.format(actualDaily * totalDays)),
                  const SizedBox(height: 16),
                  _buildDetailRow('Actual daily spending', format.format(actualDaily)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
        ),
        const SizedBox(width: 16),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
        ),
      ],
    );
  }
}

class SimpleChartPainter extends CustomPainter {
  final double maxAmount;
  final double spentAmount;
  final double timeProgress;

  SimpleChartPainter({required this.maxAmount, required this.spentAmount, required this.timeProgress});

  @override
  void paint(Canvas canvas, Size size) {
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1;

    // Draw horizontal grid lines
    for (int i = 0; i <= 5; i++) {
      final y = size.height * (i / 5);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Limit Line (Red)
    final limitPaint = Paint()
      ..color = const Color(0xFFEF4444)
      ..strokeWidth = 2;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), limitPaint);

    // Baseline (Green)
    final basePaint = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), basePaint);

    // Current Spent Line (Blue)
    final spendY = size.height - (size.height * (spentAmount / (maxAmount > 0 ? maxAmount : 1)).clamp(0.0, 1.0));
    final spendX = size.width * timeProgress;
    
    final spendPaint = Paint()
      ..color = AppColors.primaryBlue
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(spendX, spendY);
    canvas.drawPath(path, spendPaint);
    
    // Draw dot
    final dotPaint = Paint()..color = AppColors.primaryBlue;
    canvas.drawCircle(Offset(spendX, spendY), 4, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
