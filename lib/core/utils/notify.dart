import 'package:flutter/material.dart';

/// Helper centralisé de notifications (SnackBar) pour CATUSNIS mobile.
/// Équivalent Flutter du notify.ts utilisé côté web (react-toastify).
class Notify {
  Notify._();

  static const Color _successColor = Color(0xFF198754);
  static const Color _errorColor = Color(0xFFDC3545);
  static const Color _infoColor = Color(0xFF0D6EFD);
  static const Color _warningColor = Color(0xFFFD7E14);

  static void success(BuildContext context, String message) {
    _show(context,
        message: message,
        backgroundColor: _successColor,
        icon: Icons.check_circle_outline);
  }

  static void error(BuildContext context, String message) {
    _show(context,
        message: message,
        backgroundColor: _errorColor,
        icon: Icons.error_outline);
  }

  static void info(BuildContext context, String message) {
    _show(context,
        message: message,
        backgroundColor: _infoColor,
        icon: Icons.info_outline);
  }

  static void warning(BuildContext context, String message) {
    _show(context,
        message: message,
        backgroundColor: _warningColor,
        icon: Icons.warning_amber_outlined);
  }

  static void apiError(BuildContext context, dynamic err, String fallback) {
    final message = _extractErrorMessage(err) ?? fallback;
    error(context, message);
  }

  static String? _extractErrorMessage(dynamic err) {
    try {
      final response = (err as dynamic).response;
      if (response != null) {
        final data = response.data;
        if (data is Map && data['message'] is String) {
          return data['message'] as String;
        }
      }
    } catch (_) {}

    if (err is Exception) {
      final msg = err.toString().replaceFirst('Exception: ', '');
      if (msg.isNotEmpty) return msg;
    }
    return null;
  }

  static void _show(
    BuildContext context, {
    required String message,
    required Color backgroundColor,
    required IconData icon,
  }) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(12),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
