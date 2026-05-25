import 'package:flutter/material.dart';
import 'package:uangku_app/core/utils/custom_popup.dart';
import 'package:uangku_app/core/theme/app_colors.dart';
import 'package:uangku_app/core/utils/responsive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uangku_app/core/services/network_service.dart';
import 'package:uangku_app/core/services/secure_storage_helper.dart';
import 'dart:convert';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:provider/provider.dart';
import 'package:uangku_app/core/providers/preferences_provider.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uangku_app/core/services/biometric_service.dart';

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
  String? _profileImagePath;
  bool _isAppLockEnabled = false;
  bool _isBiometricsSupported = false;

  @override
  void initState() {
    super.initState();
    if (!widget.isSecurity) {
      _field1Controller.text = widget.initialName;
      _field2Controller.text = widget.initialEmail;
      _loadProfileImage();
    } else {
      _load2FAStatus();
      _loadAppLockStatus();
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImagePath = prefs.getString('profile_image_path');
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
      maxWidth: 800,
    );
    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image_path', image.path);
      setState(() {
        _profileImagePath = image.path;
      });
    }
  }

  Future<void> _removePhoto() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('profile_image_path');
    if (mounted) {
      setState(() {
        _profileImagePath = null;
      });
    }
  }

  void _showPhotoOptions() {
    final isIndo = Provider.of<PreferencesProvider>(context, listen: false).language.toLowerCase() == 'id';
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.cardColor,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: context.borderColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.photo_library_outlined, color: AppColors.primaryBlue, size: 22),
                  ),
                  title: Text(
                    isIndo ? 'Pilih dari Galeri' : 'Choose from Gallery',
                    style: TextStyle(fontWeight: FontWeight.w700, color: context.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _pickImage();
                  },
                ),
                if (_profileImagePath != null) ...[
                  Divider(height: 1, indent: 20, endIndent: 20, color: context.borderColor),
                  ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE11D48).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.delete_outline_rounded, color: Color(0xFFE11D48), size: 22),
                    ),
                    title: Text(
                      isIndo ? 'Hapus Foto Profil' : 'Remove Profile Photo',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFFE11D48)),
                    ),
                    onTap: () {
                      Navigator.pop(ctx);
                      _removePhoto();
                    },
                  ),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _load2FAStatus() async {
    final token = await SecureStorageHelper.getToken();
    
    // Update user profile
    try {
      final response = await NetworkService.get(
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

  Future<void> _loadAppLockStatus() async {
    final isSupported = await BiometricService.isBiometricsAvailable();
    final isEnabled = await BiometricService.isAppLockEnabled();
    setState(() {
      _isBiometricsSupported = isSupported;
      _isAppLockEnabled = isEnabled;
    });
  }


  @override
  void dispose() {
    _field1Controller.dispose();
    _field2Controller.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final isIndo = Provider.of<PreferencesProvider>(context, listen: false).language == 'id';

    // ─── Validasi input ──────────────────────────────────────────────────────
    if (!widget.isSecurity) {
      final name = _field1Controller.text.trim();
      final email = _field2Controller.text.trim();
      if (name.isEmpty) {
        CustomPopup.show(context, isIndo ? 'Nama tidak boleh kosong' : 'Name cannot be empty', isSuccess: false);
        return;
      }
      if (email.isEmpty || !email.contains('@')) {
        CustomPopup.show(context, isIndo ? 'Email tidak valid' : 'Invalid email address', isSuccess: false);
        return;
      }
    }

    setState(() => _isLoading = true);
    final token = await SecureStorageHelper.getToken();

    final String url = widget.isSecurity
        ? 'http://145.79.10.157:8000/api/auth/security'
        : 'http://145.79.10.157:8000/api/auth/profile';

    final Map<String, dynamic> body = widget.isSecurity
        ? {
            "password": _field1Controller.text.isNotEmpty ? _field1Controller.text : null,
          }
        : {
            "full_name": _field1Controller.text.trim(),
            "email": _field2Controller.text.trim(),
          };

    body.removeWhere((key, value) => value == null);

    if (body.isEmpty && widget.isSecurity) {
      setState(() => _isLoading = false);
      Navigator.pop(context, true);
      return;
    }

    try {
      final response = await NetworkService.put(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        // Simpan ke SecureStorage dan SharedPreferences
        if (!widget.isSecurity) {
          final newName = _field1Controller.text.trim();
          final newEmail = _field2Controller.text.trim();
          await SecureStorageHelper.saveUserData(name: newName, email: newEmail);

          // Sync ke SharedPreferences untuk komponen lain yang masih pakai prefs
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', newName);
          await prefs.setString('user_email', newEmail);
        }
        if (mounted) {
          CustomPopup.show(context, isIndo ? 'Profil berhasil diperbarui' : 'Profile updated successfully', isSuccess: true);
          Navigator.pop(context, true);
        }
      } else if (response.statusCode == 401) {
        // Token expired
        if (mounted) {
          CustomPopup.show(context, isIndo ? 'Sesi habis, silakan login ulang' : 'Session expired, please login again', isSuccess: false);
        }
      } else {
        // Server error — simpan lokal tetap berjalan tapi beri tahu user
        if (!widget.isSecurity) {
          final newName = _field1Controller.text.trim();
          final newEmail = _field2Controller.text.trim();
          await SecureStorageHelper.saveUserData(name: newName, email: newEmail);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_name', newName);
          await prefs.setString('user_email', newEmail);
          if (mounted) {
            CustomPopup.show(
              context,
              isIndo
                  ? 'Disimpan lokal. Server error: ${response.statusCode}'
                  : 'Saved locally. Server error: ${response.statusCode}',
              isSuccess: false,
            );
            Navigator.pop(context, true);
          }
        } else {
          if (mounted) {
            CustomPopup.show(context, 'Error ${response.statusCode}', isSuccess: false);
          }
        }
      }
    } on Exception catch (e) {
      // Network/timeout error — simpan lokal untuk non-security
      if (!widget.isSecurity) {
        final newName = _field1Controller.text.trim();
        final newEmail = _field2Controller.text.trim();
        await SecureStorageHelper.saveUserData(name: newName, email: newEmail);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_name', newName);
        await prefs.setString('user_email', newEmail);
        if (mounted) {
          CustomPopup.show(
            context,
            isIndo
                ? 'Tidak bisa terhubung ke server. Perubahan disimpan lokal.'
                : 'Cannot connect to server. Changes saved locally.',
            isSuccess: false,
          );
          Navigator.pop(context, true);
        }
      } else {
        if (mounted) {
          CustomPopup.show(context, isIndo ? 'Terjadi kesalahan: $e' : 'Error: $e', isSuccess: false);
        }
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isIndo = Provider.of<PreferencesProvider>(context).language == 'id';
    return Scaffold(
      backgroundColor: context.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: context.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: context.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.title,
          style: TextStyle(
            color: context.textPrimary,
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
              style: TextStyle(fontSize: 14, color: context.textSecondary),
            ),
            const SizedBox(height: 32),
            if (!widget.isSecurity) ...[
              Center(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: _showPhotoOptions,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(color: context.borderColor, shape: BoxShape.circle),
                        child: CircleAvatar(
                          radius: Responsive.r(context, 50),
                          backgroundColor: context.cardColor,
                          child: _profileImagePath != null
                              ? ClipOval(
                                  child: Image.file(
                                    File(_profileImagePath!),
                                    width: Responsive.r(context, 100),
                                    height: Responsive.r(context, 100),
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Icon(Icons.person, size: Responsive.r(context, 60), color: AppColors.primaryBlue.withOpacity(0.5)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _showPhotoOptions,
                        child: Container(
                          padding: EdgeInsets.all(Responsive.r(context, 8)),
                          decoration: const BoxDecoration(color: AppColors.primaryBlue, shape: BoxShape.circle),
                          child: Icon(Icons.camera_alt, size: Responsive.r(context, 18), color: Colors.white),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: Responsive.r(context, 32)),
            ],
            _buildInputField(
              label: widget.isSecurity ? (isIndo ? 'Password Baru' : 'New Password') : (isIndo ? 'Nama Lengkap' : 'Full Name'),
              controller: _field1Controller,
              isPassword: widget.isSecurity,
            ),
            const SizedBox(height: 24),
            if (!widget.isSecurity)
              _buildInputField(
                label: isIndo ? 'Alamat Email' : 'Email Address',
                controller: _field2Controller,
                isPassword: false,
              ),
            if (widget.isSecurity) ...[
              const SizedBox(height: 16),
              const Divider(color: Color(0xFFE2E8F0), thickness: 1),
              const SizedBox(height: 16),
              Text('Two-Factor Authentication Type', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: context.textPrimary)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: context.cardColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: context.borderColor),
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
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFE2E8F0), thickness: 1),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isIndo ? 'Kunci Aplikasi (Biometrik / PIN)' : 'App Lock (Biometrics / PIN)',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          isIndo
                              ? 'Minta sidik jari atau PIN saat membuka aplikasi Uangku.'
                              : 'Require fingerprint or PIN when launching Uangku.',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textLight,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _isAppLockEnabled,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (bool newValue) async {
                      if (newValue) {
                        // Confirm biometric ownership first before enabling
                        final authenticated = await BiometricService.authenticate();
                        if (authenticated) {
                          await BiometricService.setAppLockEnabled(true);
                          setState(() {
                            _isAppLockEnabled = true;
                          });
                          CustomPopup.show(
                            context,
                            isIndo ? 'Kunci aplikasi berhasil diaktifkan!' : 'App lock enabled successfully!',
                            isSuccess: true,
                          );
                        } else {
                          CustomPopup.show(
                            context,
                            isIndo ? 'Gagal memverifikasi sidik jari.' : 'Failed to verify biometrics.',
                            isSuccess: false,
                          );
                        }
                      } else {
                        // Turn off lock
                        await BiometricService.setAppLockEnabled(false);
                        setState(() {
                          _isAppLockEnabled = false;
                        });
                        CustomPopup.show(
                          context,
                          isIndo ? 'Kunci aplikasi dinonaktifkan.' : 'App lock disabled.',
                          isSuccess: true,
                        );
                      }
                    },
                  ),
                ],
              ),
            ],
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isIndo ? 'Simpan Perubahan' : 'Save Changes',
                        style: const TextStyle(
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
    final token = await SecureStorageHelper.getToken();

    try {
      final response = await NetworkService.post(
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
          CustomPopup.show(context, '2FA settings updated successfully', isSuccess: true);
        }
      } else {
        if (mounted) {
          CustomPopup.show(context, 'Failed to update 2FA settings', isSuccess: false);
        }
      }
    } catch (e) {
      if (mounted) {
        CustomPopup.show(context, 'Error: $e', isSuccess: false);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _enable2FA(String intendedType) async {
    setState(() => _isLoading = true);
    final token = await SecureStorageHelper.getToken();

    try {
      final response = await NetworkService.post(
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
        CustomPopup.show(context, 'Failed to generate 2FA QR Code', isSuccess: false);
      }
    } catch (e) {
      CustomPopup.show(context, 'Error: $e', isSuccess: false);
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
                        hintStyle: TextStyle(color: context.textSecondary),
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
                  child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                ),
                ElevatedButton(
                  onPressed: isVerifying
                      ? null
                      : () async {
                          if (tokenController.text.length != 6) {
                            CustomPopup.show(context, 'Enter a valid 6-digit code', isSuccess: false);
                            return;
                          }
                          setStateDialog(() => isVerifying = true);
                          final token = await SecureStorageHelper.getToken();

                          try {
                            // Verify TOTP
                            final response = await NetworkService.post(
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
                              CustomPopup.show(context, 'Invalid code, try again', isSuccess: false);
                            }
                          } catch (e) {
                            CustomPopup.show(context, 'Error: $e', isSuccess: false);
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
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: context.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          obscureText: isPassword,
          decoration: InputDecoration(
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
          ),
        ),
      ],
    );
  }
}
