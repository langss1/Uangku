import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsEditorScreen extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool isSecurity;
  final String initialName;
  final String initialEmail;

  const SettingsEditorScreen({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.isSecurity,
    this.initialName = '',
    this.initialEmail = '',
  }) : super(key: key);

  @override
  State<SettingsEditorScreen> createState() => _SettingsEditorScreenState();
}

class _SettingsEditorScreenState extends State<SettingsEditorScreen> {
  final TextEditingController _field1Controller = TextEditingController();
  final TextEditingController _field2Controller = TextEditingController();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isSecurity) {
      _field1Controller.text = widget.initialName;
      _field2Controller.text = widget.initialEmail;
    }
  }

  @override
  void dispose() {
    _field1Controller.dispose();
    _field2Controller.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    final String url = widget.isSecurity 
        ? 'http://145.79.10.157:8000/api/auth/security'
        : 'http://145.79.10.157:8000/api/auth/profile';

    final Map<String, dynamic> body = widget.isSecurity
        ? {
            "password": _field1Controller.text.isNotEmpty ? _field1Controller.text : null,
            // Can add 2FA logic here later using _field2Controller or Switch
          }
        : {
            "full_name": _field1Controller.text,
            "email": _field2Controller.text,
          };

    // Remove nulls
    body.removeWhere((key, value) => value == null);

    try {
      final response = await http.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        if (!widget.isSecurity) {
          await prefs.setString('user_name', _field1Controller.text);
          await prefs.setString('user_email', _field2Controller.text);
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings updated successfully')),
          );
          Navigator.pop(context, true); // Return true to refresh parent
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update settings')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: const TextStyle(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.subtitle,
              style: const TextStyle(fontSize: 14, color: AppColors.textLight),
            ),
            const SizedBox(height: 32),
            _buildInputField(
              label: widget.isSecurity ? 'New Password' : 'Full Name',
              controller: _field1Controller,
              isPassword: widget.isSecurity,
            ),
            const SizedBox(height: 24),
            if (!widget.isSecurity)
              _buildInputField(
                label: 'Email Address',
                controller: _field2Controller,
                isPassword: false,
              ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2962FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Save Changes',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required bool isPassword,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textDark,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFF2962FF), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
