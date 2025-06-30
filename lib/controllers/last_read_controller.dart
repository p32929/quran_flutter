import 'dart:convert';
import 'package:get/get.dart';
import 'package:pref/pref.dart';
import '../models/last_read_model.dart';

class LastReadController extends GetxController {
  static const String LAST_READ_KEY = 'last_read';

  final Rx<LastRead?> lastRead = Rx<LastRead?>(null);
  late final BasePrefService _prefService;

  @override
  void onInit() {
    super.onInit();
    _prefService = Get.find<BasePrefService>();
    loadLastRead();
  }

  void loadLastRead() {
    try {
      final String? lastReadJson = _prefService.get(LAST_READ_KEY);
      if (lastReadJson != null) {
        final Map<String, dynamic> lastReadMap = json.decode(lastReadJson);
        lastRead.value = LastRead.fromJson(lastReadMap);
      }
    } catch (e) {
      // Handle error
    }
  }

  Future<void> saveLastRead(int surah, int verse) async {
    try {
      final LastRead newLastRead = LastRead(surah: surah, verse: verse);
      final String lastReadJson = json.encode(newLastRead.toJson());
      await _prefService.set(LAST_READ_KEY, lastReadJson);
      lastRead.value = newLastRead;
    } catch (e) {
      // Handle error
    }
  }

  Future<void> clearLastRead() async {
    try {
      await _prefService.remove(LAST_READ_KEY);
      lastRead.value = null;
    } catch (e) {
      // Handle error
    }
  }
}
