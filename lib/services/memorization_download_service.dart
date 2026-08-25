import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';

/// Downloads and caches per-ayah recitation audio to local storage so a
/// surah can be looped offline for memorization practice. Reuses the same
/// everyayah.com per-ayah URL scheme as the streamed playback in
/// AudioController, just persisted to disk instead of streamed.
class MemorizationDownloadService {
  Future<Directory> _surahDir(int surahNumber, String reciterId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}/memorize_audio/$reciterId/$surahNumber');
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> ayahFilePath(int surahNumber, String reciterId, int ayahNumber) async {
    final dir = await _surahDir(surahNumber, reciterId);
    return '${dir.path}/$ayahNumber.mp3';
  }

  Future<bool> isAyahDownloaded(int surahNumber, String reciterId, int ayahNumber) async {
    final path = await ayahFilePath(surahNumber, reciterId, ayahNumber);
    final file = File(path);
    if (!await file.exists()) return false;
    return (await file.length()) > 0;
  }

  Future<bool> isSurahFullyDownloaded(int surahNumber, String reciterId, int totalAyah) async {
    final results = await Future.wait([
      for (int a = 1; a <= totalAyah; a++) isAyahDownloaded(surahNumber, reciterId, a),
    ]);
    return results.every((downloaded) => downloaded);
  }

  String _everyAyahUrl(String everyAyahDir, int surahNumber, int ayahNumber) {
    final s = surahNumber.toString().padLeft(3, '0');
    final a = ayahNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$everyAyahDir/$s$a.mp3';
  }

  /// Downloads every ayah of [surahNumber] for [reciterId] that isn't
  /// already on disk, [concurrency] files at a time (one-at-a-time was the
  /// main reason a full surah took so long). Calls [onProgress] as each ayah
  /// finishes (already-downloaded ones included, order not guaranteed) and
  /// checks [isCancelled] before each download.
  Future<void> downloadSurah({
    required int surahNumber,
    required String reciterId,
    required String everyAyahDir,
    required int totalAyah,
    required void Function(int done, int total) onProgress,
    bool Function()? isCancelled,
    int concurrency = 6,
  }) async {
    int nextAyah = 1;
    int completed = 0;
    Object? firstError;

    Future<void> worker() async {
      while (true) {
        if (firstError != null || isCancelled?.call() == true) return;
        if (nextAyah > totalAyah) return;
        final a = nextAyah++;

        try {
          final path = await ayahFilePath(surahNumber, reciterId, a);
          final file = File(path);
          if (!await file.exists() || (await file.length()) == 0) {
            final response = await http.get(Uri.parse(_everyAyahUrl(everyAyahDir, surahNumber, a)));
            if (response.statusCode != 200) {
              throw Exception('Failed to download ayah $a (HTTP ${response.statusCode})');
            }
            await file.writeAsBytes(response.bodyBytes);
          }
          completed++;
          onProgress(completed, totalAyah);
        } catch (e) {
          firstError ??= e;
          return;
        }
      }
    }

    await Future.wait(List.generate(concurrency, (_) => worker()));
    if (firstError != null) throw firstError!;
  }

  Future<void> deleteSurah(int surahNumber, String reciterId) async {
    final dir = await _surahDir(surahNumber, reciterId);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }
}
