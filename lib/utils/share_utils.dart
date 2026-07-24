import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:share_plus/share_plus.dart';
import '../models/ayah_model.dart';
import '../controllers/theme_controller.dart';
import '../controllers/translation_controller.dart';
import 'snackbar_utils.dart';

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
      SnackbarUtils.show(
        'Copied to Clipboard',
        'Sharing not supported on this device. Text copied to clipboard instead.',
        backgroundColor: Colors.green.withOpacity(0.7),
      );
    }
  }
  
  static void copyAyahText(Ayah ayah, bool includeTranslation) {
    String text = ayah.arabic;
    
    if (includeTranslation) {
      text += "\n\n${ayah.english}";
    }
    
    Clipboard.setData(ClipboardData(text: text));
    SnackbarUtils.show(
      'Copied to Clipboard',
      'Text has been copied to clipboard',
      backgroundColor: Colors.green.withOpacity(0.7),
    );
  }

  // Translation text for the currently selected edition, falling back to inline data
  static String _selectedTranslation(Ayah ayah, int surahNumber) {
    if (Get.isRegistered<TranslationController>()) {
      final tc = Get.find<TranslationController>();
      final text = tc.verseText(surahNumber, ayah.number);
      if (text.isNotEmpty) return text;
      return ayah.translationFor(tc.selected.languageCode);
    }
    final themeController = Get.find<ThemeController>();
    return ayah.translationFor(themeController.translationLanguage.value);
  }

  static String generateShareText({
    required Ayah ayah,
    required int surahNumber,
    required String surahName,
  }) {
    final String translationText = _selectedTranslation(ayah, surahNumber);

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

    final String translationText = _selectedTranslation(ayah, surahNumber);

    // Add translation
    text += "\n\n${translationText}";
    
    // Add reference
    text += "\n\n- Surah ${surahName} (${surahNumber}:${ayah.number})";
    
    await Clipboard.setData(ClipboardData(text: text));
  }
} 