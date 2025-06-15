import 'package:get/get.dart';
import '../controllers/quran_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/bookmark_controller.dart';
import '../controllers/search_controller.dart';
import '../services/quran_service.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Services
    Get.put(QuranService(), permanent: true);
    
    // Controllers
    Get.put(ThemeController(), permanent: true);
    Get.put(QuranController(), permanent: true);
    Get.put(BookmarkController(), permanent: true);
    Get.put(SearchController(), permanent: true);
  }
} 