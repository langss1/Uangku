import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/models/budget_model.dart';
import 'package:uangku_app/core/models/category_model.dart';
import 'package:uangku_app/core/data/budget_data.dart';
import 'package:uangku_app/features/transaction/screens/category_selection_screen.dart';
import 'package:intl/intl.dart';

class AddBudgetScreen extends StatefulWidget {
  final BudgetModel? existingBudget;

  const AddBudgetScreen({super.key, this.existingBudget});

  @override
  State<AddBudgetScreen> createState() => _AddBudgetScreenState();
}

class _AddBudgetScreenState extends State<AddBudgetScreen> {
  CategoryModel? _selectedCategory;
  DateTimeRange? _selectedDateRange;
  double _amount = 0;

  @override
  void initState() {
    super.initState();
    if (widget.existingBudget != null) {
      _amount = widget.existingBudget!.amount;
      _selectedDateRange = DateTimeRange(
        start: widget.existingBudget!.startDate,
        end: widget.existingBudget!.endDate,
      );
      _selectedCategory = CategoryModel(
        id: 'dummy',
        name: widget.existingBudget!.category,
        icon: widget.existingBudget!.icon,
        color: widget.existingBudget!.bgColor,
        iconColor: widget.existingBudget!.iconColor,
        isIncome: false,
      );
    }
  }
  bool _repeatBudget = false;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDateRange: _selectedDateRange ?? DateTimeRange(
        start: DateTime(now.year, now.month, 1),
        end: DateTime(now.year, now.month + 1, 0),
      ),
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
        _selectedDateRange = picked;
      });
    }
  }

  void _showAmountInputDialog() {
    final TextEditingController controller = TextEditingController(text: _amount > 0 ? _amount.toInt().toString() : '');
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Enter Amount'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              hintText: '0',
              prefixText: 'Rp ',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _amount = double.tryParse(controller.text) ?? 0;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  void _saveBudget() {
    if (_amount <= 0 || _selectedCategory == null || _selectedDateRange == null) return;

    final newBudget = BudgetModel(
      id: widget.existingBudget?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      category: _selectedCategory!.name,
      amount: _amount,
      startDate: _selectedDateRange!.start,
      endDate: _selectedDateRange!.end,
      icon: _selectedCategory!.icon,
      bgColor: _selectedCategory!.color,
      iconColor: _selectedCategory!.iconColor,
    );

    if (widget.existingBudget != null) {
      BudgetData().updateBudget(newBudget);
    } else {
      BudgetData().addBudget(newBudget);
    }
    
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _amount > 0 && _selectedCategory != null && _selectedDateRange != null;
    final format = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingBudget != null ? 'Edit Budget' : 'Add Budget',
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: false,
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: canSave ? _saveBudget : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canSave ? AppColors.primaryBlue : Colors.grey[300],
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: Text(
                'Save',
                style: TextStyle(
                  fontSize: 16, 
                  fontWeight: FontWeight.bold, 
                  color: canSave ? Colors.white : Colors.grey[500],
                ),
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  // Select Category Row
                  InkWell(
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const CategorySelectionScreen(initialIsIncome: false, isForBudget: true)),
                      );
                      if (result != null && result is CategoryModel) {
                        setState(() {
                          _selectedCategory = result;
                        });
                      }
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          if (_selectedCategory != null) ...[
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: _selectedCategory!.color,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(_selectedCategory!.icon, color: _selectedCategory!.iconColor, size: 24),
                            ),
                          ] else ...[
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xFFE2E8F0),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _selectedCategory != null ? _selectedCategory!.name : 'Select Category',
                              style: TextStyle(
                                fontSize: 16, 
                                fontWeight: _selectedCategory != null ? FontWeight.w600 : FontWeight.normal, 
                                color: AppColors.textDark,
                              ),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 88),
                  
                  // Amount Row
                  InkWell(
                    onTap: _showAmountInputDialog,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            alignment: Alignment.center,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text('IDR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF475569))),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Amount', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                                const SizedBox(height: 4),
                                Text(
                                  _amount > 0 ? format.format(_amount) : '0',
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.w600, 
                                    color: _amount > 0 ? AppColors.primaryBlue : const Color(0xFF94A3B8),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Divider(height: 1, indent: 88),

                  // Date Range Row
                  InkWell(
                    onTap: _pickDateRange,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            alignment: Alignment.center,
                            child: const Icon(Icons.calendar_month, color: Color(0xFF94A3B8), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _selectedDateRange != null
                                  ? '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                                  : 'This Month',
                              style: const TextStyle(fontSize: 16, color: AppColors.textDark),
                            ),
                          ),
                          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
