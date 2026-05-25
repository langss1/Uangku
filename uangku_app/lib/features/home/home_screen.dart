import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import 'dart:math' as math;
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/utils/responsive.dart';
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
import 'package:uangku_app/core/services/secure_storage_helper.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  String _userName = 'Guest';
  String? _profileImagePath;
  int _unreadNotifs = 0;

  late AnimationController _animationController;
  late AnimationController _waveController;
  late Animation<double> _waveAnimation;
  Timer? _waveTimer;
  Timer? _popupTimer;
  bool _showChatPopup = false;

  // Draggable chatbot position
  double _dragX = -1; // -1 = not initialized yet
  double _dragY = -1;
  bool _isDragging = false;

  void _triggerPopup() {
    if (!mounted) return;
    setState(() => _showChatPopup = true);
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showChatPopup = false);
      }
    });
  }

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

    // Popup chatbot every 90 seconds (stays for 5 seconds)
    Future.delayed(const Duration(seconds: 5), () {
      _triggerPopup();
    });
    _popupTimer = Timer.periodic(const Duration(seconds: 90), (timer) {
      _triggerPopup();
    });
  }

  @override
  void dispose() {
    _waveTimer?.cancel();
    _popupTimer?.cancel();
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
      final secureName = await SecureStorageHelper.getUserName();
      if (mounted) {
        setState(() {
          _userName = secureName ?? prefs.getString('user_name') ?? 'Guest';
          _profileImagePath = prefs.getString('profile_image_path');
        });
      }
      // Load budgets at startup so threshold notifications can check them immediately
      BudgetData().loadBudgets().catchError((e) => debugPrint("Budget load error: $e"));

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
    final screenW = MediaQuery.of(context).size.width;
    final screenH = MediaQuery.of(context).size.height;
    const botSize = 78.0;
    const navBarH = 90.0; // approx height of bottom nav

    // Initialize default position (bottom right, just above navbar)
    if (_dragX < 0) {
      _dragX = screenW - botSize - 16;
      _dragY = screenH - navBarH - botSize - 16;
    }

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      extendBody: true,
      body: Stack(
        children: [
          _buildBody(),
          // Draggable chatbot floating image
          // Chatbot popup tooltip (independent child in outer Stack to prevent hit-test clipping)
          if (_selectedIndex != 2 && _showChatPopup)
            Positioned(
              left: _dragX > screenW / 2 ? null : _dragX,
              right: _dragX > screenW / 2 ? (screenW - _dragX - botSize) : null,
              bottom: (screenH - _dragY) + 8,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 270),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF2563EB).withOpacity(0.3),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          '🤖 AI Chatbot',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                          ),
                        ),
                        // Tombol X untuk close popup
                        GestureDetector(
                          onTap: () => setState(() => _showChatPopup = false),
                          behavior: HitTestBehavior.opaque,
                          child: Container(
                            width: 24,
                            height: 24,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.25),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.close_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'AI Chatbot yang di personalisasi untuk keuangan anda',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        setState(() => _showChatPopup = false);
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChatScreen()),
                        );
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4.5),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Text(
                            'Chat Sekarang →',
                            style: TextStyle(
                              color: Color(0xFF1E3A8A),
                              fontWeight: FontWeight.w900,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Draggable chatbot floating image
          if (_selectedIndex != 2)
            Positioned(
              left: _dragX,
              top: _dragY,
              child: GestureDetector(
                onPanStart: (_) => setState(() => _isDragging = true),
                onPanUpdate: (details) {
                  setState(() {
                    _dragX = (_dragX + details.delta.dx).clamp(0.0, screenW - botSize);
                    _dragY = (_dragY + details.delta.dy).clamp(0.0, screenH - botSize);
                    _showChatPopup = false;
                  });
                },
                onPanEnd: (_) {
                  // Snap to nearest horizontal edge
                  final snapLeft = 16.0;
                  final snapRight = screenW - botSize - 16.0;
                  final snapX = (_dragX < screenW / 2) ? snapLeft : snapRight;
                  setState(() {
                    _dragX = snapX;
                    _isDragging = false;
                  });
                },
                onTap: () {
                  if (!_isDragging) {
                    setState(() => _showChatPopup = false);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ChatScreen()),
                    );
                  }
                },
                child: Stack(
                  children: [
                    // Pure chatbot.png image — no background
                    SizedBox(
                      width: botSize,
                      height: botSize,
                      child: Image.asset(
                        'assets/images/chatbot.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    // Green dot when popup is showing
                    if (_showChatPopup)
                      Positioned(
                        top: 2,
                        right: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }


  Widget _buildBody() {
    Widget activePage;
    if (_selectedIndex == 1) {
      activePage = const AnalyticsScreen(key: ValueKey('AnalyticsPage'));
    } else if (_selectedIndex == 2) {
      activePage = AddTransactionScreen(
        key: const ValueKey('AddTransactionPage'),
        onBack: () => setState(() => _selectedIndex = 0),
      );
    } else if (_selectedIndex == 3) {
      activePage = const BudgetScreen(key: ValueKey('BudgetPage'));
    } else if (_selectedIndex == 4) {
      activePage = const ProfileScreen(key: ValueKey('ProfilePage'));
    } else {
      activePage = SingleChildScrollView(
        key: const ValueKey('DashboardPage'),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildRecentTransactions(),
            const SizedBox(height: 100),
          ],
        ),
      );
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> animation) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0.03, 0.0), // elegant subtle slide in from right
              end: Offset.zero,
            ).animate(animation),
            child: child,
          ),
        );
      },
      child: activePage,
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
                      GestureDetector(
                        onTap: () async {
                          // Reload profile image when tapping avatar
                          final prefs = await SharedPreferences.getInstance();
                          if (mounted) {
                            setState(() {
                              _profileImagePath = prefs.getString('profile_image_path');
                            });
                          }
                        },
                        child: Container(
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
                          child: ClipOval(
                            child: _profileImagePath != null && File(_profileImagePath!).existsSync()
                                ? Image.file(
                                    File(_profileImagePath!),
                                    width: 54,
                                    height: 54,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
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
    final hPad = Responsive.r(context, 20);
    final vPad = Responsive.r(context, 8);
    return SafeArea(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        child: ClipRRect(
            borderRadius: BorderRadius.circular(Responsive.r(context, 36)),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: Responsive.r(context, 4)),
                decoration: BoxDecoration(
                  color: context.isDarkMode ? Colors.black.withOpacity(0.65) : Colors.white.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(Responsive.r(context, 36)),
                  border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.4), width: 1.5),
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
    final iconSize = Responsive.r(context, 24);
    final fontSize = Responsive.sp(context, 10);
    final btnSize = Responsive.r(context, 50);

    // Tombol + tengah
    if (index == 2) {
      return _AnimatedNavTap(
        onTap: () => setState(() => _selectedIndex = index),
        child: Container(
          width: btnSize,
          height: btnSize,
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
          child: Icon(Icons.add, color: Colors.white, size: iconSize + 4),
        ),
      );
    }

    return _AnimatedNavTap(
      onTap: () async {
        setState(() => _selectedIndex = index);
        if (index == 0) {
          await _loadUser();
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutBack,
        width: Responsive.r(context, 58),
        height: Responsive.r(context, 58),
        alignment: Alignment.center,
        decoration: isSelected
            ? BoxDecoration(
                // Lingkaran bulat sempurna, sangat tipis/halus (subtle)
                color: const Color(0xFF2563EB).withOpacity(0.08),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2563EB).withOpacity(0.06),
                    blurRadius: 8,
                    spreadRadius: 1,
                  ),
                ],
              )
            : const BoxDecoration(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: iconSize),
            SizedBox(height: Responsive.r(context, 2)),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: fontSize,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget helper: animasi scale saat icon/tab di-tap
class _AnimatedNavTap extends StatefulWidget {
  final Widget child;
  final VoidCallback onTap;
  const _AnimatedNavTap({required this.child, required this.onTap});

  @override
  State<_AnimatedNavTap> createState() => _AnimatedNavTapState();
}

class _AnimatedNavTapState extends State<_AnimatedNavTap>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.82)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _onTap() async {
    await _ctrl.forward();
    await _ctrl.reverse();
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _onTap,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
