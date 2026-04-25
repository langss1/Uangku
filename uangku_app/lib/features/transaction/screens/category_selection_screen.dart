import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/models/category_model.dart';
import 'package:uangku_app/core/data/category_data.dart';

class CategorySelectionScreen extends StatefulWidget {
  final bool initialIsIncome;
  final bool isForBudget;

  const CategorySelectionScreen({super.key, required this.initialIsIncome, this.isForBudget = false});

  @override
  State<CategorySelectionScreen> createState() => _CategorySelectionScreenState();
}

class _CategorySelectionScreenState extends State<CategorySelectionScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _newCategoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (!widget.isForBudget) {
      _tabController = TabController(
        length: 2, 
        vsync: this, 
        initialIndex: widget.initialIsIncome ? 1 : 0
      );
    }
  }

  @override
  void dispose() {
    if (!widget.isForBudget) {
      _tabController.dispose();
    }
    _newCategoryController.dispose();
    super.dispose();
  }

  void _showAddCategoryDialog(bool isIncome) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: const Text('New Category', style: TextStyle(color: AppColors.textDark)),
          content: TextField(
            controller: _newCategoryController,
            style: const TextStyle(color: AppColors.textDark),
            decoration: InputDecoration(
              hintText: 'Category Name',
              hintStyle: TextStyle(color: Colors.grey[400]),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: AppColors.primaryBlue, width: 2),
              ),
            ),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () {
                _newCategoryController.clear();
                Navigator.pop(context);
              },
              child: const Text('Cancel', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primaryBlue),
              onPressed: () {
                if (_newCategoryController.text.trim().isNotEmpty) {
                  final newCat = CategoryModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: _newCategoryController.text.trim(),
                    icon: Icons.label_outline, // default icon for custom
                    color: const Color(0xFFF1F5F9),
                    iconColor: const Color(0xFF475569),
                    isIncome: isIncome,
                  );
                  CategoryData().addCategory(newCat);
                  _newCategoryController.clear();
                  Navigator.pop(context); // close dialog
                  Navigator.pop(context, newCat); // close screen, pass selected
                }
              },
              child: const Text('Save', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryList(List<CategoryModel> categories, bool isIncome) {
    final filteredCategories = categories.where((c) => c.isIncome == isIncome).toList();

    return Column(
      children: [
        // Add new category button
        InkWell(
          onTap: () => _showAddCategoryDialog(isIncome),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD1FAE5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add, color: Color(0xFF059669), size: 24),
                ),
                const SizedBox(width: 16),
                const Text(
                  'NEW CATEGORY',
                  style: TextStyle(
                    color: Color(0xFF059669),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 1, color: Color(0xFFF1F5F9)),
        
        // List of categories
        Expanded(
          child: ListView.separated(
            itemCount: filteredCategories.length,
            separatorBuilder: (_, __) => const Divider(height: 1, color: Color(0xFFF1F5F9)),
            itemBuilder: (context, index) {
              final cat = filteredCategories[index];
              return InkWell(
                onTap: () => Navigator.pop(context, cat),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: cat.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(cat.icon, color: cat.iconColor, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Text(
                        cat.name,
                        style: const TextStyle(
                          color: AppColors.textDark,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
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
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Select Category',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: AppColors.textDark),
            onPressed: () {},
          ),
        ],
        bottom: widget.isForBudget ? null : TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primaryBlue,
          indicatorWeight: 3,
          labelColor: AppColors.primaryBlue,
          unselectedLabelColor: Colors.grey[500],
          tabs: const [
            Tab(text: 'EXPENSE'),
            Tab(text: 'INCOME'),
          ],
        ),
      ),
      body: ValueListenableBuilder<List<CategoryModel>>(
        valueListenable: CategoryData().categoriesNotifier,
        builder: (context, categories, child) {
          if (widget.isForBudget) {
            return _buildCategoryList(categories, false);
          }
          return TabBarView(
            controller: _tabController,
            children: [
              _buildCategoryList(categories, false), // Pengeluaran
              _buildCategoryList(categories, true),  // Pemasukan
            ],
          );
        },
      ),
    );
  }
}
