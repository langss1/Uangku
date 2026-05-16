import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uangku_app/core/providers/preferences_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const Center(child: Text('Settings / Notifications Placeholder')),
    );
  }
}

class AppPreferencesScreen extends StatelessWidget {
  const AppPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = Provider.of<PreferencesProvider>(context);

    return Scaffold(
      appBar: AppBar(title: const Text('App Preferences')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          SwitchListTile(
            title: const Text('Dark Mode'),
            subtitle: const Text('Toggle dark theme'),
            value: prefs.isDarkMode,
            onChanged: (val) {
              prefs.toggleTheme(val);
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Language'),
            subtitle: const Text('Select application language'),
            trailing: DropdownButton<String>(
              value: prefs.language,
              items: const [
                DropdownMenuItem(value: 'en', child: Text('English')),
                DropdownMenuItem(value: 'id', child: Text('Bahasa Indonesia')),
              ],
              onChanged: (val) {
                if (val != null) prefs.setLanguage(val);
              },
            ),
          ),
          const Divider(),
          ListTile(
            title: const Text('Currency'),
            subtitle: const Text('Select display currency'),
            trailing: DropdownButton<String>(
              value: prefs.currency,
              items: const [
                DropdownMenuItem(value: 'IDR', child: Text('IDR (Rp)')),
                DropdownMenuItem(value: 'USD', child: Text('USD (\$ )')),
                DropdownMenuItem(value: 'EUR', child: Text('EUR (€)')),
                DropdownMenuItem(value: 'JPY', child: Text('JPY (¥)')),
              ],
              onChanged: (val) {
                if (val != null) prefs.setCurrency(val);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class HelpSupportScreen extends StatelessWidget {
  const HelpSupportScreen({super.key});

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'uangku.apps@gmail.com',
      queryParameters: {
        'subject': 'Help & Support Request',
        'body': 'Hi UANGKU Team,\n\nI need help with...'
      },
    );

    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      debugPrint('Could not launch email client');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help & Support')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const ListTile(
            title: Text('Frequently Asked Questions (FAQ)', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Find answers to common questions.'),
          ),
          ExpansionTile(
            title: const Text('How to track expenses?'),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.centerLeft,
                child: const Text('Tap the + button on the home screen and fill in the details.'),
              )
            ],
          ),
          ExpansionTile(
            title: const Text('How to setup 2FA?'),
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                alignment: Alignment.centerLeft,
                child: const Text('Go to Profile > Security Settings to enable 2FA.'),
              )
            ],
          ),
          const SizedBox(height: 32),
          const ListTile(
            title: Text('Contact Support', style: TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Reach out to us if you need further assistance.'),
          ),
          Card(
            elevation: 0,
            color: Theme.of(context).colorScheme.surfaceVariant,
            child: ListTile(
              leading: const Icon(Icons.email),
              title: const Text('Email Us'),
              subtitle: const Text('uangku.apps@gmail.com'),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: _launchEmail,
            ),
          ),
        ],
      ),
    );
  }
}
