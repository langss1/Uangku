import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uangku_app/core/utils/custom_popup.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/providers/preferences_provider.dart';

class ThemeSettingsScreen extends StatefulWidget {
  const ThemeSettingsScreen({super.key});

  @override
  State<ThemeSettingsScreen> createState() => _ThemeSettingsScreenState();
}

class _ThemeSettingsScreenState extends State<ThemeSettingsScreen> {
  Future<void> _selectTheme(String theme) async {
    final prefsProvider = Provider.of<PreferencesProvider>(context, listen: false);
    await prefsProvider.setThemeString(theme);

    if (mounted) {
      final isIndo = prefsProvider.language.toLowerCase() == 'id';
      String displayTheme = theme;
      if (!isIndo) {
        if (theme == 'Terang') displayTheme = 'Light';
        if (theme == 'Gelap') displayTheme = 'Dark';
        if (theme == 'Sistem') displayTheme = 'System';
      }
      CustomPopup.show(
        context,
        isIndo ? 'Tema aplikasi diubah ke $displayTheme' : 'App theme changed to $displayTheme',
        isSuccess: true,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsProvider = Provider.of<PreferencesProvider>(context);
    final selectedTheme = prefsProvider.themeString;
    final isIndo = prefsProvider.language.toLowerCase() == 'id';

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isIndo ? 'Tema Aplikasi' : 'App Theme',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isIndo
                  ? 'Sesuaikan tampilan aplikasi dengan preferensi Anda. Mode Gelap dapat membantu menghemat baterai.'
                  : 'Customize the application interface to your preference. Dark Mode can help save battery.',
              style: TextStyle(fontSize: 14, color: context.textSecondary),
            ),
            const SizedBox(height: 32),

            _buildThemeCard(
              title: isIndo ? 'Terang (Light)' : 'Light',
              subtitle: isIndo
                  ? 'Tampilan standar dengan dominasi warna putih yang bersih.'
                  : 'Standard appearance with a clean, dominant white color.',
              icon: Icons.light_mode_outlined,
              isSelected: selectedTheme == 'Terang',
              onTap: () => _selectTheme('Terang'),
            ),
            
            const SizedBox(height: 16),
            
            _buildThemeCard(
              title: isIndo ? 'Gelap (Dark)' : 'Dark',
              subtitle: isIndo
                  ? 'Tampilan gelap yang nyaman untuk mata dan hemat baterai.'
                  : 'Comfortable dark theme for your eyes and saves battery.',
              icon: Icons.dark_mode_outlined,
              isSelected: selectedTheme == 'Gelap',
              onTap: () => _selectTheme('Gelap'),
            ),

            const SizedBox(height: 16),
            
            _buildThemeCard(
              title: isIndo ? 'Sistem' : 'System',
              subtitle: isIndo
                  ? 'Otomatis mengikuti pengaturan tema pada perangkat Anda.'
                  : 'Automatically follows the theme settings of your device.',
              icon: Icons.settings_brightness_outlined,
              isSelected: selectedTheme == 'Sistem',
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
          color: context.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : context.borderColor,
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
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: context.textSecondary, height: 1.4),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
              color: isSelected ? AppColors.primaryBlue : context.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}
