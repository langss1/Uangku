import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/models/transaction_model.dart';
import 'package:uangku_app/core/data/transaction_data.dart';
import 'package:uangku_app/core/models/category_model.dart';
import 'package:uangku_app/features/transaction/screens/transaction_success_screen.dart';
import 'package:uangku_app/features/transaction/screens/category_selection_screen.dart';
import 'package:uangku_app/core/services/currency_service.dart';
import 'package:uangku_app/features/scan/screens/scan_screen.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class AddTransactionScreen extends StatefulWidget {
  final VoidCallback onBack;
  final TransactionModel? transactionToEdit;

  const AddTransactionScreen({super.key, required this.onBack, this.transactionToEdit});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> with SingleTickerProviderStateMixin {
  bool _isIncome = false;
  double _amount = 0;
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  AnimationController? _animationController;
  Animation<double>? _scaleAnimation;
  Timer? _timer;
  bool _showMessage = false;
  
  // Currency state
  String _selectedCurrency = 'IDR';
  Map<String, double> _rates = {'IDR': 1.0};
  bool _isLoadingRates = false;
  final List<String> _popularCurrencies = ['IDR', 'USD', 'SGD', 'EUR', 'JPY', 'MYR'];

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut));

    _triggerAnimationAndMessage();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _triggerAnimationAndMessage();
    });

    _loadRates();

    if (widget.transactionToEdit != null) {
      _isIncome = widget.transactionToEdit!.isIncome;
      _amount = widget.transactionToEdit!.originalAmount > 0 
          ? widget.transactionToEdit!.originalAmount 
          : widget.transactionToEdit!.amount;
      _amountController.text = _amount.toInt().toString();
      _selectedDate = widget.transactionToEdit!.date;
      _notesController.text = widget.transactionToEdit!.note;
      _selectedCurrency = widget.transactionToEdit!.currencyCode;
      
      _selectedCategory = CategoryModel(
        id: "edit_cat",
        name: widget.transactionToEdit!.category,
        icon: widget.transactionToEdit!.icon,
        color: widget.transactionToEdit!.bgColor,
        iconColor: widget.transactionToEdit!.iconColor,
        isIncome: _isIncome,
      );
    }
  }

  void _triggerAnimationAndMessage() {
    if (!mounted) return;
    _animationController?.forward(from: 0.0);
    setState(() {
      _showMessage = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _showMessage = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _animationController?.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    setState(() => _isLoadingRates = true);
    try {
      final fetchedRates = await CurrencyService().fetchExchangeRates();
      setState(() {
        _rates = fetchedRates;
        _isLoadingRates = false;
      });
    } catch (e) {
      setState(() => _isLoadingRates = false);
    }
  }

  void _saveTransaction() {
    if (_amount == 0 || _selectedCategory == null) return;
    
    final double rate = _rates[_selectedCurrency] ?? 1.0;
    final double amountInIDR = _selectedCurrency == 'IDR' ? _amount : _amount * rate;

    if (widget.transactionToEdit != null) {
      // Edit
      final updatedTx = widget.transactionToEdit!.copyWith(
        amount: amountInIDR,
        originalAmount: _amount,
        currencyCode: _selectedCurrency,
        exchangeRate: rate,
        isIncome: _isIncome,
        category: _selectedCategory!.name,
        date: _selectedDate,
        note: _notesController.text,
        icon: _selectedCategory!.icon,
        bgColor: _selectedCategory!.color,
        iconColor: _selectedCategory!.iconColor,
      );
      TransactionData().updateTransaction(updatedTx);
    } else {
      // Add
      final newTx = TransactionModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: _selectedCategory!.name,
        category: _selectedCategory!.name,
        amount: amountInIDR,
        originalAmount: _amount,
        currencyCode: _selectedCurrency,
        exchangeRate: rate,
        date: _selectedDate,
        icon: _selectedCategory!.icon,
        bgColor: _selectedCategory!.color,
        iconColor: _selectedCategory!.iconColor,
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
            widget.onBack(); 
          },
          onAddAnother: () {
            Navigator.pop(context); // pop success
            setState(() {
              _amount = 0;
              _amountController.clear();
              _notesController.clear();
              _selectedCategory = null;
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
        final currentTime = DateTime.now();
        if (picked.year == currentTime.year && picked.month == currentTime.month && picked.day == currentTime.day) {
          _selectedDate = currentTime;
        } else {
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

  Future<void> _openCategorySelection() async {
    final CategoryModel? result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CategorySelectionScreen(initialIsIncome: _isIncome),
      ),
    );

    if (result != null) {
      setState(() {
        _selectedCategory = result;
        _isIncome = result.isIncome;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final amountColor = _isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626);
    final canSave = _amount > 0 && _selectedCategory != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textDark),
          onPressed: widget.onBack,
        ),
        title: const Text(
          'Tambah transaksi',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          AnimatedOpacity(
            opacity: _showMessage ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF2962FF).withOpacity(0.9),
                borderRadius: BorderRadius.circular(10),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 3))
                ]
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.auto_awesome, color: Colors.amberAccent, size: 16),
                  SizedBox(width: 6),
                  Text('AI untuk scan otomatis', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold, letterSpacing: 0.3)),
                ],
              ),
            ),
          ),
          if (_scaleAnimation != null)
            ScaleTransition(
              scale: _scaleAnimation!,
              child: FloatingActionButton(
                heroTag: 'scan_fab',
                onPressed: () {
                  Navigator.push(context, MaterialPageRoute(builder: (_) => const ScanScreen()));
                },
                backgroundColor: const Color(0xFFDBEAFE),
                elevation: 4,
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    Icon(Icons.camera_alt, color: Color(0xFF2563EB), size: 26),
                    Positioned(
                      top: -2,
                      right: -2,
                      child: Icon(Icons.auto_awesome, color: Colors.amber, size: 14),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // TABS: Pengeluaran | Pemasukan
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Container(
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                         _isIncome = false;
                         if (_selectedCategory?.isIncome == true) _selectedCategory = null; 
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: !_isIncome ? AppColors.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Center(
                          child: Text(
                            'Pengeluaran',
                            style: TextStyle(
                              color: !_isIncome ? Colors.white : AppColors.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                         _isIncome = true;
                         if (_selectedCategory?.isIncome == false) _selectedCategory = null; 
                      }),
                      child: Container(
                        decoration: BoxDecoration(
                          color: _isIncome ? AppColors.primaryBlue : Colors.transparent,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: Center(
                          child: Text(
                            'Pemasukan',
                            style: TextStyle(
                              color: _isIncome ? Colors.white : AppColors.textDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Currency and Amount
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedCurrency,
                            icon: const Icon(Icons.arrow_drop_down, color: AppColors.textDark),
                            style: const TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 14),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  _selectedCurrency = newValue;
                                });
                              }
                            },
                            items: _popularCurrencies.map<DropdownMenuItem<String>>((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: _amountController,
                          keyboardType: TextInputType.number,
                          style: TextStyle(
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                            color: amountColor,
                          ),
                          onChanged: (val) {
                            setState(() {
                              _amount = double.tryParse(val) ?? 0;
                            });
                          },
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: '0',
                            hintStyle: TextStyle(
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                              color: amountColor.withOpacity(0.5),
                            ),
                            contentPadding: const EdgeInsets.symmetric(vertical: 0),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Divider(color: amountColor, thickness: 1.5),
                  const SizedBox(height: 24),

                  // Category Selector
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: _selectedCategory?.color ?? Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _selectedCategory?.icon ?? Icons.category, 
                        color: _selectedCategory?.iconColor ?? Colors.grey[500], 
                        size: 24
                      ),
                    ),
                    title: Text(
                      _selectedCategory?.name ?? 'Pilih Kategori',
                      style: TextStyle(
                        color: _selectedCategory != null ? AppColors.textDark : Colors.grey[600], 
                        fontSize: 16,
                      ),
                    ),
                    onTap: _openCategorySelection,
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),

                  // Notes
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.notes, color: Color(0xFF64748B), size: 24),
                    title: TextField(
                      controller: _notesController,
                      style: const TextStyle(color: AppColors.textDark, fontSize: 16),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Tulis catatan',
                        hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 16),
                        isDense: true,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  const Divider(color: Color(0xFFF1F5F9), height: 16),

                  // Date Picker
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.calendar_today, color: Color(0xFF64748B), size: 24),
                    title: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.chevron_left, color: Color(0xFF64748B), size: 18),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('EEEE, dd/MM/yyyy').format(_selectedDate),
                                style: const TextStyle(color: AppColors.textDark, fontSize: 14),
                              ),
                              const SizedBox(width: 8),
                              const Icon(Icons.chevron_right, color: Color(0xFF64748B), size: 18),
                            ],
                          ),
                        ),
                      ],
                    ),
                    onTap: () => _selectDate(context),
                  ),
                  
                  const SizedBox(height: 36),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: canSave ? _saveTransaction : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: canSave ? AppColors.primaryBlue : Colors.grey[300],
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                        disabledBackgroundColor: Colors.grey[300],
                      ),
                      child: Text(
                        'Simpan',
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.bold, 
                          color: canSave ? Colors.white : Colors.grey[500],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 80), // Padding for FAB
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
