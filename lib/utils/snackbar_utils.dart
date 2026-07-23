import 'package:flutter/material.dart';

/// Global key attached to GetMaterialApp's scaffoldMessengerKey so snackbars
/// can be shown from controllers/utils without relying on GetX's overlay
/// (Get.snackbar throws "No Overlay widget found" on recent Flutter versions).
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

class SnackbarUtils {
  static void show(
    String title,
    String message, {
    Color? backgroundColor,
  }) {
    final messenger = rootScaffoldMessengerKey.currentState;
    if (messenger == null) {
      // App not mounted yet; nothing sensible to show the snackbar on.
      debugPrint('Snackbar skipped (no messenger): $title - $message');
      return;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(message),
          ],
        ),
        backgroundColor: backgroundColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(8),
      ),
    );
  }
}
