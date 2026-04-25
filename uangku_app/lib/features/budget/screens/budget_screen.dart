import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/models/budget_model.dart';
import 'package:uangku_app/core/models/transaction_model.dart';
import 'package:uangku_app/core/data/budget_data.dart';
import 'package:uangku_app/core/data/transaction_data.dart';
import 'package:uangku_app/features/budget/screens/add_budget_screen.dart';
import 'package:uangku_app/features/budget/screens/budget_detail_screen.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  @override
  void initState() {
    super.initState();
    BudgetData().loadBudgets();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9), // Light background for contrast
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        title: const Text(
          'Budgets',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.white),
            onPressed: () {},
          )
        ],
      ),
      body: ValueListenableBuilder<List<BudgetModel>>(
        valueListenable: BudgetData().budgetsNotifier,
        builder: (context, budgets, _) {
          return ValueListenableBuilder<List<TransactionModel>>(
            valueListenable: TransactionData().transactionsNotifier,
            builder: (context, transactions, _) {
              
              // Calculate global metrics
              double globalTotalBudget = 0;
              double globalTotalSpent = 0;
              int daysLeft = 0;

              final now = DateTime.now();
              DateTime? closestEndDate;

              for (var budget in budgets) {
                globalTotalBudget += budget.amount;
                if (closestEndDate == null || budget.endDate.isBefore(closestEndDate)) {
                  closestEndDate = budget.endDate;
                }

                double spent = 0;
                for (var tx in transactions) {
                  if (!tx.isIncome && tx.category == budget.category) {
                    final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
                    final start = DateTime(budget.startDate.year, budget.startDate.month, budget.startDate.day);
                    final end = DateTime(budget.endDate.year, budget.endDate.month, budget.endDate.day);
                    
                    if ((txDate.isAfter(start) || txDate.isAtSameMomentAs(start)) && 
                        (txDate.isBefore(end) || txDate.isAtSameMomentAs(end))) {
                      spent += tx.amount;
                    }
                  }
                }
                globalTotalSpent += spent;
              }

              double globalRemaining = globalTotalBudget - globalTotalSpent;
              if (globalRemaining < 0) globalRemaining = 0;
              
              if (closestEndDate != null) {
                final diff = closestEndDate.difference(now).inDays;
                daysLeft = diff < 0 ? 0 : diff;
              }

              return SingleChildScrollView(
                child: Column(
                  children: [
                    // Top Section (Arc Chart & Summary)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.only(top: 20, bottom: 32, left: 24, right: 24),
                      decoration: const BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(32),
                          bottomRight: Radius.circular(32),
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildArcChart(globalTotalBudget, globalTotalSpent, globalRemaining, daysLeft),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AddBudgetScreen()),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: AppColors.primaryBlue,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Create Budget',
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // List of Budgets
                    if (budgets.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(32.0),
                        child: Text(
                          'No budgets created yet.',
                          style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Column(
                          children: budgets.map((budget) {
                            double spent = 0;
                            for (var tx in transactions) {
                              if (!tx.isIncome && tx.category == budget.category) {
                                final txDate = DateTime(tx.date.year, tx.date.month, tx.date.day);
                                final start = DateTime(budget.startDate.year, budget.startDate.month, budget.startDate.day);
                                final end = DateTime(budget.endDate.year, budget.endDate.month, budget.endDate.day);
                                
                                if ((txDate.isAfter(start) || txDate.isAtSameMomentAs(start)) && 
                                    (txDate.isBefore(end) || txDate.isAtSameMomentAs(end))) {
                                  spent += tx.amount;
                                }
                              }
                            }
                            return _buildBudgetListTile(budget, spent);
                          }).toList(),
                        ),
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

  Widget _buildArcChart(double totalBudget, double totalSpent, double remaining, int daysLeft) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    double progress = totalBudget > 0 ? totalSpent / totalBudget : 0;
    if (progress > 1.0) progress = 1.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // The Custom Arc Painter
        SizedBox(
          width: 300,
          height: 150,
          child: CustomPaint(
            painter: ArcProgressPainter(
              progress: progress,
              backgroundColor: Colors.white.withOpacity(0.2),
              progressColor: Colors.white,
            ),
          ),
        ),
        
        // The Text Content inside the Arc
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Amount you can spend',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            Text(
              format.format(remaining),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Column(
                  children: [
                    Text(
                      _formatCompact(totalBudget),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Total budget', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
                Column(
                  children: [
                    Text(
                      _formatCompact(totalSpent),
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('Total spent', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
                Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
                Column(
                  children: [
                    Text(
                      '$daysLeft days',
                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    const Text('End of period', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1).replaceAll('.0', '')} Jt';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1).replaceAll('.0', '')} K';
    }
    return NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(value);
  }

  Widget _buildBudgetListTile(BudgetModel budget, double spent) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    double progress = budget.amount > 0 ? spent / budget.amount : 0;
    if (progress > 1.0) progress = 1.0;

    final remaining = budget.amount - spent;
    
    // Time progress for 'Hari ini' marker
    final now = DateTime.now();
    final totalDays = budget.endDate.difference(budget.startDate).inDays;
    final passedDays = now.difference(budget.startDate).inDays;
    double timeProgress = totalDays > 0 ? passedDays / totalDays : 0;
    if (timeProgress < 0) timeProgress = 0;
    if (timeProgress > 1.0) timeProgress = 1.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => BudgetDetailScreen(budget: budget, spent: spent)),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
        ),
        child: Column(
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
                Expanded(
                  child: Text(
                    budget.category,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      format.format(budget.amount),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Remaining ${format.format(remaining < 0 ? 0 : remaining)}',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Custom linear progress with Today marker
            LayoutBuilder(
              builder: (context, constraints) {
                return Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.centerLeft,
                  children: [
                    // Background track
                    Container(
                      width: double.infinity,
                      height: 8,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // Progress fill
                    Container(
                      width: constraints.maxWidth * progress,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    // 'Hari ini' Marker
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
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}

class ArcProgressPainter extends CustomPainter {
  final double progress;
  final Color backgroundColor;
  final Color progressColor;

  ArcProgressPainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height);
    final radius = size.width / 2;

    final Paint bgPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final Paint fillPaint = Paint()
      ..color = progressColor
      ..strokeWidth = 14
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Draw background arc (half circle)
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      math.pi, // start angle
      math.pi, // sweep angle
      false,
      bgPaint,
    );

    // Draw progress arc
    if (progress > 0) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        math.pi,
        math.pi * progress,
        false,
        fillPaint,
      );
    }
    
    // Draw the small knob at the end of progress
    if (progress > 0) {
      final knobAngle = math.pi + (math.pi * progress);
      final knobCenter = Offset(
        center.dx + radius * math.cos(knobAngle),
        center.dy + radius * math.sin(knobAngle),
      );
      
      final Paint knobPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.fill;
        
      final Paint knobShadow = Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);

      canvas.drawCircle(knobCenter, 12, knobShadow);
      canvas.drawCircle(knobCenter, 10, knobPaint);
      
      final Paint innerKnob = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(knobCenter, 5, innerKnob);
    }
  }

  @override
  bool shouldRepaint(covariant ArcProgressPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}
