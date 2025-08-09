import 'package:get/get.dart';
import '../bindings/app_binding.dart';
import '../views/surah_list_screen.dart';
import '../views/bookmarks_screen.dart';
import '../views/surah_details_screen.dart';
import '../views/settings_screen.dart';
import '../views/search_screen.dart';
import '../models/surah_model.dart';
import '../controllers/quran_controller.dart';

class AppRoutes {
  static const String home = '/';
  static const String surahDetails = '/surah/:id';
  static const String bookmarks = '/bookmarks';
  static const String settings = '/settings';
  static const String search = '/search';

  static final routes = [
    GetPage(
      name: home,
      page: () => const SurahListScreen(),
      binding: AppBinding(),
    ),
    GetPage(
      name: bookmarks,
      page: () => const BookmarksScreen(),
    ),
    GetPage(
      name: search,
      page: () => const SearchScreen(),
    ),
    GetPage(
      name: surahDetails,
      page: () {
        // For navigation from app (with arguments)
        if (Get.arguments is Surah) {
          return SurahDetailsScreen(surah: Get.arguments as Surah);
        } else {
          // Try to get from parameters (for direct URL navigation)
          final surahId = int.tryParse(Get.parameters['id'] ?? '1') ?? 1;

          // Get the QuranController and find the surah
          final quranController = Get.find<QuranController>();
          final foundSurah = quranController.getSurahByNumber(surahId);

          // If found, return it; otherwise create a placeholder
          if (foundSurah != null) {
            // Even if we found the surah info, we may still be loading its details
            return SurahDetailsScreen(surah: foundSurah);
          } else {
            return SurahDetailsScreen(surah: Surah(number: surahId, name: 'Loading...', nameArabic: '', nameArabicLong: '', nameTranslation: '', totalAyah: 0, revelationPlace: ''));
          }
        }
      },
    ),
  ];
}
