import 'package:flutter/material.dart';
import 'package:uangku_app/core/utils/custom_popup.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:uangku_app/core/providers/preferences_provider.dart';

class LanguageSettingsScreen extends StatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  State<LanguageSettingsScreen> createState() => _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState extends State<LanguageSettingsScreen> {
  String _selectedLanguage = 'ID';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedLanguage = prefs.getString('pref_app_language') ?? prefs.getString('language')?.toUpperCase() ?? 'EN';
    });
  }

  Future<void> _selectLanguage(String langCode, BuildContext context) async {
    setState(() {
      _selectedLanguage = langCode;
    });
    
    final prefsProvider = Provider.of<PreferencesProvider>(context, listen: false);
    await prefsProvider.setLanguage(langCode.toLowerCase());

    if (mounted) {
      CustomPopup.show(context, langCode == 'ID' ? 'Bahasa diubah ke Indonesia' : 'Language changed to English', isSuccess: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefsProvider = Provider.of<PreferencesProvider>(context);
    final isIndo = prefsProvider.language == 'id';

    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isIndo ? 'Bahasa' : 'Language',
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
                ? 'Pilih bahasa yang akan digunakan pada antarmuka aplikasi Uangku.'
                : 'Select the language to be used in the Uangku app interface.',
              style: TextStyle(fontSize: 14, color: context.textSecondary),
            ),
            const SizedBox(height: 32),

            _buildLanguageCard(
              title: 'Indonesia (ID)',
              subtitle: 'Bahasa Indonesia',
              icon: Icons.language_rounded,
              isSelected: _selectedLanguage == 'ID',
              onTap: () => _selectLanguage('ID', context),
            ),
            
            const SizedBox(height: 16),
            
            _buildLanguageCard(
              title: 'English (US)',
              subtitle: 'American English',
              icon: Icons.public_rounded,
              isSelected: _selectedLanguage == 'EN',
              onTap: () => _selectLanguage('EN', context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguageCard({
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
              color: isSelected ? AppColors.primaryBlue : const Color(0xFFCBD5E1),
            ),
          ],
        ),
      ),
    );
  }
}
