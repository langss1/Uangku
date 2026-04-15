import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/features/splash/splash_screen.dart';
import 'package:uangku_app/features/profile/profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // Placeholder function for Logout (Moved to ProfileScreen but kept here just in case)
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 4) {
      return const ProfileScreen();
    }
    
    // Default Home Screen (Index 0, or placeholders for others)
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 24),
          _buildQuickActions(),
          const SizedBox(height: 32),
          _buildRecentTransactions(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 32),
      decoration: const BoxDecoration(
        color: Color(0xFF2962FF), // Primary Blue from UI
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(0),
          bottomRight: Radius.circular(0),
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  // Avatar
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      shape: BoxShape.circle,
                    ),
                    child: const Center(
                      child: Text(
                        'SJ',
                        style: TextStyle(
                          color: Color(0xFF2962FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Greeting
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'Good Morning',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Sarah Johnson',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              // Notification Icon
              IconButton(
                onPressed: _logout, // Use this for logout for now
                icon: const Icon(Icons.notifications_none_outlined, color: Colors.white, size: 28),
              ),
            ],
          ),
          const SizedBox(height: 32),
          // Balance Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Balance',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '\$12,847.50',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF10B981), // Green dot
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      '+2.5% this month',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionItem(
                icon: Icons.qr_code_scanner,
                label: 'Scan',
                color: const Color(0xFFDBEAFE),
                iconColor: const Color(0xFF2563EB),
              ),
              _buildActionItem(
                icon: Icons.add,
                label: 'Manual',
                color: const Color(0xFFD1FAE5),
                iconColor: const Color(0xFF059669),
              ),
              _buildActionItem(
                icon: Icons.arrow_forward,
                label: 'Transfer',
                color: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF7C3AED),
              ),
              _buildActionItem(
                icon: Icons.history,
                label: 'History',
                color: const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFD97706),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String label, required Color color, required Color iconColor}) {
    return Column(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 28),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF475569),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Transactions',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: const Text(
                  'See All',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2962FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Transactions List
          _buildTransactionItem(
            title: "McDonald's",
            category: "Food & Dining",
            amount: "-\$12.50",
            date: "Today",
            icon: Icons.restaurant,
            bgColor: const Color(0xFFFEE2E2),
            iconColor: const Color(0xFFDC2626),
            isIncome: false,
          ),
          _buildTransactionItem(
            title: "Uber",
            category: "Transportation",
            amount: "-\$18.75",
            date: "Yesterday",
            icon: Icons.directions_car,
            bgColor: const Color(0xFFDBEAFE),
            iconColor: const Color(0xFF2563EB),
            isIncome: false,
          ),
          _buildTransactionItem(
            title: "Monthly Salary",
            category: "Income",
            amount: "+\$3,200.00",
            date: "Dec 1",
            icon: Icons.payments,
            bgColor: const Color(0xFFD1FAE5),
            iconColor: const Color(0xFF059669),
            isIncome: true,
          ),
          _buildTransactionItem(
            title: "Amazon",
            category: "Shopping",
            amount: "-\$89.99",
            date: "Dec 2",
            icon: Icons.shopping_bag,
            bgColor: const Color(0xFFF3E8FF),
            iconColor: const Color(0xFF7C3AED),
            isIncome: false,
          ),
          _buildTransactionItem(
            title: "Starbucks",
            category: "Food & Dining",
            amount: "-\$5.25",
            date: "Dec 2",
            icon: Icons.coffee,
            bgColor: const Color(0xFFFFEDD5),
            iconColor: const Color(0xFFD97706),
            isIncome: false,
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String title,
    required String category,
    required String amount,
    required String date,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required bool isIncome,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF1F5F9), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  category,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                date,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(icon: Icons.home_rounded, label: 'Home', index: 0),
              _buildNavItem(icon: Icons.analytics_outlined, label: 'Analytics', index: 1),
              _buildNavItem(icon: Icons.add, label: 'Add', index: 2),
              _buildNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Wallet', index: 3),
              _buildNavItem(icon: Icons.person_outline, label: 'Profile', index: 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFF2962FF) : const Color(0xFF94A3B8);
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
