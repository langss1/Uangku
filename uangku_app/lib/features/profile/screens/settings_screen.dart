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
  bool _is2FAEnabled = false;
  bool _has2FASecret = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isSecurity) {
      _field1Controller.text = widget.initialName;
      _field2Controller.text = widget.initialEmail;
    } else {
      _load2FAStatus();
    }
  }

  Future<void> _load2FAStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    // Initial local load
    setState(() {
      _is2FAEnabled = prefs.getBool('is_2fa_active') ?? false;
    });

    if (token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://145.79.10.157:8000/api/auth/2fa/status'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _is2FAEnabled = data['isActive'];
          _has2FASecret = data['hasSecret'];
        });
        await prefs.setBool('is_2fa_active', _is2FAEnabled);
      }
    } catch (e) {
      debugPrint("Error loading 2FA status: $e");
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
            if (widget.isSecurity) ...[
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE2E8F0), thickness: 1),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Two-Factor Authentication', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
                subtitle: const Text('Add an extra layer of security to your account.', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
                value: _is2FAEnabled,
                activeColor: const Color(0xFF2962FF),
                contentPadding: EdgeInsets.zero,
                onChanged: (val) {
                  if (val) {
                    if (_has2FASecret) {
                      _toggle2FA(true);
                    } else {
                      _enable2FA();
                    }
                  } else {
                    _toggle2FA(false);
                  }
                },
              ),
            ],
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

  Future<void> _enable2FA() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('http://145.79.10.157:8000/api/auth/2fa/generate'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final qrCodeData = data['qrCode'] as String;
        // The QR code is a base64 encoded image string like "data:image/png;base64,..."
        final base64String = qrCodeData.split(',').last;

        if (mounted) {
          _show2FADialog(base64String);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to generate 2FA QR Code')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _show2FADialog(String base64Image) {
    final TextEditingController tokenController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Setup 2FA', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Scan this QR code with Google Authenticator or Microsoft Authenticator.', textAlign: TextAlign.center, style: TextStyle(fontSize: 14)),
                    const SizedBox(height: 16),
                    Image.memory(base64Decode(base64Image), width: 200, height: 200),
                    const SizedBox(height: 16),
                    TextField(
                      controller: tokenController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Enter 6-digit code',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          if (tokenController.text.length != 6) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid 6-digit code')));
                            return;
                          }
                          setStateDialog(() => isVerifying = true);
                          final prefs = await SharedPreferences.getInstance();
                          final token = prefs.getString('token');

                          try {
                            final response = await http.post(
                              Uri.parse('http://145.79.10.157:8000/api/auth/2fa/verify'),
                              headers: {
                                'Authorization': 'Bearer $token',
                                'Content-Type': 'application/json',
                              },
                              body: jsonEncode({"token": tokenController.text}),
                            );

                            if (response.statusCode == 200) {
                              await prefs.setBool('is_2fa_active', true);
                              setState(() => _is2FAEnabled = true);
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('2FA enabled successfully')));
                              }
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invalid code, try again')));
                            }
                          } catch (e) {
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          } finally {
                            if (mounted) setStateDialog(() => isVerifying = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2962FF)),
                  child: isVerifying
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verify', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _toggle2FA(bool active) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('http://145.79.10.157:8000/api/auth/2fa/toggle'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"active": active}),
      );

      if (response.statusCode == 200) {
        await prefs.setBool('is_2fa_active', active);
        setState(() => _is2FAEnabled = active);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('2FA ${active ? 'enabled' : 'disabled'} successfully')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to toggle 2FA')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _disable2FA() async {
    // Deprecated in favor of _toggle2FA
    await _toggle2FA(false);
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
