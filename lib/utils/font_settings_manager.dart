import 'package:flutter/material.dart';
import 'package:pref/pref.dart';

class FontSettingsManager {
  static const String ARABIC_SIZE_KEY = 'arabic_font_size';
  static const String ENGLISH_SIZE_KEY = 'english_font_size';
  static const String TRANSLATION_LANGUAGE_KEY = 'translation_language';
  static const String SHOW_ARABIC_TEXT_KEY = 'show_arabic_text';
  static const String SHOW_TRANSLATION_KEY = 'show_translation';

  static final FontSettingsManager _instance = FontSettingsManager._internal();
  
  // Default values
  static const double defaultArabicSize = 28.0;
  static const double defaultEnglishSize = 16.0;
  static const String defaultLanguage = 'english';
  static const bool defaultShowArabicText = true;
  static const bool defaultShowTranslation = true;
  
  // Current values (with defaults)
  double arabicFontSize = defaultArabicSize;
  double englishFontSize = defaultEnglishSize;
  String translationLanguage = defaultLanguage;
  bool showArabicText = defaultShowArabicText;
  bool showTranslation = defaultShowTranslation;
  
  // Callback for when settings change
  Function? onSettingsChanged;
  
  // Pref service
  BasePrefService? _prefService;
  
  factory FontSettingsManager() {
    return _instance;
  }
  
  FontSettingsManager._internal();
  
  // Initialize and load settings
  Future<void> initialize() async {
    print('FontSettingsManager: Initializing...');
    try {
      // Initialize the service if not already done
      await _ensureServiceInitialized();
      
      // Load font sizes
      arabicFontSize = _prefService!.get(ARABIC_SIZE_KEY) ?? defaultArabicSize;
      englishFontSize = _prefService!.get(ENGLISH_SIZE_KEY) ?? defaultEnglishSize;
      translationLanguage = _prefService!.get(TRANSLATION_LANGUAGE_KEY) ?? defaultLanguage;
      showArabicText = _prefService!.get(SHOW_ARABIC_TEXT_KEY) ?? defaultShowArabicText;
      showTranslation = _prefService!.get(SHOW_TRANSLATION_KEY) ?? defaultShowTranslation;
      
      print('FontSettingsManager: Successfully loaded settings');
      print('FontSettingsManager: Arabic font size: $arabicFontSize');
      print('FontSettingsManager: English font size: $englishFontSize');
      print('FontSettingsManager: Translation language: $translationLanguage');
      print('FontSettingsManager: Show Arabic text: $showArabicText');
      print('FontSettingsManager: Show translation: $showTranslation');
    } catch (e) {
      print('FontSettingsManager: Error loading settings: $e');
      // Use defaults if there's an error
    }
  }
  
  // Make sure the service is initialized
  Future<void> _ensureServiceInitialized() async {
    if (_prefService == null) {
      _prefService = await PrefServiceShared.init(
        defaults: {
          ARABIC_SIZE_KEY: defaultArabicSize,
          ENGLISH_SIZE_KEY: defaultEnglishSize,
          TRANSLATION_LANGUAGE_KEY: defaultLanguage,
          SHOW_ARABIC_TEXT_KEY: defaultShowArabicText,
          SHOW_TRANSLATION_KEY: defaultShowTranslation,
        },
      );
      print('FontSettingsManager: Pref service initialized with defaults');
    }
  }
  
  // Set Arabic font size and save
  Future<void> setArabicFontSize(double size) async {
    print('FontSettingsManager: Setting Arabic font size to $size');
    arabicFontSize = size;
    
    await _ensureServiceInitialized();
    _prefService!.set(ARABIC_SIZE_KEY, size);
    
    print('FontSettingsManager: Arabic font size saved');
    
    // Notify listeners
    if (onSettingsChanged != null) {
      onSettingsChanged!();
    }
  }
  
  // Set English font size and save
  Future<void> setEnglishFontSize(double size) async {
    print('FontSettingsManager: Setting English font size to $size');
    englishFontSize = size;
    
    await _ensureServiceInitialized();
    _prefService!.set(ENGLISH_SIZE_KEY, size);
    
    print('FontSettingsManager: English font size saved');
    
    // Notify listeners
    if (onSettingsChanged != null) {
      onSettingsChanged!();
    }
  }
  
  // Set translation language and save
  Future<void> setTranslationLanguage(String language) async {
    print('FontSettingsManager: Setting translation language to $language');
    translationLanguage = language;
    
    await _ensureServiceInitialized();
    _prefService!.set(TRANSLATION_LANGUAGE_KEY, language);
    
    print('FontSettingsManager: Translation language saved');
    
    // Notify listeners
    if (onSettingsChanged != null) {
      onSettingsChanged!();
    }
  }
  
  // Set show Arabic text option
  Future<void> setShowArabicText(bool show) async {
    print('FontSettingsManager: Setting show Arabic text to $show');
    showArabicText = show;
    
    await _ensureServiceInitialized();
    _prefService!.set(SHOW_ARABIC_TEXT_KEY, show);
    
    print('FontSettingsManager: Show Arabic text saved');
    
    // Notify listeners
    if (onSettingsChanged != null) {
      onSettingsChanged!();
    }
  }
  
  // Set show translation option
  Future<void> setShowTranslation(bool show) async {
    print('FontSettingsManager: Setting show translation to $show');
    showTranslation = show;
    
    await _ensureServiceInitialized();
    _prefService!.set(SHOW_TRANSLATION_KEY, show);
    
    print('FontSettingsManager: Show translation saved');
    
    // Notify listeners
    if (onSettingsChanged != null) {
      onSettingsChanged!();
    }
  }
} 