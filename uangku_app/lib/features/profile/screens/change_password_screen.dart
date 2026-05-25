import 'package:flutter/material.dart';
import 'package:uangku_app/core/utils/custom_popup.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/services/network_service.dart';
import 'package:uangku_app/core/services/secure_storage_helper.dart';
import 'package:provider/provider.dart';
import 'package:uangku_app/core/providers/preferences_provider.dart';
import 'dart:convert';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  bool _isOldPasswordValidated = false;
  bool _isLoading = false;

  final _oldPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureOld = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  void _validateOldPassword() async {
    if (_oldPasswordController.text.isEmpty) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final email = await SecureStorageHelper.getUserEmail() ?? '';

      if (email.isEmpty) {
        if (mounted) CustomPopup.show(context, 'Email tidak ditemukan, silakan login ulang.', isSuccess: false);
        return;
      }

      final response = await NetworkService.post(
        Uri.parse('http://145.79.10.157:8000/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': _oldPasswordController.text,
        }),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          setState(() {
            _isOldPasswordValidated = true;
          });
        } else {
          CustomPopup.show(context, 'Password lama salah!', isSuccess: false);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomPopup.show(context, 'Gagal terhubung ke server', isSuccess: false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _submitNewPassword() async {
    if (_newPasswordController.text.isEmpty || _confirmPasswordController.text.isEmpty) return;
    
    if (_newPasswordController.text != _confirmPasswordController.text) {
      CustomPopup.show(context, 'Password baru dan konfirmasi tidak cocok!', isSuccess: false);
      return;
    }

    if (_newPasswordController.text.length < 6) {
      CustomPopup.show(context, 'Password baru minimal 6 karakter!', isSuccess: false);
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final token = await SecureStorageHelper.getToken() ?? '';

      final response = await NetworkService.put(
        Uri.parse('http://145.79.10.157:8000/api/auth/security'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'password': _newPasswordController.text}),
      );

      if (mounted) {
        if (response.statusCode == 200) {
          CustomPopup.show(context, 'Password berhasil diubah!', isSuccess: true);
          Navigator.pop(context);
        } else {
          final data = jsonDecode(response.body);
          CustomPopup.show(context, data['error'] ?? 'Gagal mengubah password', isSuccess: false);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomPopup.show(context, 'Gagal terhubung ke server', isSuccess: false);
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Builder(builder: (context) {
          final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
          return Text(
            isIndo ? 'Ganti Password' : 'Change Password',
            style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w800, fontSize: 18),
          );
        }),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Builder(builder: (context) {
        final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _isOldPasswordValidated 
                    ? (isIndo ? 'Masukkan password baru Anda untuk mengganti password lama.' : 'Enter your new password to change the old password.')
                    : (isIndo ? 'Untuk keamanan, mohon validasi password lama Anda terlebih dahulu.' : 'For security, please validate your old password first.'),
                style: TextStyle(fontSize: 14, color: context.textSecondary),
              ),
              const SizedBox(height: 32),

              if (!_isOldPasswordValidated) ...[
                _buildPasswordField(isIndo ? 'Password Lama' : 'Old Password', _oldPasswordController, _obscureOld, () {
                  setState(() => _obscureOld = !_obscureOld);
                }, isIndo),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _validateOldPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isIndo ? 'Validasi Password' : 'Validate Password', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ] else ...[
                _buildPasswordField(isIndo ? 'Password Baru' : 'New Password', _newPasswordController, _obscureNew, () {
                  setState(() => _obscureNew = !_obscureNew);
                }, isIndo),
                const SizedBox(height: 20),
                _buildPasswordField(isIndo ? 'Konfirmasi Password Baru' : 'Confirm New Password', _confirmPasswordController, _obscureConfirm, () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                }, isIndo),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitNewPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text(isIndo ? 'Simpan Password Baru' : 'Save New Password', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPasswordField(String label, TextEditingController controller, bool obscure, VoidCallback onToggle, bool isIndo) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: context.textPrimary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: obscure,
          decoration: InputDecoration(
            hintText: isIndo ? 'Masukkan $label' : 'Enter $label',
            hintStyle: TextStyle(color: context.textSecondary),
            filled: true,
            fillColor: context.cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off : Icons.visibility, color: const Color(0xFF94A3B8)),
              onPressed: onToggle,
            ),
          ),
        ),
      ],
    );
  }
}
