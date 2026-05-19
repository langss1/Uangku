import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/features/splash/splash_screen.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uangku_app/features/profile/screens/notification_settings_screen.dart';
import 'package:uangku_app/features/notification/screens/notification_screen.dart';
import 'package:uangku_app/features/profile/screens/settings_screen.dart';
import 'package:uangku_app/features/profile/screens/dummy_screens.dart';
import 'package:uangku_app/features/profile/screens/change_password_screen.dart';
import 'package:uangku_app/features/profile/screens/two_factor_auth_screen.dart';
import 'package:uangku_app/features/profile/screens/theme_settings_screen.dart';
import 'package:uangku_app/features/profile/screens/language_settings_screen.dart';
import 'package:uangku_app/features/profile/screens/about_screen.dart';
import 'package:uangku_app/features/profile/screens/help_center_screen.dart';

import 'package:uangku_app/core/data/budget_data.dart';
import 'package:uangku_app/core/data/transaction_data.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';
  bool _morningReport = true;
  bool _budgetAlerts = true;
  bool _aiInsights = true;
  bool _is2FAActive = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _morningReport = prefs.getBool('pref_morning_report') ?? true;
      _budgetAlerts = prefs.getBool('pref_budget_alerts') ?? true;
      _aiInsights = prefs.getBool('pref_ai_insights') ?? true;
      _is2FAActive = prefs.getBool('is_2fa_active') ?? false;
      _isLoading = false;
    });
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    setState(() {
      if (key == 'pref_morning_report') _morningReport = value;
      if (key == 'pref_budget_alerts') _budgetAlerts = value;
      if (key == 'pref_ai_insights') _aiInsights = value;
    });

    try {
      await prefs.setBool(key, value);
      
      if (token != null) {
        await http.put(
          Uri.parse('http://145.79.10.157:8000/api/auth/preferences'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'pref_morning_report': _morningReport,
            'pref_budget_alerts': _budgetAlerts,
            'pref_ai_insights': _aiInsights,
          }),
        );
      }
    } catch (e) {
      debugPrint('Error updating preferences on server: $e');
    }
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (mounted) {
      setState(() {
        _userName = prefs.getString('user_name') ?? 'Guest User';
        _userEmail = prefs.getString('user_email') ?? '-';
      });
    }

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://145.79.10.157:8000/api/auth/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final user = data['user'];
        setState(() {
          _userName = user['full_name'] ?? _userName;
          _userEmail = user['email'] ?? _userEmail;
          if (user['pref_morning_report'] != null) _morningReport = user['pref_morning_report'];
          if (user['pref_budget_alerts'] != null) _budgetAlerts = user['pref_budget_alerts'];
          if (user['pref_ai_insights'] != null) _aiInsights = user['pref_ai_insights'];
        });
        await prefs.setString('user_name', _userName);
        await prefs.setString('user_email', _userEmail);
        await prefs.setBool('pref_morning_report', _morningReport);
        await prefs.setBool('pref_budget_alerts', _budgetAlerts);
        await prefs.setBool('pref_ai_insights', _aiInsights);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    
    BudgetData().clearMemory();
    TransactionData().clearMemory();
    
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('AKUN & KEAMANAN'),
                  _buildGroupCard([
                    _buildSettingTile(
                      icon: Icons.person_outline_rounded,
                      iconColor: AppColors.primaryBlue,
                      title: 'Informasi Profil',
                      subtitle: 'Ubah nama dan email kamu',
                      onTap: () => _navigateToEditor('Personal Information', false),
                    ),
                    _buildSettingTile(
                      icon: Icons.lock_outline_rounded,
                      iconColor: AppColors.primaryBlue,
                      title: 'Ganti Password',
                      subtitle: 'Perbarui kata sandi akun',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ChangePasswordScreen()),
                        );
                      },
                    ),
                    _buildSettingTile(
                      icon: Icons.security_rounded,
                      iconColor: AppColors.primaryBlue,
                      title: 'Autentikasi 2-Faktor',
                      subtitle: 'Keamanan ekstra untuk akun',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const TwoFactorAuthScreen()),
                        );
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader('NOTIFIKASI'),
                  _buildGroupCard([
                    _buildSwitchTile(
                      icon: Icons.wb_sunny_outlined,
                      iconColor: AppColors.primaryBlue,
                      title: 'Laporan Harian',
                      subtitle: 'Ringkasan keuangan setiap pagi',
                      value: _morningReport,
                      onChanged: (val) => _updateNotificationSetting('pref_morning_report', val),
                    ),
                    _buildSwitchTile(
                      icon: Icons.notification_important_outlined,
                      iconColor: AppColors.primaryBlue,
                      title: 'Peringatan Anggaran',
                      subtitle: 'Notif saat pengeluaran melebihi limit',
                      value: _budgetAlerts,
                      onChanged: (val) => _updateNotificationSetting('pref_budget_alerts', val),
                    ),
                    _buildSwitchTile(
                      icon: Icons.auto_awesome_outlined,
                      iconColor: AppColors.primaryBlue,
                      title: 'Wawasan AI',
                      subtitle: 'Tips cerdas dari Gemini AI',
                      value: _aiInsights,
                      onChanged: (val) => _updateNotificationSetting('pref_ai_insights', val),
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader('PREFERENSI APLIKASI'),
                  _buildGroupCard([
                    _buildSettingTile(
                      icon: Icons.palette_outlined,
                      iconColor: AppColors.primaryBlue,
                      title: 'Tema Aplikasi',
                      subtitle: 'Terang, Gelap, atau Sistem',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ThemeSettingsScreen()),
                        );
                      },
                    ),
                    _buildSettingTile(
                      icon: Icons.language_rounded,
                      iconColor: AppColors.primaryBlue,
                      title: 'Bahasa',
                      subtitle: 'Indonesia (ID)',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
                        );
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 24),
                  _buildSectionHeader('SUPPORT'),
                  _buildGroupCard([
                    _buildSettingTile(
                      icon: Icons.help_outline_rounded,
                      iconColor: AppColors.primaryBlue,
                      title: 'Pusat Bantuan',
                      subtitle: 'FAQ dan bantuan teknis',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                        );
                      },
                    ),
                    _buildSettingTile(
                      icon: Icons.info_outline_rounded,
                      iconColor: AppColors.primaryBlue,
                      title: 'Tentang Uangku',
                      subtitle: 'Versi 2.1.4',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AboutScreen()),
                        );
                      },
                    ),
                  ]),
                  
                  const SizedBox(height: 40),
                  _buildLogoutButton(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditor(String title, bool isSecurity) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsEditorScreen(
          title: title,
          subtitle: isSecurity ? 'Perbarui keamanan akun kamu' : 'Update profil kamu',
          isSecurity: isSecurity,
          initialName: _userName,
          initialEmail: _userEmail,
        ),
      ),
    );
    if (result == true) {
      _loadUserProfile();
      _loadSettings();
    }
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
      ),
      child: Stack(
        children: [
          // Polar decorations
          Positioned(
            top: -40,
            right: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            top: 40,
            left: 20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          
          // Main content
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 40),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                const Text(
                  'Profil Saya',
                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 30),
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                      child: const CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white,
                        child: Icon(Icons.person, size: 60, color: Color(0xFF1E3A8A)),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 18, color: Color(0xFF1E3A8A)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  _userName,
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  _userEmail,
                  style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: context.textSecondary, letterSpacing: 1.2),
      ),
    );
  }

  Widget _buildGroupCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 20, offset: const Offset(0, 10)),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: context.textSecondary)),
      trailing: Icon(Icons.chevron_right_rounded, color: context.textSecondary),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(fontSize: 12, color: context.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF0056B3),
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _logout(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: context.cardColor,
          foregroundColor: const Color(0xFFE11D48),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: Color(0xFFE11D48), width: 1.5),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.logout_rounded, size: 20),
            SizedBox(width: 10),
            Text('Keluar Akun', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
