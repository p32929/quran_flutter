import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ayah_model.dart';
import '../controllers/theme_controller.dart';

class ShareUtils {
  static void shareAyah(Ayah ayah, int surahNumber, String surahName) async {
    final String text = generateShareText(
      ayah: ayah,
      surahNumber: surahNumber,
      surahName: surahName,
    );
    
    try {
      await Share.share(text);
    } catch (e) {
      // Fallback to clipboard if sharing fails (common on web)
      Clipboard.setData(ClipboardData(text: text));
      Get.snackbar(
        'Copied to Clipboard',
        'Sharing not supported on this device. Text copied to clipboard instead.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.green.withOpacity(0.7),
        colorText: Colors.white,
        margin: const EdgeInsets.all(8),
      );
    }
  }
  
  static void copyAyahText(Ayah ayah, bool includeTranslation) {
    String text = ayah.arabic;
    
    if (includeTranslation) {
      text += "\n\n${ayah.english}";
    }
    
    Clipboard.setData(ClipboardData(text: text));
    Get.snackbar(
      'Copied to Clipboard',
      'Text has been copied to clipboard',
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green.withOpacity(0.7),
      colorText: Colors.white,
      margin: const EdgeInsets.all(8),
    );
  }

  static String generateShareText({
    required Ayah ayah,
    required int surahNumber,
    required String surahName,
  }) {
    // Get the current translation language from theme controller
    final themeController = Get.find<ThemeController>();
    final String translationText = themeController.translationLanguage.value == 'bengali' 
        ? ayah.bengali 
        : ayah.english;

    return """
${ayah.arabic}

${translationText}

- Surah ${surahName} (${surahNumber}:${ayah.number})
""";
  }

  static Future<void> copyAyahToClipboard({
    required Ayah ayah,
    required int surahNumber,
    required String surahName,
  }) async {
    String text = ayah.arabic;
    
    // Get the current translation language
    final themeController = Get.find<ThemeController>();
    final String translationText = themeController.translationLanguage.value == 'bengali' 
        ? ayah.bengali 
        : ayah.english;
    
    // Add translation
    text += "\n\n${translationText}";
    
    // Add reference
    text += "\n\n- Surah ${surahName} (${surahNumber}:${ayah.number})";
    
    await Clipboard.setData(ClipboardData(text: text));
  }
} 