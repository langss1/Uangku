import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';

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
  String _twoFactorType = 'NONE';
  bool _hasTotpSecret = false;

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
    
    // Update user profile
    try {
      final response = await http.get(
        Uri.parse('http://145.79.10.157:8000/api/auth/profile'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _is2FAEnabled = data['user']['two_factor_enabled'] ?? data['user']['is_2fa_active'] ?? false;
          _twoFactorType = data['user']['two_factor_type'] ?? 'NONE';
          _hasTotpSecret = data['user']['has_totp_secret'] ?? false;
        });
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
          }
        : {
            "full_name": _field1Controller.text,
            "email": _field2Controller.text,
          };

    // Remove nulls
    body.removeWhere((key, value) => value == null);

    if (body.isEmpty && widget.isSecurity) {
        // If nothing to save for security, just pop
        setState(() => _isLoading = false);
        Navigator.pop(context, true);
        return;
    }

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
          Navigator.pop(context, true);
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
              const Text('Two-Factor Authentication Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _twoFactorType,
                    isExpanded: true,
                    items: const [
                      DropdownMenuItem(value: 'NONE', child: Text('None')),
                      DropdownMenuItem(value: 'TOTP', child: Text('Google Authenticator')),
                      DropdownMenuItem(value: 'EMAIL', child: Text('Email OTP')),
                    ],
                    onChanged: (String? newValue) {
                      if (newValue != null && newValue != _twoFactorType) {
                        _handle2FAChange(newValue);
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Text('Selecting Google Authenticator will require setting up the app.', style: TextStyle(fontSize: 12, color: AppColors.textLight)),
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

  Future<void> _handle2FAChange(String newType) async {
    if (newType == 'NONE' || newType == 'EMAIL') {
      // Direct update
      await _update2FAType(newType, newType != 'NONE');
    } else {
      // Needs TOTP setup
      await _enable2FA(newType);
    }
  }

  Future<void> _update2FAType(String type, bool enabled) async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    try {
      final response = await http.post(
        Uri.parse('http://145.79.10.157:8000/api/auth/2fa/update-type'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"type": type, "enabled": enabled}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _twoFactorType = type;
          _is2FAEnabled = enabled;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('2FA settings updated successfully')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update 2FA settings')));
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

  Future<void> _enable2FA(String intendedType) async {
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
        final qrCodeData = data['qrCodeUrl'] as String; // Now using otpauthUrl directly if using qr_flutter, or base64 if not.
        
        // Wait, my backend generateTOTP returns qrCodeUrl as otpauth string, not base64!
        // We will need to use qr_flutter to render it.
        
        if (mounted) {
          _show2FADialog(qrCodeData, intendedType);
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

  void _show2FADialog(String otpauthUrl, String intendedType) {
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
                    SizedBox(
                      width: 200,
                      height: 200,
                      // qr_flutter will be used here. Make sure qr_flutter is imported at top.
                      child: QrImageView(
                        data: otpauthUrl,
                        version: QrVersions.auto,
                        size: 200.0,
                      ),
                    ),
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
                            // Verify TOTP
                            final response = await http.post(
                              Uri.parse('http://145.79.10.157:8000/api/auth/2fa/verify'),
                              headers: {
                                'Authorization': 'Bearer $token',
                                'Content-Type': 'application/json',
                              },
                              body: jsonEncode({"token": tokenController.text}),
                            );

                            if (response.statusCode == 200) {
                              if (mounted) Navigator.pop(context); // Close dialog
                              // Now update the type to the intended one (e.g., BOTH) since verifyAndEnableTOTP sets it to TOTP default.
                              await _update2FAType(intendedType, true);
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
