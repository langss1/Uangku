import 'package:flutter/material.dart';

class CustomPopup {
  static void show(BuildContext context, String message, {required bool isSuccess}) {
    final overlayState = Overlay.of(context);
    late OverlayEntry overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => _PopupNotification(
        message: message,
        isSuccess: isSuccess,
        onDismiss: () {
          overlayEntry.remove();
        },
      ),
    );

    overlayState.insert(overlayEntry);
  }
}

class _PopupNotification extends StatefulWidget {
  final String message;
  final bool isSuccess;
  final VoidCallback onDismiss;

  const _PopupNotification({
    required this.message,
    required this.isSuccess,
    required this.onDismiss,
  });

  @override
  State<_PopupNotification> createState() => _PopupNotificationState();
}

class _PopupNotificationState extends State<_PopupNotification> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _yAnimation;
  late Animation<double> _fadeAnimation;
  bool _isDismissed = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _yAnimation = Tween<double>(begin: -120.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _controller.forward();

    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted && !_isDismissed) {
        _dismiss();
      }
    });
  }

  void _dismiss() {
    if (_isDismissed) return;
    _isDismissed = true;
    _controller.reverse().then((_) {
      widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top + 16.0;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Positioned(
          top: topPadding + _yAnimation.value,
          left: 16,
          right: 16,
          child: Opacity(
            opacity: _fadeAnimation.value,
            child: Material(
              color: Colors.transparent,
              child: GestureDetector(
                onTap: _dismiss,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: widget.isSuccess 
                        ? const Color(0xFFE8F5E9) 
                        : const Color(0xFFFFEBEE),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: widget.isSuccess 
                          ? const Color(0xFF81C784).withOpacity(0.5) 
                          : const Color(0xFFE57373).withOpacity(0.5),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: widget.isSuccess 
                              ? const Color(0xFF2E7D32).withOpacity(0.1) 
                              : const Color(0xFFC62828).withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          widget.isSuccess ? Icons.check_circle_rounded : Icons.error_rounded,
                          color: widget.isSuccess ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              widget.isSuccess ? 'Success' : 'Error',
                              style: TextStyle(
                                color: widget.isSuccess ? const Color(0xFF1B5E20) : const Color(0xFFB71C1C),
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              widget.message,
                              style: TextStyle(
                                color: widget.isSuccess 
                                    ? const Color(0xFF2E7D32).withOpacity(0.9) 
                                    : const Color(0xFFC62828).withOpacity(0.9),
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Close button
                      GestureDetector(
                        onTap: _dismiss,
                        child: Icon(
                          Icons.close_rounded,
                          color: widget.isSuccess 
                              ? const Color(0xFF2E7D32).withOpacity(0.6) 
                              : const Color(0xFFC62828).withOpacity(0.6),
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
