import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:pref/pref.dart';
import '../models/translation_edition.dart';
import '../services/quran_repository.dart';

/// Manages translation editions:
///  - bundled editions (shipped in assets, always available offline)
///  - available editions (downloadable catalog metadata)
///  - downloaded editions (fetched on demand, cached in Sembast)
/// plus the currently selected edition and its lazily-loaded verse text.
///
/// Bundled verse data: assets/data/translations/<id>.json = { "1": [..], .. }.
/// Downloaded verse data lives in the Sembast translation store, same shape.
class TranslationController extends GetxController {
  static const String editionKey = 'translation_edition';
  static const String defaultEditionId = 'eng-khattab';

  // jsdelivr-hosted fawazahmed0 editions (min = compact)
  static const String _cdnBase = 'https://cdn.jsdelivr.net/gh/fawazahmed0/quran-api@1/editions';

  // Installed (selectable) editions shipped with the app
  final RxList<TranslationEdition> editions = <TranslationEdition>[].obs;
  // Downloadable editions catalog (metadata only)
  final RxList<TranslationEdition> availableEditions = <TranslationEdition>[].obs;
  // Ids of editions the user has downloaded (persisted in Sembast)
  final RxSet<String> downloadedIds = <String>{}.obs;
  // Ids currently being downloaded (for progress UI)
  final RxSet<String> downloadingIds = <String>{}.obs;

  final RxString selectedEditionId = defaultEditionId.obs;
  final RxBool isReady = false.obs;

  // editionId -> (surahNo -> list of verse strings)
  final Map<String, Map<int, List<String>>> _verseCache = {};

  BasePrefService? _pref;
  QuranRepository? _repo;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    if (Get.isRegistered<BasePrefService>()) _pref = Get.find<BasePrefService>();
    if (Get.isRegistered<QuranRepository>()) _repo = Get.find<QuranRepository>();
    await _loadBundledCatalog();
    await _loadAvailableCatalog();
    await _loadDownloadedIds();
    _restoreSelection();
    await ensureLoaded(selectedEditionId.value);
    isReady.value = true;
  }

  Future<void> _loadBundledCatalog() async {
    try {
      final raw = await rootBundle.loadString('assets/data/translations/editions.json');
      final List<dynamic> list = json.decode(raw);
      editions.assignAll(list.map((e) => TranslationEdition.fromJson(Map<String, dynamic>.from(e))));
    } catch (e) {
      editions.assignAll(const [
        TranslationEdition(
          id: defaultEditionId,
          language: 'English',
          languageCode: 'english',
          direction: 'ltr',
          translator: 'Dr. Mustafa Khattab',
          title: 'The Clear Quran',
          description: 'Contemporary English translation.',
        ),
      ]);
      // ignore: avoid_print
      print('TranslationController: failed to load bundled catalog: $e');
    }
  }

  Future<void> _loadAvailableCatalog() async {
    try {
      final raw = await rootBundle.loadString('assets/data/translations/available_editions.json');
      final List<dynamic> list = json.decode(raw);
      availableEditions.assignAll(list.map((e) => TranslationEdition.fromJson(Map<String, dynamic>.from(e))));
    } catch (e) {
      // ignore: avoid_print
      print('TranslationController: failed to load available catalog: $e');
    }
  }

  Future<void> _loadDownloadedIds() async {
    try {
      final ids = await _repo?.getDownloadedEditionIds() ?? [];
      downloadedIds.assignAll(ids);
    } catch (e) {
      // ignore: avoid_print
      print('TranslationController: failed to load downloaded ids: $e');
    }
  }

  void _restoreSelection() {
    final saved = _pref?.get<String>(editionKey);
    if (saved != null && _isInstalled(saved)) {
      selectedEditionId.value = saved;
      return;
    }
    final legacyLang = _pref?.get<String>('translation_language');
    selectedEditionId.value = _defaultEditionForLanguage(legacyLang);
  }

  bool _isInstalled(String id) =>
      editions.any((e) => e.id == id) || downloadedIds.contains(id);

  String _defaultEditionForLanguage(String? languageCode) {
    switch (languageCode) {
      case 'bengali':
        return _firstBundledForLanguage('bengali') ?? defaultEditionId;
      case 'urdu':
        return _firstBundledForLanguage('urdu') ?? defaultEditionId;
      default:
        return defaultEditionId;
    }
  }

  String? _firstBundledForLanguage(String languageCode) =>
      editions.firstWhereOrNull((e) => e.languageCode == languageCode)?.id;

  /// Look up edition metadata across bundled + available catalogs.
  TranslationEdition? editionById(String id) =>
      editions.firstWhereOrNull((e) => e.id == id) ??
      availableEditions.firstWhereOrNull((e) => e.id == id);

  TranslationEdition get selected =>
      editionById(selectedEditionId.value) ??
      (editions.isNotEmpty
          ? editions.first
          : const TranslationEdition(
              id: defaultEditionId, language: 'English', languageCode: 'english',
              direction: 'ltr', translator: 'Dr. Mustafa Khattab', title: 'The Clear Quran', description: ''));

  bool isBundled(String id) => editions.any((e) => e.id == id);
  bool isDownloaded(String id) => downloadedIds.contains(id);
  bool isInstalled(String id) => isBundled(id) || isDownloaded(id);
  bool isDownloading(String id) => downloadingIds.contains(id);

  /// Installed editions (bundled + downloaded) for the picker, grouped by language.
  Map<String, List<TranslationEdition>> get installedByLanguage {
    final installed = <TranslationEdition>[
      ...editions,
      ...downloadedIds.map((id) => editionById(id)).whereType<TranslationEdition>(),
    ];
    final map = <String, List<TranslationEdition>>{};
    for (final e in installed) {
      map.putIfAbsent(e.language, () => []).add(e);
    }
    return map;
  }

  /// All downloadable editions grouped by language (for the manage screen).
  Map<String, List<TranslationEdition>> get availableByLanguage {
    final map = <String, List<TranslationEdition>>{};
    for (final e in availableEditions) {
      map.putIfAbsent(e.language, () => []).add(e);
    }
    return map;
  }

  Future<void> ensureLoaded(String editionId) async {
    if (_verseCache.containsKey(editionId)) return;
    // 1) bundled asset
    if (isBundled(editionId)) {
      try {
        final raw = await rootBundle.loadString('assets/data/translations/$editionId.json');
        _verseCache[editionId] = _parseVerses(json.decode(raw));
        return;
      } catch (_) {}
    }
    // 2) downloaded (Sembast)
    try {
      final stored = await _repo?.getTranslationEdition(editionId);
      if (stored != null) {
        _verseCache[editionId] = _parseVerses(stored);
        return;
      }
    } catch (_) {}
    _verseCache[editionId] = {}; // avoid repeated failed loads
  }

  Map<int, List<String>> _parseVerses(Map<String, dynamic> decoded) {
    final parsed = <int, List<String>>{};
    decoded.forEach((k, v) {
      final surahNo = int.tryParse(k);
      if (surahNo != null && v is List) {
        parsed[surahNo] = v.map((e) => e.toString()).toList();
      }
    });
    return parsed;
  }

  List<String>? versesForSurah(int surahNo) =>
      _verseCache[selectedEditionId.value]?[surahNo];

  String verseText(int surahNo, int ayahNumber) {
    final verses = versesForSurah(surahNo);
    if (verses != null && ayahNumber - 1 >= 0 && ayahNumber - 1 < verses.length) {
      return verses[ayahNumber - 1];
    }
    return '';
  }

  Future<void> setEdition(String editionId) async {
    if (!isInstalled(editionId)) return;
    await ensureLoaded(editionId);
    selectedEditionId.value = editionId;
    await _pref?.set(editionKey, editionId);
    update();
  }

  /// Download an edition from the CDN and cache it in Sembast.
  /// Returns true on success. Optionally selects it when done.
  Future<bool> downloadEdition(String editionId, {bool selectWhenDone = false}) async {
    if (isDownloaded(editionId) || isDownloading(editionId)) {
      if (selectWhenDone) await setEdition(editionId);
      return true;
    }
    downloadingIds.add(editionId);
    try {
      final resp = await http
          .get(Uri.parse('$_cdnBase/$editionId.min.json'))
          .timeout(const Duration(seconds: 60));
      if (resp.statusCode != 200) {
        throw 'HTTP ${resp.statusCode}';
      }
      final Map<String, dynamic> decoded = json.decode(utf8.decode(resp.bodyBytes));
      final List<dynamic> quran = decoded['quran'] ?? [];
      if (quran.isEmpty) throw 'empty edition';

      final bySurah = <String, List<String>>{};
      for (final item in quran) {
        final chapter = item['chapter'];
        final text = item['text'];
        if (chapter == null) continue;
        bySurah.putIfAbsent(chapter.toString(), () => []).add(text?.toString() ?? '');
      }

      await _repo?.putTranslationEdition(editionId, bySurah);
      // Cache in memory immediately
      _verseCache[editionId] =
          _parseVerses(bySurah.map((k, v) => MapEntry(k, v)));
      downloadedIds.add(editionId);

      if (selectWhenDone) await setEdition(editionId);
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('TranslationController: download failed for $editionId: $e');
      return false;
    } finally {
      downloadingIds.remove(editionId);
    }
  }

  /// Remove a downloaded edition. If it was selected, fall back to default.
  Future<void> deleteDownloaded(String editionId) async {
    if (!isDownloaded(editionId)) return;
    await _repo?.deleteTranslationEdition(editionId);
    downloadedIds.remove(editionId);
    _verseCache.remove(editionId);
    if (selectedEditionId.value == editionId) {
      await setEdition(defaultEditionId);
    }
  }
}
