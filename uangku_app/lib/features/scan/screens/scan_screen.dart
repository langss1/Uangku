import 'dart:ui';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:uangku_app/core/theme/app_colors.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with TickerProviderStateMixin {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isInitialized = false;
  bool _isFlashOn = false;

  late AnimationController _scanAnimationController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _initializeCamera();

    // Scanning line animation
    _scanAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _scanAnimationController, curve: Curves.easeInOut),
    );
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras == null || _cameras!.isEmpty) {
        _showError('No cameras found');
        return;
      }

      _controller = CameraController(
        _cameras![0],
        ResolutionPreset.high,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      _showError('Camera initialization failed: $e');
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _takePhoto() async {
    if (_controller == null || !_controller!.value.isInitialized) return;

    try {
      final XFile image = await _controller!.takePicture();
      if (mounted) {
        // Subtle haptic-like effect or visual feedback
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle, color: Colors.white, size: 20),
                SizedBox(width: 12),
                Text('Scan Successful! Processing...'),
              ],
            ),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: AppColors.primaryBlue,
          ),
        );
      }
    } catch (e) {
      _showError('Error taking photo: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_controller == null) return;
    try {
      _isFlashOn = !_isFlashOn;
      await _controller!.setFlashMode(
        _isFlashOn ? FlashMode.torch : FlashMode.off,
      );
      setState(() {});
    } catch (e) {
      debugPrint('Flash error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    _scanAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Preview
          Positioned.fill(
            child: CameraPreview(_controller!),
          ),

          // 2. Viewfinder & Scanning Overlay
          _buildScannerOverlay(context),

          // 3. Premium Header (Glassmorphic)
          _buildHeader(context),

          // 4. Instructions & Controls
          _buildBottomControls(context),
        ],
      ),
    );
  }

  Widget _buildScannerOverlay(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final scanAreaWidth = size.width * 0.75;
    final scanAreaHeight = size.width * 0.95; // More of a receipt shape

    return Stack(
      children: [
        // Darkened background with a hole
        ColorFiltered(
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(0.4),
            BlendMode.srcOut,
          ),
          child: Stack(
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: Colors.black,
                  backgroundBlendMode: BlendMode.dstOut,
                ),
              ),
              Align(
                alignment: const Alignment(0, -0.1),
                child: Container(
                  width: scanAreaWidth,
                  height: scanAreaHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Corner Brackets & Scanning Line
        Align(
          alignment: const Alignment(0, -0.1),
          child: SizedBox(
            width: scanAreaWidth,
            height: scanAreaHeight,
            child: Stack(
              children: [
                // Corner Brackets
                _buildCorner(top: 0, left: 0, angle: 0),
                _buildCorner(top: 0, right: 0, angle: 90),
                _buildCorner(bottom: 0, left: 0, angle: 270),
                _buildCorner(bottom: 0, right: 0, angle: 180),

                // Animated Scan Line
                AnimatedBuilder(
                  animation: _scanAnimation,
                  builder: (context, child) {
                    return Positioned(
                      top: _scanAnimation.value * (scanAreaHeight - 4),
                      left: 10,
                      right: 10,
                      child: Container(
                        height: 3,
                        decoration: BoxDecoration(
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.6),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0),
                              AppColors.primaryBlue,
                              Colors.white.withOpacity(0),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCorner({double? top, double? bottom, double? left, double? right, required double angle}) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Transform.rotate(
        angle: angle * 3.14159 / 180,
        child: Container(
          width: 30,
          height: 30,
          decoration: const BoxDecoration(
            border: Border(
              top: BorderSide(color: Colors.white, width: 4),
              left: BorderSide(color: Colors.white, width: 4),
            ),
            borderRadius: BorderRadius.only(topLeft: Radius.circular(8)),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 10,
              bottom: 20,
              left: 20,
              right: 20,
            ),
            color: Colors.black.withOpacity(0.2),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBlurButton(
                  icon: Icons.close_rounded,
                  onPressed: () => Navigator.pop(context),
                ),
                const Column(
                  children: [
                    Text(
                      'SCAN RECEIPT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Align text clearly',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                _buildBlurButton(
                  icon: _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                  onPressed: _toggleFlash,
                  isActive: _isFlashOn,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.8),
            ],
          ),
        ),
        child: Column(
          children: [
            const Spacer(),
            // Shutter Button
            GestureDetector(
              onTap: _takePhoto,
              child: Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white.withOpacity(0.5), width: 4),
                ),
                child: Center(
                  child: Container(
                    width: 68,
                    height: 68,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.camera_alt_rounded, color: AppColors.primaryBlue, size: 30),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBlurButton({required IconData icon, required VoidCallback onPressed, bool isActive = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.white.withOpacity(0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: isActive ? AppColors.primaryBlue : Colors.white,
          size: 24,
        ),
      ),
    );
  }
}
