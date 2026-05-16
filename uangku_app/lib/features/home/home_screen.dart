import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/features/splash/splash_screen.dart';
import 'package:uangku_app/features/profile/profile_screen.dart';
import 'package:uangku_app/core/models/transaction_model.dart';
import 'package:uangku_app/core/data/transaction_data.dart';
import 'package:uangku_app/features/transaction/screens/add_transaction_screen.dart';
import 'package:uangku_app/features/transaction/screens/transaction_history_screen.dart';
import 'package:uangku_app/features/transaction/screens/transaction_detail_screen.dart';
import 'package:uangku_app/features/analytics/screens/analytics_screen.dart';
import 'package:uangku_app/features/chat/screens/chat_screen.dart';
import 'package:uangku_app/features/scan/screens/scan_screen.dart';
import 'package:uangku_app/features/notification/screens/notification_screen.dart';
import 'package:uangku_app/features/budget/screens/budget_screen.dart';
import 'package:uangku_app/core/services/notification_service.dart';
import 'package:uangku_app/core/database/database_helper.dart';
import 'package:intl/intl.dart';
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  String _userName = 'Guest';
  int _unreadNotifs = 0;

  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning 👋';
    } else if (hour < 17) {
      return 'Good Afternoon 👋';
    } else if (hour < 20) {
      return 'Good Evening 👋';
    } else {
      return 'Good Night 👋';
    }
  }

  Future<void> _loadUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (mounted) {
        setState(() {
          _userName = prefs.getString('user_name') ?? 'Guest';
        });
      }
      // Trigger sync secara background tanpa await agar tidak menghalangi rendering
      TransactionData().fetchFromBackend().catchError((e) => debugPrint("Fetch error: $e"));
      
      // Trigger morning report notification check secara background
      NotificationService().triggerMorningReport().catchError((e) => debugPrint("Notification error: $e"));
      _checkUnreadNotifs();
    } catch (e) {
      debugPrint("Error loading user: $e");
    }
  }

  Future<void> _checkUnreadNotifs() async {
    final count = await DatabaseHelper.instance.getUnreadNotificationCount();
    if (mounted) {
      setState(() {
        _unreadNotifs = count;
      });
    }
  }

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
      backgroundColor: AppColors.background,
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
      floatingActionButton: _selectedIndex != 2 
          ? FloatingActionButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ChatScreen()),
                );
              },
              backgroundColor: Colors.white,
              child: const Icon(Icons.chat_bubble_rounded, color: Color(0xFF7C3AED)),
            )
          : null,
    );
  }

  Widget _buildBody() {
    if (_selectedIndex == 1) return const AnalyticsScreen();
    if (_selectedIndex == 2) {
      return AddTransactionScreen(onBack: () => setState(() => _selectedIndex = 0));
    }
    if (_selectedIndex == 3) return const BudgetScreen();
    if (_selectedIndex == 4) return const ProfileScreen();
    
    return SafeArea(
      child: SingleChildScrollView(
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
      ),
    );
  }

  Widget _buildAbstractBackground() {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Abstract Polar Orbs (Moving Orbs)
            ...List.generate(3, (index) {
              final speeds = [0.2, 0.3, 0.15];
              final sizes = [220.0, 160.0, 80.0];
              final colors = [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.04),
              ];
              
              final speed = speeds[index];
              final size = sizes[index];
              
              final angle = _animationController.value * math.pi * 2;
              final offsetX = math.cos(angle + index) * 15;
              final offsetY = math.sin(angle + index) * 20;

              return Positioned(
                top: index == 0 ? -60 + offsetY : (index == 1 ? 100 + offsetY : null),
                bottom: index == 2 ? -20 + offsetY : null,
                right: index == 0 ? -50 + offsetX : (index == 2 ? 60 + offsetX : null),
                left: index == 1 ? -40 + offsetX : null,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colors[index],
                  ),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          // Background animation disabled for stability
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Top Row (Avatar & Notif)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 45,
                          height: 45,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'G',
                              style: const TextStyle(
                                color: Color(0xFF1E3A8A),
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _getGreeting(),
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              _userName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationScreen()),
                      ).then((_) => _checkUnreadNotifs()),
                      icon: Stack(
                        children: [
                          const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 28),
                          if (_unreadNotifs > 0)
                            Positioned(
                              right: 0,
                              top: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                                child: Text(
                                  '$_unreadNotifs',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Balance Card
                ValueListenableBuilder<List<TransactionModel>>(
                  valueListenable: TransactionData().transactionsNotifier,
                  builder: (context, transactions, child) {
                    double totalIncome = 0;
                    double totalExpense = 0;
                    for (var tx in transactions) {
                      if (tx.isIncome) totalIncome += tx.amount;
                      else totalExpense += tx.amount;
                    }
                    double totalBalance = totalIncome - totalExpense;
                    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);

                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Total Saldo Anda", style: TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          Text(
                            format.format(totalBalance),
                            style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildBalanceInfo("Pemasukan", format.format(totalIncome), Icons.arrow_downward, Colors.greenAccent),
                              _buildBalanceInfo("Pengeluaran", format.format(totalExpense), Icons.arrow_upward, Colors.redAccent),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBalanceInfo(String label, String amount, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: Colors.white60, fontSize: 11)),
            Text(amount, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ],
        ),
      ],
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ScanScreen()),
                  );
                },
              ),
              _buildActionItem(
                icon: Icons.add,
                label: 'Manual',
                color: const Color(0xFFD1FAE5),
                iconColor: const Color(0xFF059669),
                onTap: () {
                  setState(() {
                    _selectedIndex = 2;
                  });
                },
              ),
              _buildActionItem(
                icon: Icons.chat_bubble_rounded,
                label: 'AI Chat',
                color: const Color(0xFFF3E8FF),
                iconColor: const Color(0xFF7C3AED),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ChatScreen()),
                  );
                },
              ),
              _buildActionItem(
                icon: Icons.history,
                label: 'History',
                color: const Color(0xFFFFEDD5),
                iconColor: const Color(0xFFD97706),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({required IconData icon, required String label, required Color color, required Color iconColor, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
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
      ),
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
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                  );
                },
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
          ValueListenableBuilder<List<TransactionModel>>(
            valueListenable: TransactionData().transactionsNotifier,
            builder: (context, transactions, child) {
              if (transactions.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: const BoxDecoration(
                            color: Color(0xFFF1F5F9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "Belum Ada Transaksi",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF475569),
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Ayo mulai catat pengeluaran harianmu!",
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF94A3B8),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
              
              try {
                // Show max 5 items in home screen
                final recentTxs = transactions.take(5).toList();
                
                return Column(
                  children: recentTxs.map((tx) {
                    final format = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
                    final timeFormat = DateFormat('hh:mm a');
                    return _buildTransactionItem(
                      id: tx.id,
                      title: tx.title,
                      category: tx.currencyCode == 'IDR' 
                          ? "${tx.category} • ${timeFormat.format(tx.date)}"
                          : "${tx.category} • ${tx.currencyCode} ${tx.originalAmount.toInt()} • ${timeFormat.format(tx.date)}",
                      amount: "${tx.isIncome ? '+' : '-'}${format.format(tx.amount)}",
                      date: DateFormat('MMM dd').format(tx.date),
                      icon: tx.icon,
                      bgColor: tx.bgColor,
                      iconColor: tx.iconColor,
                      isIncome: tx.isIncome,
                      context: context,
                    );
                  }).toList(),
                );
              } catch (e) {
                debugPrint("Error rendering transaction list: $e");
                return const SizedBox.shrink();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem({
    required String id,
    required String title,
    required String category,
    required String amount,
    required String date,
    required IconData icon,
    required Color bgColor,
    required Color iconColor,
    required bool isIncome,
    required BuildContext context,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => TransactionDetailScreen(transactionId: id)),
        );
      },
      child: Container(
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
              _buildNavItem(icon: Icons.account_balance_wallet_outlined, label: 'Budget', index: 3),
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
    
    if (index == 2) {
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
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFF2962FF),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: const Color(0xFF2962FF),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

    if (index == 3) {
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
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFFF3E8FF) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
                size: 26,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? const Color(0xFF7C3AED) : const Color(0xFF94A3B8),
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      );
    }

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
