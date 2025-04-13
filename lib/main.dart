import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:pref/pref.dart';
import 'controllers/quran_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/bookmark_controller.dart';
import 'controllers/audio_controller.dart';
import 'services/quran_service.dart';
import 'routes/app_routes.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'utils/font_settings_manager.dart';

void main() async {
  // ignore: prefer_const_constructors
  setUrlStrategy(PathUrlStrategy());
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize the pref service first - this should ensure consistent storage across platforms
  final prefService = await PrefServiceShared.init(
    defaults: {
      'theme_mode': 'system',
      'is_dark_mode': false,
      'use_dynamic_color': true,
      'theme_color': Colors.green.value,
      FontSettingsManager.ARABIC_SIZE_KEY: FontSettingsManager.defaultArabicSize,
      FontSettingsManager.ENGLISH_SIZE_KEY: FontSettingsManager.defaultEnglishSize,
      FontSettingsManager.TRANSLATION_LANGUAGE_KEY: FontSettingsManager.defaultLanguage,
    },
  );
  
  // Provide the service to the app
  Get.put<BasePrefService>(prefService);
  
  // Initialize theme controller with the pref service
  final themeController = Get.put(ThemeController());
  await themeController.initializeSettings();
  print('Theme controller initialized with settings');
  
  // Initialize remaining services and controllers
  await initServices();

  // Preload all surah data
  preloadAllSurahs();

  runApp(
    PrefService(
      service: prefService,
      child: const QuranApp(),
    ),
  );
}

Future<void> initServices() async {
  // Initialize the QuranService
  await Get.putAsync(() async => QuranService());

  // Initialize QuranController (ThemeController is already initialized)
  Get.put(QuranController());

  // Initialize bookmark controller
  Get.put(BookmarkController());
  
  // Initialize audio controller
  Get.put(AudioController());
}

// Preload all surahs for better offline experience
void preloadAllSurahs() {
  // Let the UI render first before starting preloading
  Future.delayed(const Duration(milliseconds: 500), () {
    final quranService = Get.find<QuranService>();
    print('Starting to preload all 114 surahs...');

    // Load all 114 surahs in batches to avoid blocking the UI
    _loadSurahBatch(quranService, 1, 114);
  });
}

// Load surahs in batches to prevent UI freezing
void _loadSurahBatch(QuranService service, int startSurah, int endSurah, {int batchSize = 10}) {
  final int end = startSurah + batchSize - 1 <= endSurah ? startSurah + batchSize - 1 : endSurah;

  print('Preloading surahs $startSurah to $end (${service.cachedSurahCount}/${endSurah} cached)');

  // Load the current batch
  for (int i = startSurah; i <= end; i++) {
    service.getSurahDetail(i).then((_) {
      service.recordPreloadedSurah();
    });
  }

  // Schedule the next batch if needed
  if (end < endSurah) {
    Future.delayed(const Duration(milliseconds: 300), () {
      _loadSurahBatch(service, end + 1, endSurah, batchSize: batchSize);
    });
  } else {
    print('Completed preloading all surahs');
  }
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the theme controller
    final themeController = Get.find<ThemeController>();

    // Use Obx to reactively rebuild when any observable changes
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        // Pass the dynamic color schemes to the theme controller
        themeController.updateDynamicColorSchemes(lightDynamic, darkDynamic);
        
        return Obx(() => GetMaterialApp(
          title: 'Quran App',
          theme: themeController.lightTheme,
          darkTheme: themeController.darkTheme,
          themeMode: themeController.useSystemTheme.value ? ThemeMode.system : (themeController.isDarkMode.value ? ThemeMode.dark : ThemeMode.light),
          debugShowCheckedModeBanner: false,
          initialRoute: AppRoutes.home,
          getPages: AppRoutes.routes,
        ));
      }
    );
  }
}
