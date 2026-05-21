import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:uangku_app/core/providers/preferences_provider.dart';
import 'package:uangku_app/features/splash/splash_screen.dart';
import 'package:uangku_app/features/profile/profile_screen.dart';
import 'package:uangku_app/core/models/transaction_model.dart';
import 'package:uangku_app/core/data/transaction_data.dart';
import 'package:uangku_app/core/data/budget_data.dart';
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

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String _userName = 'Guest';
  int _unreadNotifs = 0;

  late AnimationController _animationController;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  Timer? _waveTimer;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _waveAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 0.08).chain(CurveTween(curve: Curves.easeOut)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.05).chain(CurveTween(curve: Curves.easeInOut)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.08).chain(CurveTween(curve: Curves.easeInOut)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 0.08, end: -0.05).chain(CurveTween(curve: Curves.easeInOut)), weight: 1),
      TweenSequenceItem(tween: Tween(begin: -0.05, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 1),
    ]).animate(_waveController);

    // Initial wave after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _waveController.forward();
    });

    // Wave every 10 seconds
    _waveTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (mounted) {
        _waveController.forward(from: 0.0);
      }
    });
  }

  @override
  void dispose() {
    _waveTimer?.cancel();
    _waveController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  String _getGreeting(bool isIndo) {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return isIndo ? 'Selamat Pagi' : 'Good Morning';
    } else if (hour < 17) {
      return isIndo ? 'Selamat Siang' : 'Good Afternoon';
    } else if (hour < 20) {
      return isIndo ? 'Selamat Sore' : 'Good Evening';
    } else {
      return isIndo ? 'Selamat Malam' : 'Good Night';
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
    
    BudgetData().clearMemory();
    TransactionData().clearMemory();
    
    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      extendBody: true,
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
              backgroundColor: context.surfaceColor,
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
    
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildHeader(),
          const SizedBox(height: 32),
          _buildRecentTransactions(),
          const SizedBox(height: 100), // Increased to prevent content from hiding behind floating nav
        ],
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
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)], // Matched with Budget Screen
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: _buildAbstractBackground()), // Polar circles background
          SafeArea(
            bottom: false,
            child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Row (Avatar, Name, Notif)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 54,
                        height: 54,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            _userName.isNotEmpty ? _userName[0].toUpperCase() : 'G',
                            style: const TextStyle(
                              color: Color(0xFF2563EB),
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Builder(builder: (context) {
                                final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
                                return Text(
                                  _getGreeting(isIndo),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.85),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                );
                              }),
                              const SizedBox(width: 4),
                              RotationTransition(
                                turns: _waveAnimation,
                                alignment: Alignment.bottomRight,
                                child: const Text(
                                  '👋',
                                  style: TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                          Text(
                            _userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
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
                                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                                child: Text(
                                  '$_unreadNotifs',
                                  style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
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
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Builder(builder: (context) {
                          final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
                          return Text(
                            isIndo ? "Total Saldo" : "Total Balance", 
                            style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500)
                          );
                        }),
                        const SizedBox(height: 8),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            format.format(totalBalance).replaceAll('Rp ', 'Rp '),
                            style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Builder(builder: (context) {
                          final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
                          return Row(
                            children: [
                              Expanded(child: _buildBalanceInfo(isIndo ? "Masuk:" : "In:", format.format(totalIncome), Colors.greenAccent)),
                              const SizedBox(width: 12),
                              Expanded(child: _buildBalanceInfo(isIndo ? "Keluar:" : "Out:", format.format(totalExpense), Colors.redAccent)),
                            ],
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ), // End Padding
      ), // End SafeArea
        ],
      ), // End Stack
    );
  }

  Widget _buildBalanceInfo(String label, String amount, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            "$label $amount", 
            style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Builder(builder: (context) {
        final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isIndo ? 'Aksi Cepat' : 'Quick Actions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: context.textPrimary,
              ),
            ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildActionItem(
                icon: Icons.qr_code_scanner,
                label: isIndo ? 'Pindai' : 'Scan',
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
                label: isIndo ? 'Riwayat' : 'History',
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
        );
      }),
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: context.textSecondary,
          ),
        ),
      ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Builder(builder: (context) {
        final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isIndo ? 'Transaksi Terakhir' : 'Recent Transactions',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: context.textPrimary,
                  ),
                ),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
                  );
                },
                child: Text(
                  isIndo ? 'Lihat Semua' : 'See All',
                  style: const TextStyle(
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
                          decoration: BoxDecoration(
                            color: context.borderColor,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long_outlined,
                            size: 64,
                            color: context.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          isIndo ? "Belum Ada Transaksi" : "No Transactions Yet",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          isIndo ? "Ayo mulai catat pengeluaran harianmu!" : "Start recording your daily expenses!",
                          style: TextStyle(
                            fontSize: 13,
                            color: context.textSecondary,
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
        );
      }),
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: context.borderColor, width: 1.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: bgColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: context.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    category,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: context.textSecondary,
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
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                    color: isIncome ? const Color(0xFF059669) : const Color(0xFFDC2626),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  date,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFCBD5E1),
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
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16), // Stronger blur
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: context.isDarkMode ? Colors.black.withOpacity(0.65) : Colors.white.withOpacity(0.65), // More transparent to see background
                  borderRadius: BorderRadius.circular(32), // Pill shaped
                  border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.4), width: 1.5), // Blue outline
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Builder(builder: (context) {
                      final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
                      return _buildNavItem(icon: Icons.home_rounded, label: isIndo ? 'Beranda' : 'Home', index: 0);
                    }),
                    Builder(builder: (context) {
                      final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
                      return _buildNavItem(icon: Icons.analytics_outlined, label: isIndo ? 'Analisis' : 'Analytics', index: 1);
                    }),
                    Builder(builder: (context) {
                      final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
                      return _buildNavItem(icon: Icons.add, label: isIndo ? 'Tambah' : 'Add', index: 2);
                    }),
                    Builder(builder: (context) {
                      final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
                      return _buildNavItem(icon: Icons.account_balance_wallet_outlined, label: isIndo ? 'Anggaran' : 'Budget', index: 3);
                    }),
                    Builder(builder: (context) {
                      final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
                      return _buildNavItem(icon: Icons.person_outline, label: isIndo ? 'Profil' : 'Profile', index: 4);
                    }),
                  ],
                ),
              ),
            ),
          ),
        ),
    );
  }

  Widget _buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    final color = isSelected ? const Color(0xFF2563EB) : const Color(0xFF94A3B8);
    
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
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.4),
                    blurRadius: 15,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 28),
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
      child: SizedBox(
        width: 56, // Fixed width to ensure even spacing
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: isSelected
                  ? BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2563EB).withOpacity(0.35),
                          blurRadius: 20,
                          spreadRadius: 8,
                        ),
                      ],
                    )
                  : null,
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.visible,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
