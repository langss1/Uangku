import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uangku_app/core/providers/preferences_provider.dart';

class TwoFactorAuthScreen extends StatefulWidget {
  const TwoFactorAuthScreen({super.key});

  @override
  State<TwoFactorAuthScreen> createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen> {
  String? _selectedMethod;

  @override
  void initState() {
    super.initState();
    _loadState();
  }

  Future<void> _loadState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedMethod = prefs.getString('pref_2fa_method') ?? 'None';
    });
  }

  bool _isLoading = false;

  void _selectMethod(String method) {
    setState(() {
      _selectedMethod = method;
    });
  }

  Future<void> _saveMethod() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token') ?? '';

      String type = 'NONE';
      bool enabled = false;
      if (_selectedMethod == 'Email') {
        type = 'EMAIL';
        enabled = true;
      } else if (_selectedMethod == 'Google Auth') {
        setState(() => _isLoading = false);
        _setupGoogleAuth();
        return;
      }

      final response = await http.post(
        Uri.parse('http://145.79.10.157:8000/api/auth/2fa/update-type'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({"type": type, "enabled": enabled}),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          await prefs.setString('pref_2fa_method', _selectedMethod ?? 'None');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pengaturan 2FA berhasil disimpan!')),
          );
          Navigator.pop(context);
        } else {
          final data = jsonDecode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(data['error'] ?? 'Gagal menyimpan 2FA')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koneksi bermasalah')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _setupGoogleAuth() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';

    try {
      final response = await http.post(
        Uri.parse('http://145.79.10.157:8000/api/auth/2fa/generate'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final qrCodeUrl = data['qrCodeUrl'] as String;
        
        if (mounted) {
          _show2FADialog(qrCodeUrl, token, prefs);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal membuat QR Code 2FA')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koneksi bermasalah saat setup 2FA')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _show2FADialog(String qrCodeUrl, String token, SharedPreferences prefs) {
    final TextEditingController tokenController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final isIndo = Provider.of<PreferencesProvider>(context, listen: false).language == 'id';
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Text(isIndo ? 'Setup Google Auth' : 'Google Auth Setup', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      isIndo ? 'Scan QR code ini menggunakan aplikasi Google Authenticator.' : 'Scan this QR code using Google Authenticator app.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: 200,
                      height: 200,
                      child: QrImageView(
                        data: qrCodeUrl,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: tokenController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: isIndo ? 'Masukkan 6 digit kode' : 'Enter 6 digit code',
                        filled: true,
                        fillColor: context.cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isVerifying ? null : () => Navigator.pop(context),
                  child: Text(isIndo ? 'Batal' : 'Cancel', style: const TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          if (tokenController.text.length != 6) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan 6 digit kode yang valid')));
                            return;
                          }
                          setStateDialog(() => isVerifying = true);

                          try {
                            // 1. Verifikasi TOTP
                            final verifyResponse = await http.post(
                              Uri.parse('http://145.79.10.157:8000/api/auth/2fa/verify'),
                              headers: {
                                'Authorization': 'Bearer $token',
                                'Content-Type': 'application/json',
                              },
                              body: jsonEncode({"token": tokenController.text}),
                            );

                            if (verifyResponse.statusCode == 200) {
                              // 2. Set sebagai TOTP enabled
                              final updateResponse = await http.post(
                                Uri.parse('http://145.79.10.157:8000/api/auth/2fa/update-type'),
                                headers: {
                                  'Authorization': 'Bearer $token',
                                  'Content-Type': 'application/json',
                                },
                                body: jsonEncode({"type": "TOTP", "enabled": true}),
                              );

                              if (updateResponse.statusCode == 200) {
                                await prefs.setString('pref_2fa_method', 'Google Auth');
                                if (mounted) {
                                  Navigator.pop(context); // Tutup dialog
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Google Authenticator berhasil diaktifkan!')));
                                  Navigator.pop(context); // Kembali ke pengaturan
                                }
                              } else {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menyimpan tipe 2FA')));
                                }
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kode OTP salah, coba lagi')));
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Koneksi bermasalah')));
                            }
                          } finally {
                            if (mounted) setStateDialog(() => isVerifying = false);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: isVerifying
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Verifikasi', style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          isIndo ? 'Autentikasi 2-Faktor' : '2-Factor Authentication',
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isIndo ? 'Tambahkan lapisan keamanan ekstra pada akun Anda. Pilih metode yang paling sesuai untuk Anda.' : 'Add an extra layer of security to your account. Choose the method that suits you best.',
              style: TextStyle(fontSize: 14, color: context.textSecondary, height: 1.5),
            ),
            const SizedBox(height: 24),

            _buildMethodCard(
              title: isIndo ? 'Tidak Ada (None)' : 'None',
              subtitle: isIndo ? 'Tanpa proteksi 2FA. Tidak dianjurkan untuk keamanan akun Anda.' : 'No 2FA protection. Not recommended for your account security.',
              icon: Icons.no_encryption_outlined,
              iconColor: AppColors.primaryBlue,
              isRecommended: false,
              isSelected: _selectedMethod == 'None',
              onTap: () => _selectMethod('None'),
              isIndo: isIndo,
            ),
            
            const SizedBox(height: 12),

            _buildMethodCard(
              title: 'Email OTP',
              subtitle: isIndo ? 'Kode OTP akan dikirimkan ke email terdaftar Anda saat login.' : 'OTP code will be sent to your registered email when logging in.',
              icon: Icons.email_outlined,
              iconColor: AppColors.primaryBlue,
              isRecommended: true,
              isSelected: _selectedMethod == 'Email',
              onTap: () => _selectMethod('Email'),
              isIndo: isIndo,
            ),
            
            const SizedBox(height: 12),
            
            _buildMethodCard(
              title: 'Google Authenticator',
              subtitle: isIndo ? 'Gunakan aplikasi Google Authenticator untuk menghasilkan kode OTP.' : 'Use Google Authenticator app to generate OTP codes.',
              icon: Icons.qr_code_scanner_rounded,
              iconColor: AppColors.primaryBlue,
              isRecommended: false,
              isSelected: _selectedMethod == 'Google Auth',
              onTap: () => _selectMethod('Google Auth'),
              isIndo: isIndo,
            ),

            const SizedBox(height: 32),
            
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveMethod,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(isIndo ? 'Simpan Perubahan' : 'Save Changes', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMethodCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool isRecommended,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isIndo,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
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
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        title,
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: context.textPrimary),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isIndo ? 'Dianjurkan' : 'Recommended',
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ),
                      ],
                    ],
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
