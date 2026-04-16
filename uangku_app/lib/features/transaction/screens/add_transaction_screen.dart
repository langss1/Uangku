import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/models/transaction_model.dart';
import 'package:uangku_app/core/data/transaction_data.dart';
import 'package:uangku_app/features/transaction/screens/transaction_success_screen.dart';

class AddTransactionScreen extends StatefulWidget {
  final VoidCallback onBack;
  final TransactionModel? transactionToEdit;

  const AddTransactionScreen({super.key, required this.onBack, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  bool _isIncome = false;
  double _amount = 0;
  String _selectedCategory = 'Food';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'name': 'Groceries', 'icon': Icons.shopping_cart, 'color': Color(0xFFFDE68A), 'iconColor': Color(0xFFD97706)},
    {'name': 'Food', 'icon': Icons.restaurant, 'color': Color(0xFFFECACA), 'iconColor': Color(0xFFDC2626)},
    {'name': 'Transport', 'icon': Icons.directions_car, 'color': Color(0xFFBFDBFE), 'iconColor': Color(0xFF2563EB)},
    {'name': 'Rent', 'icon': Icons.home, 'color': Color(0xFFBBF7D0), 'iconColor': Color(0xFF16A34A)},
    {'name': 'Shopping', 'icon': Icons.shopping_bag, 'color': Color(0xFFE9D5FF), 'iconColor': Color(0xFF9333EA)},
    {'name': 'Entertainment', 'icon': Icons.sports_esports, 'color': Color(0xFFFBCFE8), 'iconColor': Color(0xFFDB2777)},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.transactionToEdit != null) {
      _isIncome = widget.transactionToEdit!.isIncome;
      _amount = widget.transactionToEdit!.amount;
      _amountController.text = _amount.toInt().toString();
      _selectedCategory = widget.transactionToEdit!.category;
      _selectedDate = widget.transactionToEdit!.date;
      _notesController.text = widget.transactionToEdit!.note;
    }
  }

  void _saveTransaction() {
    if (_amount == 0) return; // Prevent zero amount
    
    final categoryMap = _categories.firstWhere((cat) => cat['name'] == _selectedCategory, orElse: () => _categories[1]);

    if (widget.transactionToEdit != null) {
      // Edit
      final updatedTx = widget.transactionToEdit!.copyWith(
        amount: _amount,
        isIncome: _isIncome,
        category: _selectedCategory,
        date: _selectedDate,
        note: _notesController.text,
        icon: categoryMap['icon'],
        bgColor: categoryMap['color'],
        iconColor: categoryMap['iconColor'],
      );
      TransactionData().updateTransaction(updatedTx);
    } else {
      // Add
      final newTx = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _selectedCategory,
        category: _selectedCategory,
        amount: _amount,
        date: _selectedDate,
        icon: categoryMap['icon'],
        bgColor: categoryMap['color'],
        iconColor: categoryMap['iconColor'],
        isIncome: _isIncome,
        note: _notesController.text,
      );
      TransactionData().addTransaction(newTx);
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TransactionSuccessScreen(
          onViewHistory: () {
            Navigator.pop(context); // pop success
            widget.onBack(); // back to home? 
            // In a better flow we would set selectedIndex to 0. 
            // We can pass a callback that sets index to 0 or handles the back.
          },
          onAddAnother: () {
            Navigator.pop(context); // pop success
            setState(() {
              _amount = 0;
              _amountController.clear();
              _notesController.clear();
            });
          },
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() {
        // preserve the current time
        final currentTime = DateTime.now();
        // If the user picked today, keep the exact current real-time
        if (picked.year == currentTime.year && picked.month == currentTime.month && picked.day == currentTime.day) {
          _selectedDate = currentTime;
        } else {
          // Otherwise, just use the picked date with the time when screen opened (or 12:00)
          _selectedDate = DateTime(
            picked.year,
            picked.month,
            picked.day,
            _selectedDate.hour,
            _selectedDate.minute,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: widget.onBack,
        ),
        title: Text(
          widget.transactionToEdit == null ? 'Add Transaction' : 'Edit Transaction',
          style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Amount section
              Center(
                child: Column(
                  children: [
                    const Text('Rp', style: TextStyle(fontSize: 24, color: AppColors.textLight)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (val) {
                        setState(() {
                          _amount = double.tryParse(val) ?? 0;
                        });
                      },
                      style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Income/Expense Toggle
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isIncome = true),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: _isIncome ? AppColors.primaryBlue : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Income',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _isIncome ? Colors.white : AppColors.textDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _isIncome = false),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: !_isIncome ? AppColors.primaryBlue : Colors.transparent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              'Expense',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: !_isIncome ? Colors.white : AppColors.textDark,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Category
              const Text('Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _categories.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 1,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['name']),
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cat['color'],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(cat['icon'], color: cat['iconColor'], size: 24),
                          ),
                          const SizedBox(height: 8),
                          Text(cat['name'], style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 32),

              // Date
              const Text('Date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () => _selectDate(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      )
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, color: AppColors.textLight),
                      const SizedBox(width: 16),
                      Text(
                        "${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Notes
              const Text('Notes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: TextField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: 'Write a note about this transaction',
                  ),
                ),
              ),
              const SizedBox(height: 48),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _saveTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    widget.transactionToEdit == null ? 'Save Transaction' : 'Update Transaction',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
