import 'package:flutter/material.dart';
import 'package:uangku_app/core/utils/custom_popup.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  String _selectedTheme = 'Sistem';

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedTheme = prefs.getString('pref_app_theme') ?? 'Sistem';
    });
  }

  Future<void> _selectTheme(String theme) async {
    setState(() {
      _selectedTheme = theme;
    });
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_app_theme', theme);

    if (mounted) {
      CustomPopup.show(context, 'Tema aplikasi diubah ke $theme', isSuccess: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Tema Aplikasi',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sesuaikan tampilan aplikasi dengan preferensi Anda. Mode Gelap dapat membantu menghemat baterai.',
              style: TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
            const SizedBox(height: 32),

            _buildThemeCard(
              title: 'Terang (Light)',
              subtitle: 'Tampilan standar dengan dominasi warna putih yang bersih.',
              icon: Icons.light_mode_outlined,
              isSelected: _selectedTheme == 'Terang',
              onTap: () => _selectTheme('Terang'),
            ),
            
            const SizedBox(height: 16),
            
            _buildThemeCard(
              title: 'Gelap (Dark)',
              subtitle: 'Tampilan gelap yang nyaman untuk mata dan hemat baterai.',
              icon: Icons.dark_mode_outlined,
              isSelected: _selectedTheme == 'Gelap',
              onTap: () => _selectTheme('Gelap'),
            ),

            const SizedBox(height: 16),
            
            _buildThemeCard(
              title: 'Sistem',
              subtitle: 'Otomatis mengikuti pengaturan tema pada perangkat Anda.',
              icon: Icons.settings_brightness_outlined,
              isSelected: _selectedTheme == 'Sistem',
              onTap: () => _selectTheme('Sistem'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primaryBlue, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.primaryBlue : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}
