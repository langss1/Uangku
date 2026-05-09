import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/core/theme/app_colors.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _morningReport = true;
  bool _budgetAlerts = true;
  bool _aiInsights = true;
  bool _transactionSuccess = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _morningReport = prefs.getBool('pref_morning_report') ?? true;
      _budgetAlerts = prefs.getBool('pref_budget_alerts') ?? true;
      _aiInsights = prefs.getBool('pref_ai_insights') ?? true;
      _transactionSuccess = prefs.getBool('pref_transaction_success') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _updateSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    setState(() {
      if (key == 'pref_morning_report') _morningReport = value;
      if (key == 'pref_budget_alerts') _budgetAlerts = value;
      if (key == 'pref_ai_insights') _aiInsights = value;
      if (key == 'pref_transaction_success') _transactionSuccess = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Notification Settings',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Push Preferences',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 15, offset: const Offset(0, 5)),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildSwitchTile(
                          title: 'Morning Report',
                          subtitle: 'Daily financial summary at 6 AM',
                          value: _morningReport,
                          onChanged: (val) => _updateSetting('pref_morning_report', val),
                        ),
                        Divider(color: Colors.grey.shade100, height: 1, indent: 16),
                        _buildSwitchTile(
                          title: 'Budget Alerts',
                          subtitle: 'Alert when spending exceeds budget limit',
                          value: _budgetAlerts,
                          onChanged: (val) => _updateSetting('pref_budget_alerts', val),
                        ),
                        Divider(color: Colors.grey.shade100, height: 1, indent: 16),
                        _buildSwitchTile(
                          title: 'AI Insights & Chatbot',
                          subtitle: 'Tips and smart analysis from Gemini AI',
                          value: _aiInsights,
                          onChanged: (val) => _updateSetting('pref_ai_insights', val),
                        ),
                        Divider(color: Colors.grey.shade100, height: 1, indent: 16),
                        _buildSwitchTile(
                          title: 'Transaction Status',
                          subtitle: 'Confirmations for every new entry',
                          value: _transactionSuccess,
                          onChanged: (val) => _updateSetting('pref_transaction_success', val),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'Marketing',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Promotions & News', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              SizedBox(height: 2),
                              Text('Stay updated with latest features', style: TextStyle(fontSize: 12, color: Colors.grey)),
                            ],
                          ),
                        ),
                        const Switch(value: false, onChanged: null), // Feature not available
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textDark)),
                const SizedBox(height: 2),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF2962FF),
          ),
        ],
      ),
    );
  }
}
