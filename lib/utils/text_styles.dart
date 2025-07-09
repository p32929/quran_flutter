import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';

class TextStyles {
  static TextStyle arabicText(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    return TextStyle(
      fontFamily: 'IndoPak',
      fontSize: themeController.arabicFontSize.value,
      height: 1.5,
      color: Theme.of(context).colorScheme.onBackground,
    );
  }
  
  static TextStyle englishText(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    return TextStyle(
      fontSize: themeController.englishFontSize.value,
      height: 1.5,
      color: Theme.of(context).colorScheme.onBackground,
    );
  }
  
  static TextStyle surahTitle(BuildContext context) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    );
  }
  
  static TextStyle surahSubtitle(BuildContext context) {
    return TextStyle(
      fontSize: 14,
      color: Theme.of(context).colorScheme.onBackground,
    );
  }
  
  static TextStyle ayahNumber(BuildContext context) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).colorScheme.primary,
    );
  }
} 