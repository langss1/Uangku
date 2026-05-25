import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/models/budget_model.dart';
import 'package:uangku_app/core/models/category_model.dart';
import 'package:uangku_app/core/data/budget_data.dart';
import 'package:uangku_app/features/transaction/screens/category_selection_screen.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:uangku_app/core/utils/currency_input_formatter.dart';
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
        icon: IconData(widget.existingBudget!.iconCodePoint, fontFamily: 'MaterialIcons'),
        color: widget.existingBudget!.bgColor,
        iconColor: widget.existingBudget!.iconColor,
        isIncome: false,
      );
    }
  }
  bool _repeatBudget = false;
  bool _isSaving = false;

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
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.primaryBlue,
                    onPrimary: Colors.white,
                    surface: Color(0xFF1E1E1E),
                    onSurface: Colors.white,
                  )
                : const ColorScheme.light(
                    primary: AppColors.primaryBlue,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black,
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
    final f = NumberFormat("#,###", "en_US");
    final initialText = _amount > 0 ? f.format(_amount.toInt()).replaceAll(',', '.') : '';
    final TextEditingController controller = TextEditingController(text: initialText);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: context.cardColor,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Enter Amount',
            style: TextStyle(fontWeight: FontWeight.bold, color: context.textPrimary, fontSize: 18),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            style: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              CurrencyInputFormatter(),
            ],
            decoration: InputDecoration(
              hintText: '0',
              hintStyle: TextStyle(color: context.textSecondary.withOpacity(0.4)),
              prefixText: 'Rp ',
              prefixStyle: TextStyle(color: context.textPrimary, fontSize: 18, fontWeight: FontWeight.bold),
              enabledBorder: UnderlineInputBorder(
                borderSide: BorderSide(color: context.borderColor),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              style: TextButton.styleFrom(foregroundColor: context.textSecondary),
              child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _amount = double.tryParse(controller.text.replaceAll('.', '')) ?? 0;
                });
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _saveBudget() async {
    if (_amount <= 0 || _selectedCategory == null || _selectedDateRange == null) return;
    if (_isSaving) return;

    setState(() => _isSaving = true);

    final newBudget = BudgetModel(
      id: widget.existingBudget?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
      category: _selectedCategory!.name,
      amount: _amount,
      startDate: _selectedDateRange!.start,
      endDate: _selectedDateRange!.end,
      iconCodePoint: _selectedCategory!.icon.codePoint,
      bgColor: _selectedCategory!.color,
      iconColor: _selectedCategory!.iconColor,
    );

    if (widget.existingBudget != null) {
      await BudgetData().updateBudget(newBudget);
    } else {
      await BudgetData().addBudget(newBudget);
    }
    
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final canSave = _amount > 0 && _selectedCategory != null && _selectedDateRange != null;
    final format = NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0);

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.close, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.existingBudget != null ? 'Edit Budget' : 'Add Budget',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold, fontSize: 18),
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
              onPressed: canSave && !_isSaving ? _saveBudget : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: canSave && !_isSaving ? AppColors.primaryBlue : (context.isDarkMode ? Colors.grey[800] : Colors.grey[300]),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(28),
                ),
                elevation: 0,
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Text(
                      'Save',
                      style: TextStyle(
                        fontSize: 16, 
                        fontWeight: FontWeight.bold, 
                        color: canSave ? Colors.white : (context.isDarkMode ? Colors.grey[600] : Colors.grey[500]),
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
              color: context.cardColor,
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
                              decoration: BoxDecoration(
                                color: context.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFE2E8F0),
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
                                color: context.textPrimary,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: context.textSecondary.withOpacity(0.5)),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: 88, color: context.borderColor),
                  
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
                                color: context.isDarkMode ? const Color(0xFF1E1E1E) : const Color(0xFFE2E8F0),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text('IDR', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: context.isDarkMode ? const Color(0xFFCBD5E1) : const Color(0xFF475569))),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Amount', style: TextStyle(fontSize: 12, color: context.textSecondary)),
                                const SizedBox(height: 4),
                                Text(
                                  _amount > 0 ? format.format(_amount) : '0',
                                  style: TextStyle(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.w600, 
                                    color: _amount > 0 ? AppColors.primaryBlue : context.textSecondary.withOpacity(0.6),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Divider(height: 1, indent: 88, color: context.borderColor),
 
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
                            child: Icon(Icons.calendar_month, color: context.textSecondary, size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _selectedDateRange != null
                                  ? '${DateFormat('dd/MM').format(_selectedDateRange!.start)} - ${DateFormat('dd/MM').format(_selectedDateRange!.end)}'
                                  : 'This Month',
                              style: TextStyle(fontSize: 16, color: context.textPrimary),
                            ),
                          ),
                          Icon(Icons.chevron_right, color: context.textSecondary.withOpacity(0.5)),
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
