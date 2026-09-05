import 'dart:convert';
import 'package:get/get.dart';
import 'package:pref/pref.dart';
import '../services/memorization_download_service.dart';
import 'audio_controller.dart';

class MemorizeController extends GetxController {
  static const String _downloadedRecitersKey = 'memorize_downloaded_reciters';

  final MemorizationDownloadService _downloadService = MemorizationDownloadService();
  late final AudioController _audioController;
  late final BasePrefService _prefService;

  // Selected surah/reciter for the current memorization session
  final RxInt surahNumber = 0.obs;
  final RxInt totalAyah = 0.obs;
  final RxString reciterId = ''.obs;

  // Reciter ids already downloaded for the current surah (most-recent last),
  // so the reciter list can show them grouped at the top.
  final RxList<String> downloadedReciterIds = <String>[].obs;

  // Download state for the current surah + reciter
  final RxBool isCheckingDownload = false.obs;
  final RxBool isDownloaded = false.obs;
  final RxBool isDownloading = false.obs;
  final RxInt downloadedCount = 0.obs;
  final RxInt downloadTotal = 0.obs;
  bool _downloadCancelled = false;

  // Loop range + playback state
  final RxInt rangeStart = 1.obs;
  final RxInt rangeEnd = 1.obs;
  final RxBool isLooping = false.obs;

  @override
  void onInit() {
    super.onInit();
    _audioController = Get.find<AudioController>();
    _prefService = Get.find<BasePrefService>();
  }

  Map<String, List<String>> _downloadedRecitersMap() {
    final raw = _prefService.get<String>(_downloadedRecitersKey);
    if (raw == null) return {};
    try {
      final decoded = json.decode(raw) as Map;
      return decoded.map((k, v) => MapEntry(k as String, List<String>.from(v as List)));
    } catch (_) {
      return {};
    }
  }

  Future<void> _addDownloadedReciter(int surahNo, String reciterId) async {
    final map = _downloadedRecitersMap();
    final key = surahNo.toString();
    final list = map[key] ?? <String>[];
    list.remove(reciterId);
    list.add(reciterId); // most-recent last
    map[key] = list;
    await _prefService.set(_downloadedRecitersKey, json.encode(map));
    downloadedReciterIds.assignAll(list);
  }

  Future<void> _removeDownloadedReciter(int surahNo, String reciterId) async {
    final map = _downloadedRecitersMap();
    final key = surahNo.toString();
    final list = map[key] ?? <String>[];
    list.remove(reciterId);
    map[key] = list;
    await _prefService.set(_downloadedRecitersKey, json.encode(map));
    downloadedReciterIds.assignAll(list);
  }

  // Resets session state for a newly opened surah. Reciter defaults to
  // whichever one was most recently downloaded for this surah (so a
  // returning user sees it already downloaded), falling back to the first
  // reciter in the (alphabetically sorted) list if none has been downloaded.
  Future<void> startSession(int surahNo, int total) async {
    surahNumber.value = surahNo;
    totalAyah.value = total;
    rangeStart.value = 1;
    rangeEnd.value = total;

    final downloaded = _downloadedRecitersMap()[surahNo.toString()] ?? <String>[];
    downloadedReciterIds.assignAll(downloaded);
    reciterId.value = downloaded.isNotEmpty
        ? downloaded.last
        : (_audioController.reciters.isNotEmpty ? _audioController.reciters.first.id : _audioController.defaultReciterId.value);
    isDownloaded.value = false;
    await refreshDownloadStatus();
  }

  Future<void> selectReciter(String id) async {
    if (reciterId.value == id) return;
    reciterId.value = id;
    isDownloaded.value = false;
    await refreshDownloadStatus();
  }

  String? get _everyAyahDir {
    final reciter = _audioController.reciters.firstWhereOrNull((r) => r.id == reciterId.value);
    return reciter != null && reciter.everyAyahDir.isNotEmpty ? reciter.everyAyahDir : null;
  }

  Future<void> refreshDownloadStatus() async {
    if (surahNumber.value == 0 || reciterId.value.isEmpty || totalAyah.value == 0) return;
    isCheckingDownload.value = true;
    try {
      isDownloaded.value = await _downloadService.isSurahFullyDownloaded(
        surahNumber.value,
        reciterId.value,
        totalAyah.value,
      );
    } finally {
      isCheckingDownload.value = false;
    }
  }

  Future<void> downloadCurrentSurah() async {
    final dir = _everyAyahDir;
    if (dir == null || surahNumber.value == 0 || totalAyah.value == 0) return;

    _downloadCancelled = false;
    isDownloading.value = true;
    downloadedCount.value = 0;
    downloadTotal.value = totalAyah.value;

    try {
      await _downloadService.downloadSurah(
        surahNumber: surahNumber.value,
        reciterId: reciterId.value,
        everyAyahDir: dir,
        totalAyah: totalAyah.value,
        onProgress: (done, total) {
          downloadedCount.value = done;
        },
        isCancelled: () => _downloadCancelled,
      );

      if (!_downloadCancelled) {
        isDownloaded.value = true;
        await _addDownloadedReciter(surahNumber.value, reciterId.value);
      }
    } catch (e) {
      Get.snackbar('Download failed', 'Could not download the surah audio. Please try again.');
    } finally {
      isDownloading.value = false;
    }
  }

  void cancelDownload() {
    _downloadCancelled = true;
  }

  Future<void> deleteDownload() async {
    if (surahNumber.value == 0 || reciterId.value.isEmpty) return;
    await stopLoop();
    await _downloadService.deleteSurah(surahNumber.value, reciterId.value);
    isDownloaded.value = false;
    await _removeDownloadedReciter(surahNumber.value, reciterId.value);
  }

  void setRange(int start, int end) {
    if (start < 1 || end > totalAyah.value || start > end) return;
    rangeStart.value = start;
    rangeEnd.value = end;
    if (isLooping.value) {
      // Range changed mid-loop: restart the loop with the new range
      playLoop();
    }
  }

  Future<void> playLoop() async {
    if (!isDownloaded.value) return;
    final paths = <String>[];
    for (int a = rangeStart.value; a <= rangeEnd.value; a++) {
      paths.add(await _downloadService.ayahFilePath(surahNumber.value, reciterId.value, a));
    }
    if (paths.isEmpty) return;

    isLooping.value = true;
    await _audioController.playLocalRangeLooping(
      surahNumber: surahNumber.value,
      startAyah: rangeStart.value,
      localFilePaths: paths,
    );
  }

  Future<void> stopLoop() async {
    isLooping.value = false;
    await _audioController.stopMemorizationLoop();
  }

  Future<void> togglePause() async {
    if (_audioController.isPlaying.value) {
      await _audioController.pauseAudio();
    } else {
      await _audioController.resumeAudio();
    }
  }

  // Ayah previewed per reciter — ayah 2 (not 1) of the surah currently open
  // in the memorize screen, since ayah 1 is often just "Bismillah" or short
  // disjointed letters and isn't representative of the reciter's voice.
  static const int previewAyahNumber = 2;

  // Streams a sample ayah for the given reciter so the user can audition a
  // voice before committing to the full download.
  Future<void> previewSampleAyah(String previewReciterId) async {
    if (surahNumber.value == 0) return;
    final switchingReciter = _audioController.currentReciterId.value != previewReciterId;
    _audioController.currentReciterId.value = previewReciterId;
    if (switchingReciter) {
      // The preview ayah may already be "current" from a previous reciter's
      // preview — clear it so playAyah does a fresh load instead of just
      // toggling pause/resume on the old reciter's audio.
      _audioController.currentAyahNumber.value = 0;
    }
    await _audioController.playAyah(surahNumber.value, previewAyahNumber);
  }
}
