import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:get/get.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:pref/pref.dart';
import 'controllers/quran_controller.dart';
import 'controllers/theme_controller.dart';
import 'controllers/bookmark_controller.dart';
import 'controllers/audio_controller.dart';
import 'controllers/last_read_controller.dart';
import 'services/quran_service.dart';
import 'routes/app_routes.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'utils/font_settings_manager.dart';
// Sembast bootstrap
import 'services/quran_repository.dart';
import 'services/data_bootstrapper.dart';

void main() async {
  // ignore: prefer_const_constructors
  setUrlStrategy(PathUrlStrategy());

  WidgetsFlutterBinding.ensureInitialized();

  // For web, show loading screen during initialization
  if (kIsWeb) {
    // Start with a loading app that will handle the bootstrap
    runApp(const QuranWebApp());
  } else {
    // For mobile, do full initialization as before
    await _fullInitialization();
    runApp(
      PrefService(
        service: Get.find<BasePrefService>(),
        child: const QuranApp(),
      ),
    );
  }
}

// Full initialization for mobile platforms
Future<void> _fullInitialization() async {
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

  // STEP A: Open Sembast and import data if needed (version.txt gating)
  final repo = QuranRepository();
  // Register repo so services can find it
  Get.put<QuranRepository>(repo, permanent: true);
  final bootstrapper = DataBootstrapper(repo);
  print('Starting data bootstrap (Sembast import if needed)...');
  final result = await bootstrapper.initialize(onProgress: (done, total) {
    if (done % 10 == 0 || done == total) {
      // Throttle logs
      print('Import progress: $done/$total');
    }
  });
  print('Data bootstrap complete. Imported: ${result.imported}. AssetVersion: ${result.assetVersion}, DbVersion(before): ${result.dbVersion}');

  // Initialize remaining services and controllers
  await initServices();

  // Remove heavy global preloader — DB-first reads are instant after first import
  // preloadAllSurahs(); // disabled
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

  // Initialize last read controller
  Get.put(LastReadController());
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

// Web app wrapper that shows loading screen during initialization
class QuranWebApp extends StatefulWidget {
  const QuranWebApp({super.key});

  @override
  State<QuranWebApp> createState() => _QuranWebAppState();
}

class _QuranWebAppState extends State<QuranWebApp> {
  bool _isInitialized = false;
  BasePrefService? _prefService;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      // Initialize the pref service first
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

      Get.put<BasePrefService>(prefService);
      _prefService = prefService;

      // Initialize theme controller
      final themeController = Get.put(ThemeController());
      await themeController.initializeSettings();

      // Initialize Sembast and import data
      final repo = QuranRepository();
      Get.put<QuranRepository>(repo, permanent: true);
      final bootstrapper = DataBootstrapper(repo);

      await bootstrapper.initialize(onProgress: (done, total) {
        // Progress tracking happens in console logs only
      });

      // Initialize services
      await initServices();

      setState(() {
        _isInitialized = true;
      });

    } catch (e) {
      print('Error during initialization: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitialized && _prefService != null) {
      // Show the main app
      return PrefService(
        service: _prefService!,
        child: const QuranApp(),
      );
    }

    // Show loading screen - just circular progress indicator
    return MaterialApp(
      title: 'Quran',
      home: Scaffold(
        body: Container(
          color: const Color(0xffa1d39a), // Using the specified green color
          child: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 3.0,
            ),
          ),
        ),
      ),
    );
  }
}

class QuranApp extends StatelessWidget {
  const QuranApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Get the theme controller
    final themeController = Get.find<ThemeController>();

    // Use Obx to reactively rebuild when any observable changes
    return DynamicColorBuilder(builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
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
    });
  }
}
