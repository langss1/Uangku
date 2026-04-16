import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String _selectedFilter = 'Weekly'; // Weekly, Monthly, Custom
  DateTimeRange? _customDateRange;

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
      // TODO: Panggil fungsi fetch data di sini
      // berdasarkan range tanggal: picked.start hingga picked.end
    }
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
          onPressed: () {
            // Karena ini tab dari bottom nav, back biasanya bukan pop unless from separate stack.
            // Biarkan default pop jika di-push, atau ubah navigasi _selectedIndex di HomeScreen.
          },
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
      body: SingleChildScrollView(
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
            _buildIncomeVsExpenseCard(),
            const SizedBox(height: 16),
            _buildSpendingByCategoryCard(),
            const SizedBox(height: 16),
            _buildSummaryCards(),
            const SizedBox(height: 32), // padding bawah untuk bottom nav
          ],
        ),
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

  Widget _buildIncomeVsExpenseCard() {
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
            'Trend analysis over time',
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
                  horizontalInterval: 200,
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
                      interval: 200,
                      getTitlesWidget: (value, meta) {
                        if (value == 0) return const SizedBox.shrink(); // hide 0
                        return Text(
                          value.toInt().toString(),
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
                maxY: 1000,
                lineBarsData: [
                  // TODO: Ganti data spot di bawah ini dengan data asli (Income)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 680),
                      FlSpot(1, 720),
                      FlSpot(2, 650),
                      FlSpot(3, 900),
                      FlSpot(4, 750),
                      FlSpot(5, 620),
                      FlSpot(6, 580),
                    ],
                    isCurved: false,
                    color: const Color(0xFF10B981), // Income Green
                    barWidth: 3,
                    isStrokeCapRound: true,
                    dotData: FlDotData(show: false),
                  ),
                  // TODO: Ganti data spot di bawah ini dengan data asli (Expense)
                  LineChartBarData(
                    spots: const [
                      FlSpot(0, 450),
                      FlSpot(1, 520),
                      FlSpot(2, 380),
                      FlSpot(3, 610),
                      FlSpot(4, 490),
                      FlSpot(5, 420),
                      FlSpot(6, 380),
                    ],
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

  Widget _buildSpendingByCategoryCard() {
    // Data list matching image roughly
    // TODO: Generate list ini dinamis dari data asli
    final List<Map<String, dynamic>> categoryData = [
      {'name': 'Food & Dining', 'amount': 1240, 'color': const Color(0xFF60A5FA), 'percent': 34.6},
      {'name': 'Transportation', 'amount': 890, 'color': const Color(0xFF4ADE80), 'percent': 24.9},
      {'name': 'Shopping', 'amount': 650, 'color': const Color(0xFFF472B6), 'percent': 18.2},
      {'name': 'Entertainment', 'amount': 420, 'color': const Color(0xFFA78BFA), 'percent': 11.7},
      {'name': 'Utilities', 'amount': 380, 'color': const Color(0xFFFB923C), 'percent': 10.6},
    ];

    final format = NumberFormat.currency(locale: 'en_US', symbol: '\$', decimalDigits: 0);

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
                    value: data['percent'].toDouble(),
                    title: '${data['name']}\n${data['percent']}%',
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

  Widget _buildSummaryCards() {
    // TODO: Ganti nilai statis menjadi data kalkulasi asli
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
                const Text(
                  '\$4,850', // TODO: Tampilkan total pendapatan yang sebenarnya
                  style: TextStyle(
                    color: Color(0xFF065F46),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '+12% vs last month',
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
                const Text(
                  '\$3,580', // TODO: Tampilkan total pengeluaran sebenarnya
                  style: TextStyle(
                    color: Color(0xFFBE123C),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '+8% vs last month',
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
}
