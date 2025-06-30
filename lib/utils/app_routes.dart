import 'package:get/get.dart';
import '../views/surah_list_screen.dart';
import '../views/surah_details_screen.dart';
import '../views/bookmarks_screen.dart';
import '../views/settings_screen.dart';
import '../models/surah_model.dart';
import '../controllers/quran_controller.dart';
import '../bindings/app_binding.dart';

/// Class to manage application routes
class AppRoutes {
  // Route names
  static const String home = '/';
  static const String surahDetails = '/surah';
  static const String bookmarks = '/bookmarks';
  static const String settings = '/settings';
  
  // Route definitions with bindings, middlewares, etc.
  static List<GetPage> routes = [
    GetPage(
      name: home,
      page: () => SurahListScreen(),
      binding: AppBinding(),
    ),
    GetPage(
      name: surahDetails,
      page: () {
        // Check for direct surah argument
        final surah = Get.arguments;
        if (surah is Surah) {
          return SurahDetailsScreen(surah: surah);
        } else {
          // Try to get from parameters (for direct URL navigation)
          final surahId = int.tryParse(Get.parameters['id'] ?? '1') ?? 1;
          
          // Get the QuranController and find the surah
          final quranController = Get.find<QuranController>();
          final foundSurah = quranController.getSurahByNumber(surahId);
          
          // If found, return it; otherwise create a placeholder
          if (foundSurah != null) {
            return SurahDetailsScreen(surah: foundSurah);
          } else {
            return SurahDetailsScreen(surah: Surah(
              number: 0,
              name: 'Loading...',
              nameArabic: '',
              nameArabicLong: '',
              nameTranslation: '',
              totalAyah: 0,
              revelationPlace: ''
            ));
          }
        }
      },
    ),
    GetPage(
      name: bookmarks,
      page: () => const BookmarksScreen(),
    ),
    GetPage(
      name: settings,
      page: () => const SettingsScreen(),
    ),
  ];
} 