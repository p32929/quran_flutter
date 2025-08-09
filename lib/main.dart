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
  String _status = 'Initializing...';
  double _progress = 0.0;
  int _currentStep = 0;
  int _totalSteps = 114;
  bool _isInitialized = false;
  BasePrefService? _prefService;

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      setState(() {
        _status = 'Preparing preferences...';
        _progress = 0.1;
      });

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

      setState(() {
        _status = 'Setting up theme...';
        _progress = 0.2;
      });

      // Initialize theme controller
      final themeController = Get.put(ThemeController());
      await themeController.initializeSettings();

      setState(() {
        _status = 'Loading Quran data...';
        _progress = 0.3;
      });

      // Initialize Sembast and import data with progress tracking
      final repo = QuranRepository();
      Get.put<QuranRepository>(repo, permanent: true);
      final bootstrapper = DataBootstrapper(repo);

      final result = await bootstrapper.initialize(onProgress: (done, total) {
        setState(() {
          _currentStep = done;
          _totalSteps = total;
          _status = 'Loading Surahs ($done/$total)...';
          _progress = 0.3 + (done / total * 0.6); // 30% to 90%
        });
      });

      setState(() {
        _status = 'Finalizing...';
        _progress = 0.95;
      });

      // Initialize services
      await initServices();

      setState(() {
        _status = 'Ready!';
        _progress = 1.0;
      });

      // Small delay to show completion, then switch to main app
      await Future.delayed(const Duration(milliseconds: 500));

      setState(() {
        _isInitialized = true;
      });

    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
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

    // Show loading screen
    return MaterialApp(
      title: 'Quran',
      home: Scaffold(
        body: Container(
          color: const Color(0xffa1d39a), // Using the specified green color
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.book,
                    size: 80,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    'القرآن الكريم',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Holy Quran',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                  const SizedBox(height: 48),
                  
                  // Progress bar
                  Container(
                    width: double.infinity,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: _progress,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Status text
                  Text(
                    _status,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  
                  if (_currentStep > 0 && _totalSteps > 0)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        '${(_progress * 100).round()}%',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                ],
              ),
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
