import 'package:get/get.dart';
import '../controllers/quran_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/bookmark_controller.dart';
import '../controllers/search_controller.dart';
import '../services/quran_hive_service.dart';
import '../services/quran_service.dart'; // Import old service for compatibility
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:hive_flutter/hive_flutter.dart';

class AppBinding extends Bindings {
  @override
  void dependencies() {
    // Create and initialize QuranHiveService
    final quranService = QuranHiveService();
    Get.put(quranService, permanent: true);
    
    // Register QuranService as an adapter to QuranHiveService for backward compatibility
    final quranCompatService = QuranService();
    Get.put(quranCompatService, permanent: true);
    
    // Controllers
    Get.put(ThemeController(), permanent: true);
    Get.put(QuranController(), permanent: true);
    Get.put(BookmarkController(), permanent: true);
    Get.put(SearchController(), permanent: true);
    
    // Start service initialization in background
    _initializeServices();
  }
  
  // Initialize services asynchronously
  void _initializeServices() async {
    try {
      final service = Get.find<QuranHiveService>();
      await service.init();
    } catch (e) {
      print('Error initializing services: $e');
    }
  }
} 