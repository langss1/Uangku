import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PreferencesProvider extends ChangeNotifier {
  SharedPreferences? _prefs;

  bool _isDarkMode = false;
  String _themeString = 'Sistem';
  String _language = 'en';
  String _currency = 'IDR';

  bool get isDarkMode => _isDarkMode;
  String get themeString => _themeString;
  String get language => _language;
  String get currency => _currency;

  ThemeMode get themeMode {
    if (_themeString == 'Gelap') {
      return ThemeMode.dark;
    } else if (_themeString == 'Terang') {
      return ThemeMode.light;
    } else {
      return ThemeMode.system;
    }
  }

  PreferencesProvider() {
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _themeString = _prefs?.getString('pref_app_theme') ?? 'Sistem';
    _isDarkMode = _prefs?.getBool('isDarkMode') ?? (_themeString == 'Gelap');
    _language = _prefs?.getString('language') ?? 'en';
    _currency = _prefs?.getString('currency') ?? 'IDR';
    notifyListeners();
  }

  Future<void> toggleTheme(bool isDark) async {
    _isDarkMode = isDark;
    _themeString = isDark ? 'Gelap' : 'Terang';
    await _prefs?.setBool('isDarkMode', isDark);
    await _prefs?.setString('pref_app_theme', _themeString);
    notifyListeners();
  }

  Future<void> setThemeString(String theme) async {
    _themeString = theme;
    _isDarkMode = (theme == 'Gelap');
    await _prefs?.setString('pref_app_theme', theme);
    await _prefs?.setBool('isDarkMode', _isDarkMode);
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
