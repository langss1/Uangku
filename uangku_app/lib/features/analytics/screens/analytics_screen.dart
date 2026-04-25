import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:uangku_app/core/data/transaction_data.dart';
import 'package:uangku_app/core/models/transaction_model.dart';
import 'package:uangku_app/features/profile/screens/export_preview_screen.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedFilter = 'Weekly'; // Weekly, Monthly, Custom
  DateTimeRange? _customDateRange;
  DateTimeRange? _exportDateRange;

  @override
  void initState() {
    super.initState();
    _exportDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
  }

  Future<void> _selectCustomDateRange() async {
    DateTime? tempStart = _customDateRange?.start ?? DateTime.now().subtract(const Duration(days: 7));
    DateTime? tempEnd = _customDateRange?.end ?? DateTime.now();

    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Custom Date Range',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select your start and end date below:', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: tempStart!,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (date != null) {
                              setDialogState(() => tempStart = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text('Start Date', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMM yyyy').format(tempStart!),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: tempEnd ?? tempStart!,
                              firstDate: tempStart!,
                              lastDate: DateTime(2101),
                            );
                            if (date != null) {
                              setDialogState(() => tempEnd = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text('End Date', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text(
                                  tempEnd != null ? DateFormat('dd MMM yyyy').format(tempEnd!) : 'Select',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (tempStart != null && tempEnd != null) {
                      Navigator.pop(context, DateTimeRange(start: tempStart!, end: tempEnd!));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _customDateRange = picked;
        _selectedFilter = 'Custom';
      });
    }
  }

  Future<void> _selectExportDateRange() async {
    DateTime? tempStart = _exportDateRange?.start ?? DateTime.now().subtract(const Duration(days: 30));
    DateTime? tempEnd = _exportDateRange?.end ?? DateTime.now();

    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Custom Date Range',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select your start and end date below:', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: tempStart!,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (date != null) {
                              setDialogState(() => tempStart = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text('Start Date', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMM yyyy').format(tempStart!),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: tempEnd ?? tempStart!,
                              firstDate: tempStart!,
                              lastDate: DateTime(2101),
                            );
                            if (date != null) {
                              setDialogState(() => tempEnd = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text('End Date', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text(
                                  tempEnd != null ? DateFormat('dd MMM yyyy').format(tempEnd!) : 'Select',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (tempStart != null && tempEnd != null) {
                      Navigator.pop(context, DateTimeRange(start: tempStart!, end: tempEnd!));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _exportDateRange = picked;
      });
    }
  }

  void _navigateToPreview(String format) {
    if (_exportDateRange == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExportPreviewScreen(
          dateRange: _exportDateRange!,
          exportFormat: format,
          userName: 'Sarah Johnson', // Hardcoded as per existing UI
        ),
      ),
    );
  }

  void _onFilterChanged(String filter) {
    if (filter == 'Custom') {
      _selectCustomDateRange();
    } else {
      setState(() {
        _selectedFilter = filter;
      });
      // TODO: Panggil fungsi fetch data (seperti Provider/Bloc/TransactionData) di sini
      // berdasarkan filter 'Weekly' atau 'Monthly'
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB), // Background mirip gambar
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {},
        ),
        title: const Text(
          'Financial Analytics',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.black87),
            onPressed: () {},
          ),
        ],
      ),
      body: ValueListenableBuilder<List<TransactionModel>>(
        valueListenable: TransactionData().transactionsNotifier,
        builder: (context, transactions, child) {
          List<TransactionModel> filteredTransactions = transactions;
          if (_selectedFilter == 'Weekly') {
            final now = DateTime.now();
            filteredTransactions = transactions.where((tx) => now.difference(tx.date).inDays <= 7).toList();
          } else if (_selectedFilter == 'Monthly') {
            final now = DateTime.now();
            filteredTransactions = transactions.where((tx) => tx.date.month == now.month && tx.date.year == now.year).toList();
          } else if (_selectedFilter == 'Custom' && _customDateRange != null) {
            filteredTransactions = transactions.where((tx) => 
                tx.date.isAfter(_customDateRange!.start.subtract(const Duration(days: 1))) && 
                tx.date.isBefore(_customDateRange!.end.add(const Duration(days: 1)))).toList();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildFilterTabs(),
                if (_selectedFilter == 'Custom' && _customDateRange != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
                    child: Text(
                      '${DateFormat('dd MMM yyyy').format(_customDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_customDateRange!.end)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2962FF),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                _buildSummaryCards(filteredTransactions),
                const SizedBox(height: 16),
                _buildIncomeVsExpenseCard(filteredTransactions),
                const SizedBox(height: 16),
                _buildSpendingByCategoryCard(filteredTransactions),
                const SizedBox(height: 32),
                _buildExportSection(),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0).withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(4),
      child: Row(
        children: [
          _buildFilterTabItem('Weekly'),
          _buildFilterTabItem('Monthly'),
          _buildFilterTabItem('Custom'),
        ],
      ),
    );
  }

  Widget _buildFilterTabItem(String title) {
    bool isSelected = _selectedFilter == title;
    return Expanded(
      child: GestureDetector(
        onTap: () => _onFilterChanged(title),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Center(
            child: Text(
              title,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.black87 : const Color(0xFF64748B),
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIncomeVsExpenseCard(List<TransactionModel> transactions) {
    List<double> incomeByDay = List.filled(7, 0.0);
    List<double> expenseByDay = List.filled(7, 0.0);

    for (var tx in transactions) {
      int index = tx.date.weekday - 1; // 0 = Mon, 6 = Sun
      if (index >= 0 && index < 7) {
        if (tx.isIncome) {
          incomeByDay[index] += tx.amount;
        } else {
          expenseByDay[index] += tx.amount;
        }
      }
    }

    double maxY = 1000;
    for (var i = 0; i < 7; i++) {
      if (incomeByDay[i] > maxY) maxY = incomeByDay[i];
      if (expenseByDay[i] > maxY) maxY = expenseByDay[i];
    }
    maxY = maxY * 1.2;

    double interval = maxY / 5;
    if (interval < 200) interval = 200;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Income vs Expense',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Trend analysis by day',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: interval,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: const Color(0xFFF1F5F9),
                      strokeWidth: 1,
                    );
                  },
                ),
                titlesData: FlTitlesData(
                  show: true,
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 30,
                      interval: 1,
                      getTitlesWidget: (value, meta) {
                        const style = TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 11,
                        );
                        Widget text;
                        switch (value.toInt()) {
                          case 0:
                            text = const Text('Mon', style: style);
                            break;
                          case 1:
                            text = const Text('Tue', style: style);
                            break;
                          case 2:
                            text = const Text('Wed', style: style);
                            break;
                          case 3:
                            text = const Text('Thu', style: style);
                            break;
                          case 4:
                            text = const Text('Fri', style: style);
                            break;
                          case 5:
                            text = const Text('Sat', style: style);
                            break;
                          case 6:
                            text = const Text('Sun', style: style);
                            break;
                          default:
                            text = const Text('', style: style);
                            break;
                        }
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: text,
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: interval,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink(); // hide 0
                        final compactFormat = NumberFormat.compact(locale: 'id_ID');
                        return Text(
                          compactFormat.format(value),
                          style: const TextStyle(
                            color: Color(0xFF64748B),
                            fontSize: 11,
                          ),
                        );
                      },
                      reservedSize: 42,
                    ),
                  ),
                ),
                borderData: FlBorderData(
                  show: false,
                ),
                minX: 0,
                maxX: 6,
                minY: 0,
                maxY: maxY,
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(7, (index) => FlSpot(index.toDouble(), incomeByDay[index])),
                    isCurved: false,
                    color: const Color(0xFF10B981), // Income Green
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                  ),
                  LineChartBarData(
                    spots: List.generate(7, (index) => FlSpot(index.toDouble(), expenseByDay[index])),
                    isCurved: false,
                    color: const Color(0xFFF97316), // Expense Orange
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpendingByCategoryCard(List<TransactionModel> transactions) {
    Map<String, double> categorySums = {};
    double totalExpense = 0;

    for (var tx in transactions) {
      if (!tx.isIncome) {
        categorySums[tx.category] = (categorySums[tx.category] ?? 0) + tx.amount;
        totalExpense += tx.amount;
      }
    }

    final colors = [
      const Color(0xFF60A5FA),
      const Color(0xFF4ADE80),
      const Color(0xFFF472B6),
      const Color(0xFFA78BFA),
      const Color(0xFFFB923C),
      const Color(0xFFFBBF24),
    ];

    List<Map<String, dynamic>> categoryData = [];
    int colorIndex = 0;
    categorySums.forEach((name, amount) {
      categoryData.add({
        'name': name,
        'amount': amount,
        'percent': totalExpense > 0 ? (amount / totalExpense * 100) : 0.0,
        'color': colors[colorIndex % colors.length],
      });
      colorIndex++;
    });

    categoryData.sort((a, b) => b['amount'].compareTo(a['amount']));

    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending by Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Distribution overview',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 24),
          if (categoryData.isEmpty)
            const SizedBox(
              height: 220,
              child: Center(
                child: Text('No expenses found', style: TextStyle(color: Colors.black54)),
              ),
            )
          else
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(enabled: true),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 0,
                  centerSpaceRadius: 40,
                  sections: categoryData.map((data) {
                    return PieChartSectionData(
                      color: data['color'],
                      value: data['percent'],
                      title: '${data['name']}\n${data['percent'].toStringAsFixed(1)}%',
                      radius: 70,
                      titleStyle: const TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E293B),
                      ),
                      titlePositionPercentageOffset: 1.3,
                    );
                  }).toList(),
                ),
              ),
            ),
          const SizedBox(height: 32),
          // LEGEND
          Column(
            children: categoryData.map((data) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: data['color'],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      data['name'],
                      style: const TextStyle(
                        color: Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      format.format(data['amount']),
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCards(List<TransactionModel> transactions) {
    double totalIncome = 0;
    double totalExpense = 0;

    for (var tx in transactions) {
      if (tx.isIncome) {
        totalIncome += tx.amount;
      } else {
        totalExpense += tx.amount;
      }
    }

    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

    return Row(
      children: [
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7), // Light green background
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.trending_up, color: Color(0xFF059669), size: 16),
                    SizedBox(width: 4),
                    Text(
                      'INCOME',
                      style: TextStyle(
                        color: Color(0xFF059669),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    format.format(totalIncome),
                    style: const TextStyle(
                      color: Color(0xFF065F46),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Based on filter',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFE4E6), // Light red background
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    Icon(Icons.trending_down, color: Color(0xFFE11D48), size: 16),
                    SizedBox(width: 4),
                    Text(
                      'EXPENSES',
                      style: TextStyle(
                        color: Color(0xFFE11D48),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    format.format(totalExpense),
                    style: const TextStyle(
                      color: Color(0xFFBE123C),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Based on filter',
                  style: TextStyle(
                    color: Color(0xFFE11D48),
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExportSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Export Analytics',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1E293B)),
          ),
          const SizedBox(height: 4),
          const Text(
            'Download your financial reports in preferred format',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 24),
        
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildInputLabel('Select Date Range'),
            GestureDetector(
              onTap: _selectExportDateRange,
              child: const Text(
                'Change',
                style: TextStyle(
                  color: Color(0xFF2962FF),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _selectExportDateRange,
          child: _buildDatePicker(
            label: 'Start Date', 
            value: DateFormat('dd MMM yyyy').format(_exportDateRange!.start)
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: _selectExportDateRange,
          child: _buildDatePicker(
            label: 'End Date', 
            value: DateFormat('dd MMM yyyy').format(_exportDateRange!.end)
          ),
        ),
        
        const SizedBox(height: 24),
        
        _buildInputLabel('Choose Export Format'),
        const SizedBox(height: 12),
        
        GestureDetector(
          onTap: () => _navigateToPreview('PDF'),
          child: _buildFormatTile(
            icon: Icons.picture_as_pdf,
            iconBgColor: const Color(0xFFFEE2E2),
            iconColor: const Color(0xFFDC2626),
            title: 'PDF Report',
            subtitle: 'Formatted financial report',
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _navigateToPreview('CSV'),
          child: _buildFormatTile(
            icon: Icons.insert_drive_file_outlined,
            iconBgColor: const Color(0xFFD1FAE5),
            iconColor: const Color(0xFF059669),
            title: 'CSV File',
            subtitle: 'Raw data for analysis',
          ),
        ),
      ],
    ),
  );
}

  Widget _buildInputLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)));
  }

  Widget _buildDatePicker({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
              const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFormatTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1E293B))),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 24),
        ],
      ),
    );
  }
}
