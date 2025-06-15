import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';

class SettingsBottomSheet extends StatelessWidget {
  const SettingsBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
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
                  
                  // Translation Language Selection
                  Text(
                    'Translation Language',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Radio buttons for language selection
                  Obx(() => Column(
                    children: [
                      RadioListTile(
                        title: const Text('English'),
                        value: 'english',
                        groupValue: themeController.translationLanguage.value,
                        onChanged: (value) {
                          themeController.setTranslationLanguage(value.toString());
                        },
                        activeColor: colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                      RadioListTile(
                        title: const Text('Bengali'),
                        value: 'bengali',
                        groupValue: themeController.translationLanguage.value,
                        onChanged: (value) {
                          themeController.setTranslationLanguage(value.toString());
                        },
                        activeColor: colorScheme.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ],
                  )),
                  
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
                    child: Obx(() => Text(
                      'In the name of Allah, the Entirely Merciful, the Especially Merciful.',
                      style: TextStyle(
                        fontSize: themeController.englishFontSize.value,
                        color: colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    )),
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