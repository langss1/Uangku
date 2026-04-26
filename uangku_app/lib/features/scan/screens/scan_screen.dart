import 'dart:ui';
import 'dart:convert';
import 'dart:typed_data';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:intl/intl.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
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
  bool _isProcessing = false;

  final TextRecognizer _textRecognizer = TextRecognizer();

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
      
      setState(() {
        _isProcessing = true;
      });

      // 1. Try Premium Multimodal AI Analysis (Image -> Gemini)
      // This is much more accurate than local OCR
      final bytes = await image.readAsBytes();
      final aiResult = await _processImageWithGemini(bytes);
      
      double? extractedAmount;
      String? storeName;

      if (aiResult != null && aiResult['amount'] > 0) {
        extractedAmount = aiResult['amount'];
        storeName = aiResult['store'];
      } else {
        // 2. Fallback to Local OCR if Gemini fails or can't find amount
        final inputImage = InputImage.fromFilePath(image.path);
        final RecognizedText recognizedText = await _textRecognizer.processImage(inputImage);
        extractedAmount = _parseAmount(recognizedText);
        storeName = "Receipt Scan";
      }

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        if (extractedAmount != null && extractedAmount > 0) {
          final formatter = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0);
          final formattedAmount = formatter.format(extractedAmount);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                   const Icon(Icons.auto_awesome, color: Colors.amber, size: 20),
                   const SizedBox(width: 12),
                   Expanded(
                     child: Text(
                       'AI detected $formattedAmount at $storeName',
                       overflow: TextOverflow.ellipsis,
                     ),
                   ),
                ],
              ),
              backgroundColor: const Color(0xFF1E293B),
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
          
          Navigator.pop(context, {
            'amount': extractedAmount,
            'note': '$storeName - $formattedAmount (AI Scan)',
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Could not find amount. Please try again.'),
              backgroundColor: Colors.orange,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isProcessing = false);
      _showError('Error processing image: $e');
    }
  }

  double? _parseAmount(RecognizedText recognizedText) {
    double? bestCandidate;
    double highestScore = -1;

    final List<String> keywords = ["total", "grand", "jumlah", "bayar", "nett", "pembayaran", "amount", "total belanja", "tunggakan"];
    
    // 1. Collect all detected numbers with their coordinates
    List<_NumericCandidate> candidates = [];
    
    for (TextBlock block in recognizedText.blocks) {
      for (TextLine line in block.lines) {
        String lineText = line.text.toLowerCase();
        
        // Filter out dates (e.g. 20/12/2024 or 2024-12-20)
        if (lineText.contains(RegExp(r'\d{1,4}[-/]\d{1,2}[-/]\d{1,4}'))) continue;
        // Filter out times (e.g. 12:30 or 12.30)
        if (lineText.contains(RegExp(r'\d{1,2}[:.]\d{2}\s?(am|pm)?'))) {
           if (!lineText.contains('rp')) continue; // Skip if no currency prefix
        }

        // Improved Regex: Matches numbers with dots, commas, or spaces as separators
        // Example: Rp 323.000, 323,000, 323 . 000, 19.600
        final RegExp regExp = RegExp(r'(?:Rp|IDR)?\s?(\d{1,3}(?:[\s.,]\d{3})*(?:[\s.,]\d{2,3})?|\d+)');
        final matches = regExp.allMatches(line.text);

        for (var match in matches) {
          String valueStr = match.group(1) ?? '';
          
          // Intelligent Indonesian Currency Parsing
          // 1. Remove all spaces
          String cleanValue = valueStr.replaceAll(' ', '');
          
          // 2. Identify if the last separator is a decimal or thousands separator
          // In IDR, if there are exactly 3 digits after a separator, it's almost always thousands.
          // If there are exactly 2 digits, it's likely decimal (cents).
          
          if (cleanValue.contains('.') || cleanValue.contains(',')) {
            // Find the last separator type and its position
            int lastDot = cleanValue.lastIndexOf('.');
            int lastComma = cleanValue.lastIndexOf(',');
            int lastIdx = lastDot > lastComma ? lastDot : lastComma;
            String suffix = cleanValue.substring(lastIdx + 1);
            
            if (suffix.length == 3) {
              // Case: 323.000 or 323,000 -> Both are thousands
              cleanValue = cleanValue.replaceAll('.', '').replaceAll(',', '');
            } else if (suffix.length == 2) {
              // Case: 323.00 or 323,00 -> Both are decimals
              // Convert to a standard double string (dot as decimal)
              String prefix = cleanValue.substring(0, lastIdx).replaceAll('.', '').replaceAll(',', '');
              cleanValue = '$prefix.$suffix';
            } else {
              // Fallback: just strip all separators
              cleanValue = cleanValue.replaceAll('.', '').replaceAll(',', '');
            }
          }

          double? value = double.tryParse(cleanValue);

          if (value != null && value > 100) {
            candidates.add(_NumericCandidate(
              value: value,
              text: line.text,
              y: line.boundingBox.top,
              height: line.boundingBox.height,
              isCurrencyFormatted: line.text.contains('Rp') || line.text.contains('.') || line.text.contains(','),
            ));
          }
        }
      }
    }

    if (candidates.isEmpty) return null;

    // 2. Score each candidate
    for (int i = 0; i < candidates.length; i++) {
      var candidate = candidates[i];
      double score = 0;

      // FACTOR A: Vertical Position (Higher score for items at the bottom)
      // Receipts usually have the total at the end.
      score += (i / candidates.length) * 40;

      // FACTOR B: Keywords on the SAME horizontal level (Y-coordinate alignment)
      // This is the most accurate way to find a Total value
      for (TextBlock block in recognizedText.blocks) {
        for (TextLine line in block.lines) {
          String lineText = line.text.toLowerCase();
          
          // Check if this line contains a keyword
          bool hasKeyword = keywords.any((k) => lineText.contains(k));
          if (hasKeyword) {
            // Check vertical proximity (Are they on the same line?)
            double yDiff = (line.boundingBox.top - candidate.y).abs();
            if (yDiff < candidate.height * 1.5) {
              score += 120; // Massive bonus for same-line keywords
            } else if (line.boundingBox.top < candidate.y && yDiff < candidate.height * 5) {
              score += 60; // Bonus for keyword appearing slightly above the value
            }
          }
        }
      }

      // FACTOR C: Currency format indicators
      if (candidate.isCurrencyFormatted) score += 30;

      if (score > highestScore) {
        highestScore = score;
        bestCandidate = candidate.value;
      }
    }

    return bestCandidate;
  }

  Future<Map<String, dynamic>?> _processImageWithGemini(Uint8List imageBytes) async {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) return null;

      final model = GenerativeModel(model: 'gemini-1.5-flash', apiKey: apiKey);
      
      final content = [
        Content.multi([
          TextPart('''
            You are a professional financial assistant expert in reading Indonesian shopping receipts.
            Analyze this image carefully:
            1. Find the final TOTAL transaction amount (after taxes and discounts).
            2. Find the Name of the Store/Merchant.
            
            Return the result ONLY in the following JSON format:
            {"amount": 150000, "store": "Indomaret"}
            
            Notes:
            - "amount" must be a pure INTEGER without any dots, commas, or currency symbols (e.g., 323000).
            - IMPORTANT: In Indonesia, "323.000" or "323,000" means three hundred twenty-three thousand. NEVER return it as 323.
            - If you see a number like "323" that is clearly the total (e.g., net amount or grand total), it is likely "323000". Use context to decide.
            - Return ONLY the digits for "amount".
            - If you cannot find the total, return {"amount": 0, "store": "Unknown"}
            - Prioritize values next to "TOTAL", "GRAND TOTAL", "JUMLAH", "BAYAR", or "NETT".
            - Ignore dates, times, and phone numbers.
          '''),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      final response = await model.generateContent(content);
      
      String? result = response.text?.trim();
      if (result != null) {
        // Find JSON block in case Gemini adds markdown
        final jsonMatch = RegExp(r'\{.*\}', dotAll: true).firstMatch(result);
        if (jsonMatch != null) {
          final data = jsonDecode(jsonMatch.group(0)!);
          return {
            'amount': double.tryParse(data['amount'].toString()) ?? 0.0,
            'store': data['store']?.toString() ?? 'Receipt Scan',
          };
        }
      }
    } catch (e) {
      debugPrint('Gemini Image analysis error: $e');
    }
    return null;
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
    _textRecognizer.close();
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

          // 5. Loading Overlay
          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.6),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 20),
                    const Text(
                      'Analyzing Receipt...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
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

class _NumericCandidate {
  final double value;
  final String text;
  final double y;
  final double height;
  final bool isCurrencyFormatted;

  _NumericCandidate({
    required this.value,
    required this.text,
    required this.y,
    required this.height,
    required this.isCurrencyFormatted,
  });
}
