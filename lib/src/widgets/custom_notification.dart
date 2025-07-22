import 'package:flutter/material.dart';

enum NotificationType {
  success,
  error,
  warning,
  info,
}

class CustomNotification {
  static OverlayEntry? _overlayEntry;

  static void show(
    BuildContext context, {
    required String message,
    NotificationType type = NotificationType.info,
    Duration duration = const Duration(seconds: 3),
    bool fromTop = true,
  }) {
    // Check if context is valid and mounted
    try {
      final overlay = Overlay.maybeOf(context);
      if (overlay == null) return;
      
      // Remove any existing notification
      hide();

      _overlayEntry = _createOverlayEntry(
        context,
        message: message,
        type: type,
        duration: duration,
        fromTop: fromTop,
      );

      overlay.insert(_overlayEntry!);

      // Auto hide after duration
      Future.delayed(duration, () {
        hide();
      });
    } catch (e) {
      // Silently handle overlay errors
      _overlayEntry = null;
    }
  }

  static void hide() {
    try {
      _overlayEntry?.remove();
    } catch (e) {
      // Silently handle removal errors
    }
    _overlayEntry = null;
  }

  static OverlayEntry _createOverlayEntry(
    BuildContext context, {
    required String message,
    required NotificationType type,
    required Duration duration,
    required bool fromTop,
  }) {
    return OverlayEntry(
      builder: (context) => _CustomNotificationWidget(
        message: message,
        type: type,
        fromTop: fromTop,
        onDismiss: hide,
      ),
    );
  }
}

class _CustomNotificationWidget extends StatefulWidget {
  final String message;
  final NotificationType type;
  final bool fromTop;
  final VoidCallback onDismiss;

  const _CustomNotificationWidget({
    required this.message,
    required this.type,
    required this.fromTop,
    required this.onDismiss,
  });

  @override
  State<_CustomNotificationWidget> createState() => _CustomNotificationWidgetState();
}

class _CustomNotificationWidgetState extends State<_CustomNotificationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    // Slide animation from top or side
    _slideAnimation = Tween<Offset>(
      begin: widget.fromTop 
          ? const Offset(0, -1) // From top
          : const Offset(1, 0),  // From right
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Color _getBackgroundColor() {
    switch (widget.type) {
      case NotificationType.success:
        return const Color(0xFF4CAF50);
      case NotificationType.error:
        return const Color(0xFFF44336);
      case NotificationType.warning:
        return const Color(0xFFFF9800);
      case NotificationType.info:
        return const Color(0xFF2196F3);
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case NotificationType.success:
        return Icons.check_circle;
      case NotificationType.error:
        return Icons.error;
      case NotificationType.warning:
        return Icons.warning;
      case NotificationType.info:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: widget.fromTop ? 50 : null,
      bottom: !widget.fromTop ? 100 : null,
      left: 16,
      right: 16,
      child: SlideTransition(
        position: _slideAnimation,
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: _getBackgroundColor(),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    _getIcon(),
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      _animationController.reverse().then((_) {
                        widget.onDismiss();
                      });
                    },
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Extension để dễ sử dụng
extension NotificationExtension on BuildContext {
  void showSuccessNotification(String message) {
    CustomNotification.show(
      this,
      message: message,
      type: NotificationType.success,
    );
  }

  void showErrorNotification(String message) {
    CustomNotification.show(
      this,
      message: message,
      type: NotificationType.error,
    );
  }

  void showWarningNotification(String message) {
    CustomNotification.show(
      this,
      message: message,
      type: NotificationType.warning,
    );
  }

  void showInfoNotification(String message) {
    CustomNotification.show(
      this,
      message: message,
      type: NotificationType.info,
    );
  }

  void showNotificationFromSide(String message, {NotificationType type = NotificationType.info}) {
    CustomNotification.show(
      this,
      message: message,
      type: type,
      fromTop: false,
    );
  }
}
