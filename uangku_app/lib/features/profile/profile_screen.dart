import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/utils/responsive.dart';
import 'package:uangku_app/features/splash/splash_screen.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:uangku_app/core/services/network_service.dart';
import 'package:uangku_app/core/services/secure_storage_helper.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
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
import 'package:uangku_app/core/database/database_helper.dart';
import 'package:uangku_app/core/services/notification_service.dart';

import 'package:uangku_app/core/data/budget_data.dart';
import 'package:uangku_app/core/data/transaction_data.dart';
import 'package:provider/provider.dart';
import 'package:uangku_app/core/providers/preferences_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with SingleTickerProviderStateMixin {
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';
  bool _morningReport = true;
  bool _budgetAlerts = true;
  bool _aiInsights = true;
  bool _is2FAActive = false;
  bool _isLoading = true;
  String? _profileImagePath;

  // Animasi fade-in saat halaman tampil
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _loadSettings();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
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

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<void> _updateNotificationSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await SecureStorageHelper.getToken();

    setState(() {
      if (key == 'pref_morning_report') _morningReport = value;
      if (key == 'pref_budget_alerts') _budgetAlerts = value;
      if (key == 'pref_ai_insights') _aiInsights = value;
    });

    try {
      await prefs.setBool(key, value);
      
      if (token != null) {
        await NetworkService.put(
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
    final token = await SecureStorageHelper.getToken();
    
    if (mounted) {
      final secureName = await SecureStorageHelper.getUserName();
      final secureEmail = await SecureStorageHelper.getUserEmail();
      setState(() {
        _userName = secureName ?? prefs.getString('user_name') ?? 'Guest User';
        _userEmail = secureEmail ?? prefs.getString('user_email') ?? '-';
        _profileImagePath = prefs.getString('profile_image_path');
      });
    }

    if (token == null) return;

    try {
      final response = await NetworkService.get(
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
        await SecureStorageHelper.saveUserData(name: _userName, email: _userEmail);
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
    // Ambil email sebelum dihapus untuk cleanup
    final userEmail = await SecureStorageHelper.getUserEmail() ?? '';

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

    // Hapus SharedPreferences yang di-scope ke user ini
    await prefs.remove('profile_image_path');
    await prefs.remove('user_name');
    await prefs.remove('user_email');

    // Hapus SecureStorage (token + user info)
    await SecureStorageHelper.clearAll();

    // Bersihkan notifikasi state untuk user ini
    await NotificationService().clearUserNotificationPrefs(userEmail);

    // Reset memory data
    BudgetData().clearMemory();
    TransactionData().clearMemory();

    // Reset database connection agar login berikutnya pakai user context baru
    await DatabaseHelper.instance.closeAndReset();

    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const SplashScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', image.path);
      if (mounted) {
        setState(() {
          _profileImagePath = image.path;
        });
      }
    }
  }

  Future<void> _removePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_image_path');
    if (mounted) {
      setState(() {
        _profileImagePath = null;
      });
    }
  }

  void _showPhotoOptions() {
    final isIndo = Provider.of<PreferencesProvider>(context, listen: false).language.toLowerCase() == 'id';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: AppColors.primaryBlue, size: 22),
                  ),
                  title: Text(
                    isIndo ? 'Pilih dari Galeri' : 'Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage();
                  },
                ),
                if (_profileImagePath != null) ...[
                  Divider(height: 1, indent: 20, endIndent: 20, color: context.borderColor),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE11D48), size: 22),
                    ),
                    title: Text(
                      isIndo ? 'Hapus Foto Profil' : 'Remove Profile Photo',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE11D48)),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _removePhoto();
                    },
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIndo = Provider.of<PreferencesProvider>(context).language.toLowerCase() == 'id';
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(isIndo),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  Responsive.r(context, 20),
                  Responsive.r(context, 36),
                  Responsive.r(context, 20),
                  Responsive.r(context, 180),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(height: Responsive.r(context, 16)),
                    _buildSectionHeader(isIndo ? 'AKUN & KEAMANAN' : 'ACCOUNT & SECURITY'),
                    _buildGroupCard([
                      _buildSettingTile(
                        icon: Icons.person_outline_rounded,
                        iconColor: AppColors.primaryBlue,
                        title: isIndo ? 'Informasi Profil' : 'Profile Information',
                        subtitle: isIndo ? 'Ubah nama dan email kamu' : 'Change your name and email',
                        onTap: () => _navigateToEditor(isIndo ? 'Informasi Personal' : 'Personal Information', false),
                      ),
                      _buildSettingTile(
                        icon: Icons.lock_outline_rounded,
                        iconColor: AppColors.primaryBlue,
                        title: isIndo ? 'Ganti Password' : 'Change Password',
                        subtitle: isIndo ? 'Perbarui kata sandi akun' : 'Update account password',
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
                        title: isIndo ? 'Autentikasi 2-Faktor' : '2-Factor Authentication',
                        subtitle: isIndo ? 'Keamanan ekstra untuk akun' : 'Extra security for your account',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const TwoFactorAuthScreen()),
                          );
                        },
                      ),
                    ]),
                    
                    SizedBox(height: Responsive.r(context, 24)),
                    _buildSectionHeader(isIndo ? 'NOTIFIKASI' : 'NOTIFICATIONS'),
                    _buildGroupCard([
                      _buildSwitchTile(
                        icon: Icons.wb_sunny_outlined,
                        iconColor: AppColors.primaryBlue,
                        title: isIndo ? 'Laporan Harian' : 'Daily Report',
                        subtitle: isIndo ? 'Ringkasan keuangan setiap pagi' : 'Financial summary every morning',
                        value: _morningReport,
                        onChanged: (val) => _updateNotificationSetting('pref_morning_report', val),
                      ),
                      _buildSwitchTile(
                        icon: Icons.notification_important_outlined,
                        iconColor: AppColors.primaryBlue,
                        title: isIndo ? 'Peringatan Anggaran' : 'Budget Alerts',
                        subtitle: isIndo ? 'Notif saat pengeluaran melebihi limit' : 'Notify when expenses exceed limit',
                        value: _budgetAlerts,
                        onChanged: (val) => _updateNotificationSetting('pref_budget_alerts', val),
                      ),
                      _buildSwitchTile(
                        icon: Icons.auto_awesome_outlined,
                        iconColor: AppColors.primaryBlue,
                        title: isIndo ? 'Wawasan AI' : 'AI Insights',
                        subtitle: isIndo ? 'Tips cerdas dari Gemini AI' : 'Smart tips from Gemini AI',
                        value: _aiInsights,
                        onChanged: (val) => _updateNotificationSetting('pref_ai_insights', val),
                      ),
                    ]),
                    
                    SizedBox(height: Responsive.r(context, 24)),
                    _buildSectionHeader(isIndo ? 'PREFERENSI APLIKASI' : 'APP PREFERENCES'),
                    _buildGroupCard([
                      _buildSettingTile(
                        icon: Icons.palette_outlined,
                        iconColor: AppColors.primaryBlue,
                        title: isIndo ? 'Tema Aplikasi' : 'App Theme',
                        subtitle: isIndo ? 'Terang, Gelap, atau Sistem' : 'Light, Dark, or System',
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
                        title: isIndo ? 'Bahasa' : 'Language',
                        subtitle: isIndo ? 'Indonesia (ID)' : 'English (US)',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const LanguageSettingsScreen()),
                          );
                        },
                      ),
                    ]),
                    
                    SizedBox(height: Responsive.r(context, 24)),
                    _buildSectionHeader(isIndo ? 'DUKUNGAN' : 'SUPPORT'),
                    _buildGroupCard([
                      _buildSettingTile(
                        icon: Icons.help_outline_rounded,
                        iconColor: AppColors.primaryBlue,
                        title: isIndo ? 'Pusat Bantuan' : 'Help Center',
                        subtitle: isIndo ? 'FAQ dan bantuan teknis' : 'FAQ and technical support',
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
                        title: isIndo ? 'Tentang Uangku' : 'About Uangku',
                        subtitle: isIndo ? 'Versi 2.1.4' : 'Version 2.1.4',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const AboutScreen()),
                          );
                        },
                      ),
                    ]),
                    
                    SizedBox(height: Responsive.r(context, 40)),
                    _buildLogoutButton(isIndo),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _navigateToEditor(String title, bool isSecurity) async {
    final isIndo = Provider.of<PreferencesProvider>(context, listen: false).language.toLowerCase() == 'id';
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsEditorScreen(
          title: title,
          subtitle: isSecurity 
              ? (isIndo ? 'Perbarui keamanan akun kamu' : 'Update your account security') 
              : (isIndo ? 'Update profil kamu' : 'Update your profile'),
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

  Widget _buildHeader(bool isIndo) {
    final avatarRadius = Responsive.r(context, 50);
    final titleFontSize = Responsive.sp(context, 18);
    final nameFontSize = Responsive.sp(context, 22);
    final emailFontSize = Responsive.sp(context, 14);
    final topPad = MediaQuery.of(context).padding.top + Responsive.r(context, 20);

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
            padding: EdgeInsets.fromLTRB(24, topPad, 24, Responsive.r(context, 40)),
            child: SizedBox(
              width: double.infinity,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                Text(
                  isIndo ? 'Profil Saya' : 'My Profile',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: Responsive.r(context, 24)),
                // Avatar dengan Hero animation
                Hero(
                  tag: 'profile_avatar',
                  child: Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: avatarRadius,
                          backgroundColor: Colors.white,
                          child: _profileImagePath != null
                              ? ClipOval(
                                  child: Image.file(
                                    File(_profileImagePath!),
                                    width: avatarRadius * 2,
                                    height: avatarRadius * 2,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(Icons.person, size: avatarRadius * 1.2, color: const Color(0xFF1E3A8A)),
                        ),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: _showPhotoOptions,
                          child: Container(
                            padding: EdgeInsets.all(Responsive.r(context, 8)),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.15),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(Icons.camera_alt, size: Responsive.r(context, 18), color: const Color(0xFF1E3A8A)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: Responsive.r(context, 16)),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _userName,
                    style: TextStyle(color: Colors.white, fontSize: nameFontSize, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 4),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    _userEmail,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: emailFontSize),
                  ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    List<Widget> dividedChildren = [];
    for (int i = 0; i < children.length; i++) {
      dividedChildren.add(children[i]);
      if (i < children.length - 1) {
        dividedChildren.add(
          Divider(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.06),
            height: 1,
            thickness: 0.5,
            indent: 20,
            endIndent: 20,
          ),
        );
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: dividedChildren),
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
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
        child: Icon(icon, color: iconColor, size: 22),
      ),
      title: Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: context.textPrimary)),
      subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: context.textSecondary)),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF0056B3),
      ),
    );
  }

  Widget _buildLogoutButton(bool isIndo) {
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
          children: [
            const Icon(Icons.logout_rounded, size: 20),
            const SizedBox(width: 10),
            Text(isIndo ? 'Keluar Akun' : 'Log Out', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}
