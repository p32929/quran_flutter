import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/theme_controller.dart';
import 'widgets/settings_bottom_sheet.dart';
import 'widgets/about_bottom_sheet.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        centerTitle: false, // Left align the title
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Theme Settings
          _buildSectionHeader(context, 'Theme Settings'),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.dark_mode,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Toggle between light and dark theme'),
                  trailing: Obx(() => Switch(
                    value: themeController.isDarkMode.value,
                    onChanged: (_) => themeController.toggleTheme(),
                    activeColor: colorScheme.primary,
                  )),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Icon(
                    Icons.system_update,
                    color: colorScheme.primary,
                  ),
                  title: const Text('Use System Theme'),
                  subtitle: const Text('Follow system dark/light mode'),
                  trailing: Obx(() => Switch(
                    value: themeController.useSystemTheme.value,
                    onChanged: (value) => themeController.toggleUseSystemTheme(),
                    activeColor: colorScheme.primary,
                  )),
                ),
              ],
            ),
          ),
          
          // Font Size Settings
          _buildSectionHeader(context, 'Font Settings'),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Arabic Font Size'),
                      const SizedBox(height: 8),
                      Obx(() => Slider(
                        value: themeController.arabicFontSize.value,
                        min: 18,
                        max: 40,
                        divisions: 22,
                        label: themeController.arabicFontSize.value.toStringAsFixed(1),
                        onChanged: (value) => themeController.setArabicFontSize(value),
                        activeColor: colorScheme.primary,
                      )),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Obx(() => Text(
                            'بِسْمِ اللَّهِ',
                            style: TextStyle(
                              fontFamily: 'IndoPak',
                              fontSize: themeController.arabicFontSize.value,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Translation Font Size'),
                      const SizedBox(height: 8),
                      Obx(() => Slider(
                        value: themeController.englishFontSize.value,
                        min: 14,
                        max: 24,
                        divisions: 10,
                        label: themeController.englishFontSize.value.toStringAsFixed(1),
                        onChanged: (value) => themeController.setEnglishFontSize(value),
                        activeColor: colorScheme.primary,
                      )),
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Obx(() => Text(
                            'In the name of Allah',
                            style: TextStyle(
                              fontSize: themeController.englishFontSize.value,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // About Section
          _buildSectionHeader(context, 'About'),
          Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.info_outline,
                    color: colorScheme.primary,
                  ),
                  title: const Text('About this app'),
                  onTap: () => _showAboutDialog(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(BuildContext context, String title) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8, left: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: colorScheme.primary,
        ),
      ),
    );
  }
  
  void _showAboutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AboutBottomSheet(),
    );
  }
} 