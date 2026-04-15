import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/features/splash/splash_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  Future<void> _logout(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);

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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () {
            // Usually goes back to home tab, but parent controls the tab.
            // Leaving as placeholder or call a callback.
          },
        ),
        title: const Text(
          'Export & Profile',
          style: TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(color: Colors.grey.shade100, height: 1.0),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Profile Management Section
            const Text(
              'Profile Management',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Manage your account settings and preferences',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            
            // User Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.grey.shade200,
                        // Using a generic person icon if no picture is loaded
                        child: const Icon(Icons.person, size: 36, color: Colors.grey),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt, size: 16, color: Color(0xFF2962FF)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Sarah Johnson',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'sarah.johnson@email.com',
                          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(20)),
                          child: const Text('Verified', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Color(0xFF059669))),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Settings List
            _buildSettingTile(
              icon: Icons.person_outline,
              iconBgColor: const Color(0xFFDBEAFE),
              iconColor: const Color(0xFF2563EB),
              title: 'Personal Information',
              subtitle: 'Update name, email, phone',
            ),
            _buildSettingTile(
              icon: Icons.security_outlined,
              iconBgColor: const Color(0xFFD1FAE5),
              iconColor: const Color(0xFF059669),
              title: 'Security Settings',
              subtitle: 'Password, 2FA, sessions',
            ),
            _buildSettingTile(
              icon: Icons.smartphone,
              iconBgColor: const Color(0xFFF3E8FF),
              iconColor: const Color(0xFF7C3AED),
              title: 'Manage 2FA',
              subtitle: 'Two-factor authentication',
              trailingText: 'Enabled',
              trailingColor: const Color(0xFFD1FAE5),
              trailingTextColor: const Color(0xFF059669),
            ),
            _buildSettingTile(
              icon: Icons.notifications_none_outlined,
              iconBgColor: const Color(0xFFFEF3C7),
              iconColor: const Color(0xFFD97706),
              title: 'Notifications',
              subtitle: 'Email, push preferences',
            ),
            _buildSettingTile(
              icon: Icons.settings_outlined,
              iconBgColor: const Color(0xFFF1F5F9),
              iconColor: const Color(0xFF475569),
              title: 'App Preferences',
              subtitle: 'Theme, language, currency',
            ),
            _buildSettingTile(
              icon: Icons.help_outline,
              iconBgColor: const Color(0xFFFFEDD5),
              iconColor: const Color(0xFFEA580C),
              title: 'Help & Support',
              subtitle: 'FAQ, contact support',
            ),
            
            const SizedBox(height: 32),
            
            // Export Reports Section
            const Text(
              'Export Reports',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textDark),
            ),
            const SizedBox(height: 4),
            const Text(
              'Download your financial reports in preferred format',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 20),
            
            _buildInputLabel('Select Date Range'),
            const SizedBox(height: 8),
            _buildDatePicker(label: 'Start Date', value: '2024-01-01'),
            const SizedBox(height: 12),
            _buildDatePicker(label: 'End Date', value: '2024-12-31'),
            
            const SizedBox(height: 24),
            
            _buildInputLabel('Choose Export Format'),
            const SizedBox(height: 12),
            
            // Export formats
            _buildFormatTile(
              icon: Icons.picture_as_pdf,
              iconBgColor: const Color(0xFFFEE2E2),
              iconColor: const Color(0xFFDC2626),
              title: 'PDF Report',
              subtitle: 'Formatted financial report',
            ),
            const SizedBox(height: 12),
            _buildFormatTile(
              icon: Icons.insert_drive_file_outlined,
              iconBgColor: const Color(0xFFD1FAE5),
              iconColor: const Color(0xFF059669),
              title: 'CSV File',
              subtitle: 'Raw data for analysis',
            ),
            
            const SizedBox(height: 40),
            
            // Logout Button
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, size: 20, color: Colors.white),
              label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48), // Bright Red
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Center(
              child: Text(
                'Version 2.1.4 • Last sync: 2 minutes ago',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF475569)));
  }

  Widget _buildDatePicker({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF94A3B8))),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textDark)),
              const Icon(Icons.calendar_today_outlined, size: 20, color: Color(0xFF94A3B8)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
    String? trailingText,
    Color? trailingColor,
    Color? trailingTextColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
              ],
            ),
          ),
          if (trailingText != null)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: trailingColor, borderRadius: BorderRadius.circular(20)),
              child: Text(trailingText, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: trailingTextColor)),
            ),
          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 24),
        ],
      ),
    );
  }

  Widget _buildFormatTile({
    required IconData icon,
    required Color iconBgColor,
    required Color iconColor,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: iconBgColor, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B))),
              ],
            ),
          ),
          const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1), size: 24),
        ],
      ),
    );
  }
}
