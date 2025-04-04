import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:pref/pref.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';
import 'controllers/theme_controller.dart';
import 'routes/app_routes.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'utils/font_settings_manager.dart';
import 'bindings/app_binding.dart';

void main() async {
  // ignore: prefer_const_constructors
  setUrlStrategy(PathUrlStrategy());
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Hive for all platforms
  await Hive.initFlutter();
  print('Initialized Hive for ${kIsWeb ? 'web' : 'mobile/desktop'}');
  
  // Initialize the pref service
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

  runApp(
    PrefService(
      service: prefService,
      child: const QuranApp(),
    ),
  );
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
          initialBinding: AppBinding(),
          getPages: AppRoutes.routes,
        ));
      }
    );
  }
}
