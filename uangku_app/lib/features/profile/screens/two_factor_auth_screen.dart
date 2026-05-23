import 'package:flutter/material.dart';
import 'package:uangku_app/core/utils/custom_popup.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';

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
          CustomPopup.show(context, 'Pengaturan 2FA berhasil disimpan!', isSuccess: true);
          Navigator.pop(context);
        } else {
          final data = jsonDecode(response.body);
          CustomPopup.show(context, data['error'] ?? 'Gagal menyimpan 2FA', isSuccess: false);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomPopup.show(context, 'Koneksi bermasalah', isSuccess: false);
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
        CustomPopup.show(context, 'Gagal membuat QR Code 2FA', isSuccess: false);
      }
    } catch (e) {
      if (mounted) {
        CustomPopup.show(context, 'Koneksi bermasalah saat setup 2FA', isSuccess: false);
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
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: const Text('Setup Google Auth', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.bold)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Scan QR code ini menggunakan aplikasi Google Authenticator.',
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
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: tokenController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        hintText: 'Masukkan 6 digit kode',
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
                  child: const Text('Batal', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          if (tokenController.text.length != 6) {
                            CustomPopup.show(context, 'Masukkan 6 digit kode yang valid', isSuccess: false);
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
                                  CustomPopup.show(context, 'Google Authenticator berhasil diaktifkan!', isSuccess: true);
                                  Navigator.pop(context); // Kembali ke pengaturan
                                }
                              } else {
                                if (mounted) {
                                  CustomPopup.show(context, 'Gagal menyimpan tipe 2FA', isSuccess: false);
                                }
                              }
                            } else {
                              if (mounted) {
                                CustomPopup.show(context, 'Kode OTP salah, coba lagi', isSuccess: false);
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              CustomPopup.show(context, 'Koneksi bermasalah', isSuccess: false);
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
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Autentikasi 2-Faktor',
          style: TextStyle(color: AppColors.textDark, fontWeight: FontWeight.w800, fontSize: 18),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambahkan lapisan keamanan ekstra pada akun Anda. Pilih metode yang paling sesuai untuk Anda.',
              style: TextStyle(fontSize: 14, color: AppColors.textLight, height: 1.5),
            ),
            const SizedBox(height: 24),

            _buildMethodCard(
              title: 'Tidak Ada (None)',
              subtitle: 'Tanpa proteksi 2FA. Tidak dianjurkan untuk keamanan akun Anda.',
              icon: Icons.no_encryption_outlined,
              iconColor: AppColors.primaryBlue,
              isRecommended: false,
              isSelected: _selectedMethod == 'None',
              onTap: () => _selectMethod('None'),
            ),
            
            const SizedBox(height: 12),

            _buildMethodCard(
              title: 'Email OTP',
              subtitle: 'Kode OTP akan dikirimkan ke email terdaftar Anda saat login.',
              icon: Icons.email_outlined,
              iconColor: AppColors.primaryBlue,
              isRecommended: true,
              isSelected: _selectedMethod == 'Email',
              onTap: () => _selectMethod('Email'),
            ),
            
            const SizedBox(height: 12),
            
            _buildMethodCard(
              title: 'Google Authenticator',
              subtitle: 'Gunakan aplikasi Google Authenticator untuk menghasilkan kode OTP.',
              icon: Icons.qr_code_scanner_rounded,
              iconColor: AppColors.primaryBlue,
              isRecommended: false,
              isSelected: _selectedMethod == 'Google Auth',
              onTap: () => _selectMethod('Google Auth'),
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
                    : const Text('Simpan Perubahan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
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
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.transparent,
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
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textDark),
                      ),
                      if (isRecommended) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Dianjurkan',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.orange),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 13, color: Color(0xFF64748B), height: 1.4),
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
