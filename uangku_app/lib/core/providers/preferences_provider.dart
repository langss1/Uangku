import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  bool _isDarkMode = false;
  String _language = 'en';
  String _currency = 'IDR';

  bool get isDarkMode => _isDarkMode;
  String get language => _language;
  String get currency => _currency;

  PreferencesProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs?.getBool('isDarkMode') ?? false;
    _language = _prefs?.getString('language') ?? 'en';
    _currency = _prefs?.getString('currency') ?? 'IDR';
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    await _prefs?.setBool('isDarkMode', isDark);
    notifyListeners();
  }

  Future<void> setLanguage(String langCode) async {
    _language = langCode;
    await _prefs?.setString('language', langCode);
    notifyListeners();
  }

  Future<void> setCurrency(String currCode) async {
    _currency = currCode;
    await _prefs?.setString('currency', currCode);
    notifyListeners();
  }
}
