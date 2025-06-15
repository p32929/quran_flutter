import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/theme_controller.dart';

class ThemeBottomSheet extends StatelessWidget {
  const ThemeBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeController themeController = Get.find<ThemeController>();
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.6,
      ),
      padding: const EdgeInsets.only(top: 12, left: 16, right: 16, bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
          const SizedBox(height: 12),
          
          // Title
          Text(
            'Theme Settings',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: colorScheme.onBackground,
            ),
          ),
          const SizedBox(height: 2),
          
          // Current theme status
          Obx(() {
            String currentTheme = themeController.useSystemTheme.value 
                ? 'Currently using system theme'
                : themeController.isDarkMode.value
                    ? 'Currently using dark theme'
                    : 'Currently using light theme';
            return Text(
              currentTheme,
              style: TextStyle(
                fontSize: 12,
                color: colorScheme.onBackground.withOpacity(0.7),
              ),
            );
          }),
          
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  
                  // Theme mode options
                  Text(
                    'Theme Mode',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onBackground,
                    ),
                  ),
                  const SizedBox(height: 8),
                  
                  // Theme options in a row
                  Row(
                    children: [
                      // System theme option
                      Expanded(
                        child: GetX<ThemeController>(
                          builder: (controller) => _buildCompactThemeOption(
                            context,
                            title: 'System',
                            icon: Icons.settings_suggest,
                            isSelected: controller.useSystemTheme.value,
                            onTap: () => controller.setThemeMode(true, controller.isDarkMode.value),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Light theme option
                      Expanded(
                        child: GetX<ThemeController>(
                          builder: (controller) => _buildCompactThemeOption(
                            context,
                            title: 'Light',
                            icon: Icons.light_mode,
                            isSelected: !controller.useSystemTheme.value && !controller.isDarkMode.value,
                            onTap: () => controller.setThemeMode(false, false),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      
                      // Dark theme option
                      Expanded(
                        child: GetX<ThemeController>(
                          builder: (controller) => _buildCompactThemeOption(
                            context,
                            title: 'Dark',
                            icon: Icons.dark_mode,
                            isSelected: !controller.useSystemTheme.value && controller.isDarkMode.value,
                            onTap: () => controller.setThemeMode(false, true),
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Only show dynamic colors option if available
                  GetBuilder<ThemeController>(
                    builder: (controller) {
                      if (controller.dynamicColorsAvailable) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            
                            // Dynamic colors section
                            Text(
                              'Material You Colors',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Dynamic colors toggle
                            Card(
                              margin: EdgeInsets.zero,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: colorScheme.surfaceVariant,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.palette,
                                        color: colorScheme.onSurfaceVariant,
                                        size: 16,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Use Material You Colors',
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                              color: colorScheme.onBackground,
                                            ),
                                          ),
                                          Text(
                                            'Based on your wallpaper',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: colorScheme.onBackground.withOpacity(0.7),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Obx(() => Switch(
                                      value: controller.useDynamicColor.value,
                                      onChanged: (_) => controller.toggleUseDynamicColor(),
                                      activeColor: colorScheme.primary,
                                    )),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }
                  ),
                  
                  // Only show color selection if dynamic colors are not available or disabled
                  GetBuilder<ThemeController>(
                    builder: (controller) {
                      if (!controller.dynamicColorsAvailable || !controller.useDynamicColor.value) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 16),
                            
                            // Color theme section
                            Text(
                              'Theme Color',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: colorScheme.onBackground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            
                            // Color selection in a single row
                            SizedBox(
                              height: 40,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: controller.popularColors.length,
                                separatorBuilder: (context, index) => const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final color = controller.popularColors[index];
                                  final isSelected = color.value == controller.themeColor.value.value;
                                  
                                  return InkWell(
                                    onTap: () => controller.setThemeColor(color),
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected 
                                              ? Colors.white 
                                              : Colors.transparent,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color: color.withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 1),
                                          ),
                                        ],
                                      ),
                                      child: isSelected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                              size: 20,
                                            )
                                          : null,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }
                      return const SizedBox.shrink();
                    }
                  ),
                ],
              ),
            ),
          ),
          
          // Apply button
          Padding(
            padding: const EdgeInsets.only(top: 12),
            child: SizedBox(
              width: double.infinity,
              height: 40,
              child: ElevatedButton(
                onPressed: () => Get.back(),
                style: ElevatedButton.styleFrom(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Apply',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  // Compact theme option for the row layout
  Widget _buildCompactThemeOption(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 20,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? colorScheme.primary : colorScheme.onBackground,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected 
                    ? colorScheme.primary.withOpacity(0.1)
                    : colorScheme.surfaceVariant,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onBackground,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle,
                  color: colorScheme.primary,
                ),
            ],
          ),
        ),
      ),
    );
  }
} 