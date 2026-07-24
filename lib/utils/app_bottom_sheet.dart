import 'package:flutter/material.dart';

/// Shared launcher for all modal bottom sheets so they share a consistent,
/// responsive width. On phones the sheet is full-width; on wider screens
/// (tablet/desktop) it is capped and centered, so every sheet lines up.
///
/// The child is forced to full width within that constraint, so sheets whose
/// content would otherwise size to their content still render at the same
/// width as the rest.
Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isScrollControlled = true,
}) {
  const double maxSheetWidth = 640.0;
  final double screenWidth = MediaQuery.of(context).size.width;
  final double sheetWidth = screenWidth < maxSheetWidth ? screenWidth : maxSheetWidth;

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    backgroundColor: Colors.transparent,
    constraints: BoxConstraints(maxWidth: sheetWidth),
    builder: (ctx) => SizedBox(
      width: double.infinity,
      child: builder(ctx),
    ),
  );
}
