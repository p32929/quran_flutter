import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pref/pref.dart';
import '../theme/app_theme.dart';
import '../utils/font_settings_manager.dart';
import 'dart:async';

class ThemeController extends GetxController {
  static const String THEME_MODE_KEY = 'theme_mode';
  static const String IS_DARK_MODE_KEY = 'is_dark_mode';
  static const String THEME_COLOR_KEY = 'theme_color';
  static const String USE_DYNAMIC_COLOR_KEY = 'use_dynamic_color';
  
  // Theme state
  final RxBool isDarkMode = false.obs;
  final RxBool useSystemTheme = true.obs;
  final Rx<MaterialColor> themeColor = Colors.green.obs;
  final RxBool useDynamicColor = true.obs;
  
  // Dynamic color schemes from Material You (Android 12+)
  ColorScheme? _lightDynamicColorScheme;
  ColorScheme? _darkDynamicColorScheme;
  
  // Popular colors that users can choose from
  final List<MaterialColor> popularColors = [
    Colors.green,
    Colors.blue,
    Colors.red,
    Colors.purple,
    Colors.orange,
    Colors.teal,
    Colors.indigo,
    Colors.pink,
  ];
  
  // Font settings manager
  final FontSettingsManager _fontSettingsManager = FontSettingsManager();
  
  // Font sizes as rx values for reactivity
  final RxDouble arabicFontSize = 28.0.obs;
  final RxDouble englishFontSize = 16.0.obs;
  
  // Translation language
  final RxString translationLanguage = 'english'.obs;
  
  // Display options
  final RxBool showArabicText = true.obs;
  final RxBool showTranslation = true.obs;
  
  // Access to the pref service
  late final BasePrefService _prefService;
  final Completer<void> _initCompleter = Completer<void>();
  
  @override
  void onInit() {
    super.onInit();
    // Initialize controller
    _initializeAsync();
  }
  
  // Public method to wait for initialization to complete
  Future<void> initializeSettings() async {
    return _initCompleter.future;
  }
  
  Future<void> _initializeAsync() async {
    try {
      print('ThemeController: Starting initialization...');
      
      // Get the pref service
      _prefService = Get.find<BasePrefService>();
      
      // First initialize font settings manager
      await _fontSettingsManager.initialize();
      
      // Get values from font settings manager
      arabicFontSize.value = _fontSettingsManager.arabicFontSize;
      englishFontSize.value = _fontSettingsManager.englishFontSize;
      translationLanguage.value = _fontSettingsManager.translationLanguage;
      showArabicText.value = _fontSettingsManager.showArabicText;
      showTranslation.value = _fontSettingsManager.showTranslation;
      
      print('ThemeController: Font settings loaded from manager');
      print('ThemeController: Arabic font size: ${arabicFontSize.value}');
      print('ThemeController: English font size: ${englishFontSize.value}');
      print('ThemeController: Show Arabic text: ${showArabicText.value}');
      print('ThemeController: Show translation: ${showTranslation.value}');
      
      // Load theme settings from pref service
      final themeModeSetting = _prefService.get(THEME_MODE_KEY);
      useSystemTheme.value = themeModeSetting == 'system';
      isDarkMode.value = _prefService.get(IS_DARK_MODE_KEY) ?? false;
      
      // Load theme color (ensuring it's a MaterialColor)
      int savedColorValue = _prefService.get(THEME_COLOR_KEY) ?? Colors.green.value;
      try {
        // Find the closest matching material color
        MaterialColor matchedColor = Colors.primaries.firstWhere(
          (color) => color.value == savedColorValue,
          orElse: () => Colors.green,
        );
        themeColor.value = matchedColor;
      } catch (e) {
        // Fallback to default
        print('Error setting theme color: $e');
        themeColor.value = Colors.green;
      }
      
      // Load dynamic color preference
      useDynamicColor.value = _prefService.get(USE_DYNAMIC_COLOR_KEY) ?? true;
      
      // Apply theme
      _applyTheme();
      
      print('ThemeController: Initialization completed');
      
      // Complete the initialization
      if (!_initCompleter.isCompleted) {
        _initCompleter.complete();
      }
    } catch (e) {
      print('ThemeController: Error during initialization - $e');
      if (!_initCompleter.isCompleted) {
        _initCompleter.completeError(e);
      }
    }
  }
  
  void _applyTheme() {
    final ThemeMode newThemeMode = useSystemTheme.value 
      ? ThemeMode.system 
      : (isDarkMode.value ? ThemeMode.dark : ThemeMode.light);
      
    Get.changeThemeMode(newThemeMode);
    update();
  }
  
  // Set Arabic font size
  void setArabicFontSize(double size) async {
    print('ThemeController: Setting Arabic font size to $size');
    arabicFontSize.value = size;
    
    // Save using the font settings manager
    await _fontSettingsManager.setArabicFontSize(size);
    
    // Force UI update with specific ID
    update(['surah_details_view']);
  }
  
  // Set English font size
  void setEnglishFontSize(double size) async {
    print('ThemeController: Setting English font size to $size');
    englishFontSize.value = size;
    
    // Save using the font settings manager
    await _fontSettingsManager.setEnglishFontSize(size);
    
    // Force UI update with specific ID
    update(['surah_details_view']);
  }
  
  // Set translation language
  void setTranslationLanguage(String language) async {
    translationLanguage.value = language;
    
    // Save using the font settings manager
    await _fontSettingsManager.setTranslationLanguage(language);
    
    // Force UI update for the surah details screen with specific ID
    update(['surah_details_view']);
  }
  
  // Set a temporary translation language that doesn't persist
  void setTemporaryTranslationLanguage(String language) {
    // Only update the reactive value without persisting to storage
    translationLanguage.value = language;
    
    // Force UI update for the surah details screen with specific ID
    update(['surah_details_view']);
    
    print('ThemeController: Set temporary translation language to $language');
  }
  
  // Toggle show Arabic text
  void toggleShowArabicText() async {
    // Prevent both being turned off at the same time
    if (!showTranslation.value && showArabicText.value) {
      return; // Don't turn off Arabic if translation is already off
    }
    
    showArabicText.value = !showArabicText.value;
    await _fontSettingsManager.setShowArabicText(showArabicText.value);
    
    // Force UI update for the surah details screen with specific ID
    update(['surah_details_view']);
  }
  
  // Toggle show translation
  void toggleShowTranslation() async {
    // Prevent both being turned off at the same time
    if (!showArabicText.value && showTranslation.value) {
      return; // Don't turn off translation if Arabic is already off
    }
    
    showTranslation.value = !showTranslation.value;
    await _fontSettingsManager.setShowTranslation(showTranslation.value);
    
    // Force UI update for the surah details screen with specific ID
    update(['surah_details_view']);
  }
  
  // Toggle between light and dark theme
  void toggleTheme() {
    isDarkMode.value = !isDarkMode.value;
    _prefService.set(IS_DARK_MODE_KEY, isDarkMode.value);
    
    // Only apply if not using system theme
    if (!useSystemTheme.value) {
      _applyTheme();
    }
  }
  
  // Toggle system theme usage
  void toggleUseSystemTheme() {
    useSystemTheme.value = !useSystemTheme.value;
    _prefService.set(THEME_MODE_KEY, useSystemTheme.value ? 'system' : 'custom');
    _applyTheme();
  }
  
  // Toggle dynamic color usage
  void toggleUseDynamicColor() {
    useDynamicColor.value = !useDynamicColor.value;
    _prefService.set(USE_DYNAMIC_COLOR_KEY, useDynamicColor.value);
    _applyTheme();
    Get.forceAppUpdate();
  }
  
  // Set a specific theme mode
  void setThemeMode(bool useSystem, bool isDark) {
    useSystemTheme.value = useSystem;
    isDarkMode.value = isDark;
    _prefService.set(THEME_MODE_KEY, useSystem ? 'system' : 'custom');
    _prefService.set(IS_DARK_MODE_KEY, isDark);
    _applyTheme();
  }
  
  // Set theme color
  void setThemeColor(MaterialColor color) {
    themeColor.value = color;
    _prefService.set(THEME_COLOR_KEY, color.value);
    _applyTheme();
    Get.forceAppUpdate();
  }
  
  // Update dynamic color schemes from Material You
  void updateDynamicColorSchemes(ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
    _lightDynamicColorScheme = lightDynamic;
    _darkDynamicColorScheme = darkDynamic;
    update();
  }
  
  // Whether dynamic colors are available on this device
  bool get dynamicColorsAvailable => _lightDynamicColorScheme != null && _darkDynamicColorScheme != null;
  
  // Get the current theme data
  ThemeData get lightTheme {
    // Use dynamic colors if available and enabled
    if (useDynamicColor.value && _lightDynamicColorScheme != null) {
      return AppTheme.lightTheme(_lightDynamicColorScheme);
    }
    
    // Fall back to seed color theme
    return AppTheme.lightTheme(ColorScheme.fromSeed(
      seedColor: themeColor.value,
      brightness: Brightness.light,
    ));
  }
  
  ThemeData get darkTheme {
    // Use dynamic colors if available and enabled
    if (useDynamicColor.value && _darkDynamicColorScheme != null) {
      return AppTheme.darkTheme(_darkDynamicColorScheme);
    }
    
    // Fall back to seed color theme
    return AppTheme.darkTheme(ColorScheme.fromSeed(
      seedColor: themeColor.value,
      brightness: Brightness.dark,
    ));
  }
} 