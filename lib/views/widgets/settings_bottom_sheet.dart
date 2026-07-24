import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';
import '../../controllers/translation_controller.dart';
import 'translation_picker_bottom_sheet.dart';
import '../../utils/app_bottom_sheet.dart';

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  void _showTranslationPicker(BuildContext context) {
    showAppBottomSheet(
      context: context,
      builder: (_) => const TranslationPickerBottomSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final TranslationController translationController = Get.find<TranslationController>();
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle for the bottom sheet
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Title
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 24),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Display Options Header
                  Text(
                    'Display Options',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Show Arabic Text Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Show Arabic Text',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Obx(() => Switch(
                        value: themeController.showArabicText.value,
                        onChanged: (_) {
                          themeController.toggleShowArabicText();
                        },
                        activeColor: colorScheme.primary,
                      )),
                    ],
                  ),
                  
                  // Show Translation Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Show Translation',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Obx(() => Switch(
                        value: themeController.showTranslation.value,
                        onChanged: (_) {
                          themeController.toggleShowTranslation();
                        },
                        activeColor: colorScheme.primary,
                      )),
                    ],
                  ),
                  
                  const Divider(height: 32),
                  
                  // Theme Settings Header
                  Text(
                    'Theme Settings',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // System Theme Toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Use System Theme',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      Obx(() => Switch(
                        value: themeController.useSystemTheme.value,
                        onChanged: (_) => themeController.toggleUseSystemTheme(),
                        activeColor: colorScheme.primary,
                      )),
                    ],
                  ),
                  
                  // Only show dark theme toggle if not using system theme
                  Obx(() => themeController.useSystemTheme.value 
                    ? const SizedBox.shrink() 
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Dark Theme',
                            style: TextStyle(
                              fontSize: 16,
                              color: colorScheme.onSurface,
                            ),
                          ),
                          Switch(
                            value: themeController.isDarkMode.value,
                            onChanged: (_) => themeController.toggleTheme(),
                            activeColor: colorScheme.primary,
                          ),
                        ],
                      )
                  ),
                  
                  const Divider(height: 32),
                  
                  // Translation Selection
                  Text(
                    'Translation',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Tappable row showing the current translation; opens the picker
                  Obx(() {
                    // .selected reads selectedEditionId.value, so this Obx is reactive
                    final edition = translationController.selected;
                    return Material(
                      color: colorScheme.surfaceVariant.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => _showTranslationPicker(context),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Icon(Icons.translate, color: colorScheme.primary, size: 22),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${edition.language} · ${edition.translator}',
                                      style: TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                    if (edition.description.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        edition.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),

                  const Divider(height: 32),
                  
                  // Arabic Text Size
                  Text(
                    'Arabic Text Size',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Row(
                    children: [
                      Text('Small', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      Expanded(
                        child: Slider(
                          value: themeController.arabicFontSize.value,
                          min: 18,
                          max: 36,
                          divisions: 6,
                          onChanged: (value) => themeController.setArabicFontSize(value),
                          onChangeEnd: null,
                        ),
                      ),
                      Text('Large', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    ],
                  )),
                  
                  // Preview Arabic Text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Obx(() => Text(
                      'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
                      style: TextStyle(
                        fontFamily: 'IndoPak',
                        fontSize: themeController.arabicFontSize.value,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    )),
                  ),
                  const SizedBox(height: 24),
                  
                  // Translation Text Size
                  Text(
                    'Translation Text Size',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Obx(() => Row(
                    children: [
                      Text('Small', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                      Expanded(
                        child: Slider(
                          value: themeController.englishFontSize.value,
                          min: 12,
                          max: 24,
                          divisions: 6,
                          onChanged: (value) => themeController.setEnglishFontSize(value),
                          onChangeEnd: null,
                        ),
                      ),
                      Text('Large', style: TextStyle(color: colorScheme.onSurfaceVariant)),
                    ],
                  )),
                  
                  // Preview Translation Text
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Obx(() {
                      final edition = translationController.selected;
                      // Live preview from the selected edition (Al-Fatiha, ayah 1)
                      String preview = translationController.verseText(1, 1);
                      if (preview.isEmpty) {
                        preview = 'In the name of Allah, the Entirely Merciful, the Especially Merciful.';
                      }
                      return Text(
                        preview,
                        style: TextStyle(
                          fontSize: themeController.englishFontSize.value,
                          color: colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                        textDirection:
                            edition.isRtl ? TextDirection.rtl : TextDirection.ltr,
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
} 