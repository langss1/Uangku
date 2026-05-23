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
import 'package:provider/provider.dart';
import 'package:uangku_app/core/providers/preferences_provider.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    BudgetData().loadBudgets();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Builder(builder: (context) {
          final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
          return Text(
            isIndo ? 'Anggaran' : 'Budgets',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          );
        }),
        centerTitle: true,
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
              final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
              
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
                    final txLocal = tx.date.toLocal();
                    final startLocal = budget.startDate.toLocal();
                    final endLocal = budget.endDate.toLocal();
                    
                    final txDate = DateTime(txLocal.year, txLocal.month, txLocal.day);
                    final start = DateTime(startLocal.year, startLocal.month, startLocal.day);
                    final end = DateTime(endLocal.year, endLocal.month, endLocal.day);
                    
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

              return Stack(
                children: [
                  // Blue Gradient Header Background with Polar Circles
                  Container(
                    height: 380,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: AnimatedBuilder(
                      animation: _animationController,
                      builder: (context, child) {
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            Positioned(
                              top: -60 + (math.sin(_animationController.value * math.pi * 2) * 20),
                              right: -50 + (math.cos(_animationController.value * math.pi * 2) * 15),
                              child: Container(
                                width: 220,
                                height: 220,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.06),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 150 + (math.cos(_animationController.value * math.pi * 2) * 25),
                              left: -40 + (math.sin(_animationController.value * math.pi * 2) * 10),
                              child: Container(
                                width: 140,
                                height: 140,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.05),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 20 + (math.sin(_animationController.value * math.pi * 2) * 15),
                              right: 20 + (math.cos(_animationController.value * math.pi * 2) * 10),
                              child: Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.04),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                  SafeArea(
                    child: Column(
                      children: [
                        // ── FIXED TOP SECTION (tidak scroll) ──
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.only(top: 20, bottom: 32, left: 24, right: 24),
                          child: Column(
                            children: [
                              _buildArcChart(globalTotalBudget, globalTotalSpent, globalRemaining, daysLeft, isIndo),
                              const SizedBox(height: 24),
                              Container(
                                width: double.infinity,
                                height: 50,
                                padding: const EdgeInsets.only(left: 1.5, right: 1.5, bottom: 2.0, top: 0),
                                decoration: BoxDecoration(
                                  color: AppColors.primaryBlue,
                                  borderRadius: BorderRadius.circular(25),
                                ),
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
                                  child: Text(
                                    isIndo ? 'Buat Anggaran' : 'Create Budget',
                                    style: const TextStyle(
                                      fontSize: 16, 
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // ── SCROLLABLE BUDGET LIST (hanya ini yang scroll) ──
                        Expanded(
                          child: budgets.isEmpty
                            ? Center(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 60.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(24),
                                        decoration: BoxDecoration(
                                          color: context.cardColor,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.05),
                                              blurRadius: 20,
                                              offset: const Offset(0, 10),
                                            ),
                                          ],
                                        ),
                                        child: Icon(
                                          Icons.account_balance_wallet_outlined,
                                          size: 80,
                                          color: context.textSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 24),
                                      Text(
                                        isIndo ? "Belum Ada Anggaran" : "No Budgets Yet",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w800,
                                          color: context.textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 40),
                                        child: Text(
                                          isIndo ? "Buat rencana anggaranmu untuk mengontrol pengeluaran dengan lebih baik." : "Create your budget plan to control expenses better.",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: context.textSecondary,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                                itemCount: budgets.length,
                                itemBuilder: (context, index) {
                                  final budget = budgets[index];
                                  double spent = 0;
                                  for (var tx in transactions) {
                                    if (!tx.isIncome && tx.category == budget.category) {
                                      final txLocal = tx.date.toLocal();
                                      final startLocal = budget.startDate.toLocal();
                                      final endLocal = budget.endDate.toLocal();
                                      
                                      final txDate = DateTime(txLocal.year, txLocal.month, txLocal.day);
                                      final start = DateTime(startLocal.year, startLocal.month, startLocal.day);
                                      final end = DateTime(endLocal.year, endLocal.month, endLocal.day);
                                      
                                      if ((txDate.isAfter(start) || txDate.isAtSameMomentAs(start)) && 
                                          (txDate.isBefore(end) || txDate.isAtSameMomentAs(end))) {
                                        spent += tx.amount;
                                      }
                                    }
                                  }
                                  return _buildBudgetListTile(budget, spent, isIndo);
                                },
                              ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildArcChart(double totalBudget, double totalSpent, double remaining, int daysLeft, bool isIndo) {
    final format = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);
    double progress = totalBudget > 0 ? totalSpent / totalBudget : 0;
    if (progress > 1.0) progress = 1.0;

    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomCenter,
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
                Text(
                  isIndo ? 'Sisa yang bisa dipakai' : 'Amount you can spend',
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
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
                const SizedBox(height: 10),
              ],
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Expanded(
              child: Column(
                children: [
                  Text(
                    _formatCompact(totalBudget),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(isIndo ? 'Total anggaran' : 'Total budget', style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            ),
            Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
            Expanded(
              child: Column(
                children: [
                  Text(
                    _formatCompact(totalSpent),
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(isIndo ? 'Total pengeluaran' : 'Total spent', style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
            ),
            Container(width: 1, height: 30, color: Colors.white.withOpacity(0.2)),
            Expanded(
              child: Column(
                children: [
                  Text(
                    isIndo ? '$daysLeft hari' : '$daysLeft days',
                    style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(isIndo ? 'Akhir periode' : 'End of period', style: const TextStyle(color: Colors.white70, fontSize: 12), textAlign: TextAlign.center),
                ],
              ),
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

  Widget _buildBudgetListTile(BudgetModel budget, double spent, bool isIndo) {
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
          color: context.cardColor,
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
                  child: Icon(IconData(budget.iconCodePoint, fontFamily: 'MaterialIcons'), color: budget.iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    budget.category,
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      format.format(budget.amount),
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isIndo ? 'Tersisa ${format.format(remaining < 0 ? 0 : remaining)}' : 'Remaining ${format.format(remaining < 0 ? 0 : remaining)}',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
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
                        color: context.borderColor,
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
                      left: (constraints.maxWidth * timeProgress - 1).clamp(0.0, constraints.maxWidth - 2.0),
                      top: -4,
                      child: Container(
                        width: 2,
                        height: 16,
                        color: context.textSecondary,
                      ),
                    ),
                    Positioned(
                      left: (constraints.maxWidth * timeProgress - 20).clamp(0.0, constraints.maxWidth - 40.0),
                      top: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: context.borderColor,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          isIndo ? 'Hari ini' : 'Today',
                          style: TextStyle(fontSize: 10, color: context.textSecondary),
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
