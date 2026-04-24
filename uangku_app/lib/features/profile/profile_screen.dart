import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/features/splash/splash_screen.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:uangku_app/features/profile/screens/export_preview_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  DateTimeRange? _selectedDateRange;
  String _userName = 'Loading...';
  String _userEmail = 'Loading...';

  @override
  void initState() {
    super.initState();
    // Default to last 30 days
    _selectedDateRange = DateTimeRange(
      start: DateTime.now().subtract(const Duration(days: 30)),
      end: DateTime.now(),
    );
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    // Load cached first
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
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        setState(() {
          _userName = data['user']['full_name'];
          _userEmail = data['user']['email'];
        });
        
        // Update cache
        await prefs.setString('user_name', _userName);
        await prefs.setString('user_email', _userEmail);
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
    }
  }

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

  Future<void> _selectCustomDateRange() async {
    DateTime? tempStart = _selectedDateRange?.start ?? DateTime.now().subtract(const Duration(days: 30));
    DateTime? tempEnd = _selectedDateRange?.end ?? DateTime.now();

    final picked = await showDialog<DateTimeRange>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text(
                'Custom Date Range',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Select your start and end date below:', style: TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: tempStart!,
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2101),
                            );
                            if (date != null) {
                              setDialogState(() => tempStart = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text('Start Date', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text(
                                  DateFormat('dd MMM yyyy').format(tempStart!),
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: tempEnd ?? tempStart!,
                              firstDate: tempStart!,
                              lastDate: DateTime(2101),
                            );
                            if (date != null) {
                              setDialogState(() => tempEnd = date);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              children: [
                                const Text('End Date', style: TextStyle(fontSize: 11, color: Colors.black54)),
                                const SizedBox(height: 4),
                                Text(
                                  tempEnd != null ? DateFormat('dd MMM yyyy').format(tempEnd!) : 'Select',
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.black54)),
                ),
                ElevatedButton(
                  onPressed: () {
                    if (tempStart != null && tempEnd != null) {
                      Navigator.pop(context, DateTimeRange(start: tempStart!, end: tempEnd!));
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2962FF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                  child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ],
            );
          },
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
    }
  }

  void _navigateToPreview(String format) {
    if (_selectedDateRange == null) return;
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ExportPreviewScreen(
          dateRange: _selectedDateRange!,
          exportFormat: format,
          userName: 'Sarah Johnson', // Hardcoded as per existing UI
        ),
      ),
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
          onPressed: () {},
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
                        Text(
                          _userName,
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _userEmail,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Color(0xFF64748B)),
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
            
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildInputLabel('Select Date Range'),
                GestureDetector(
                  onTap: _selectCustomDateRange,
                  child: const Text(
                    'Change',
                    style: TextStyle(
                      color: Color(0xFF2962FF),
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _selectCustomDateRange,
              child: _buildDatePicker(
                label: 'Start Date', 
                value: DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: _selectCustomDateRange,
              child: _buildDatePicker(
                label: 'End Date', 
                value: DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)
              ),
            ),
            
            const SizedBox(height: 24),
            
            _buildInputLabel('Choose Export Format'),
            const SizedBox(height: 12),
            
            GestureDetector(
              onTap: () => _navigateToPreview('PDF'),
              child: _buildFormatTile(
                icon: Icons.picture_as_pdf,
                iconBgColor: const Color(0xFFFEE2E2),
                iconColor: const Color(0xFFDC2626),
                title: 'PDF Report',
                subtitle: 'Formatted financial report',
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _navigateToPreview('CSV'),
              child: _buildFormatTile(
                icon: Icons.insert_drive_file_outlined,
                iconBgColor: const Color(0xFFD1FAE5),
                iconColor: const Color(0xFF059669),
                title: 'CSV File',
                subtitle: 'Raw data for analysis',
              ),
            ),
            
            const SizedBox(height: 40),
            
            ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout, size: 20, color: Colors.white),
              label: const Text('Logout', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE11D48),
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
