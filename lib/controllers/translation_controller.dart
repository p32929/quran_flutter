import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:pref/pref.dart';
import '../models/translation_edition.dart';

/// Manages selectable translation editions: the catalog (metadata), the
/// currently selected edition, and lazy-loaded/cached verse text per edition.
///
/// Verse data lives in assets/data/translations/<id>.json as
/// { "1": ["verse1", "verse2", ...], "2": [...], ... }.
class TranslationController extends GetxController {
  static const String editionKey = 'translation_edition';
  static const String defaultEditionId = 'eng-khattab';

  final RxList<TranslationEdition> editions = <TranslationEdition>[].obs;
  final RxString selectedEditionId = defaultEditionId.obs;
  final RxBool isReady = false.obs;

  // editionId -> (surahNo -> list of verse strings)
  final Map<String, Map<int, List<String>>> _verseCache = {};

  BasePrefService? _pref;

  @override
  void onInit() {
    super.onInit();
    _init();
  }

  Future<void> _init() async {
    if (Get.isRegistered<BasePrefService>()) {
      _pref = Get.find<BasePrefService>();
    }
    await _loadCatalog();
    _restoreSelection();
    // Preload the active edition so the UI has data immediately
    await ensureLoaded(selectedEditionId.value);
    isReady.value = true;
  }

  Future<void> _loadCatalog() async {
    try {
      final raw = await rootBundle.loadString('assets/data/translations/editions.json');
      final List<dynamic> list = json.decode(raw);
      editions.assignAll(list.map((e) => TranslationEdition.fromJson(Map<String, dynamic>.from(e))));
    } catch (e) {
      // Fallback: a minimal English-only catalog so the app still runs
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
      print('TranslationController: failed to load catalog: $e');
    }
  }

  void _restoreSelection() {
    String? saved = _pref?.get<String>(editionKey);
    if (saved != null && _hasEdition(saved)) {
      selectedEditionId.value = saved;
      return;
    }
    // Migration: derive from legacy translation_language if present
    final legacyLang = _pref?.get<String>('translation_language');
    final derived = _defaultEditionForLanguage(legacyLang);
    selectedEditionId.value = derived;
  }

  bool _hasEdition(String id) => editions.any((e) => e.id == id);

  String _defaultEditionForLanguage(String? languageCode) {
    switch (languageCode) {
      case 'bengali':
        return _firstEditionForLanguage('bengali') ?? defaultEditionId;
      case 'urdu':
        return _firstEditionForLanguage('urdu') ?? defaultEditionId;
      default:
        return defaultEditionId;
    }
  }

  String? _firstEditionForLanguage(String languageCode) {
    final match = editions.firstWhereOrNull((e) => e.languageCode == languageCode);
    return match?.id;
  }

  TranslationEdition get selected =>
      editions.firstWhereOrNull((e) => e.id == selectedEditionId.value) ??
      (editions.isNotEmpty ? editions.first : const TranslationEdition(
        id: defaultEditionId, language: 'English', languageCode: 'english',
        direction: 'ltr', translator: 'Dr. Mustafa Khattab', title: 'The Clear Quran', description: '',
      ));

  /// Editions grouped by display language, preserving catalog order.
  Map<String, List<TranslationEdition>> get editionsByLanguage {
    final map = <String, List<TranslationEdition>>{};
    for (final e in editions) {
      map.putIfAbsent(e.language, () => []).add(e);
    }
    return map;
  }

  Future<void> ensureLoaded(String editionId) async {
    if (_verseCache.containsKey(editionId)) return;
    try {
      final raw = await rootBundle.loadString('assets/data/translations/$editionId.json');
      final Map<String, dynamic> decoded = json.decode(raw);
      final parsed = <int, List<String>>{};
      decoded.forEach((k, v) {
        final surahNo = int.tryParse(k);
        if (surahNo != null && v is List) {
          parsed[surahNo] = v.map((e) => e.toString()).toList();
        }
      });
      _verseCache[editionId] = parsed;
    } catch (e) {
      // ignore: avoid_print
      print('TranslationController: failed to load edition $editionId: $e');
      _verseCache[editionId] = {}; // cache empty to avoid repeated failures
    }
  }

  /// Verses for a surah in the currently selected edition, or null if not loaded yet.
  List<String>? versesForSurah(int surahNo) {
    return _verseCache[selectedEditionId.value]?[surahNo];
  }

  /// Verse text for a specific ayah (1-based) in the selected edition.
  String verseText(int surahNo, int ayahNumber) {
    final verses = versesForSurah(surahNo);
    if (verses != null && ayahNumber - 1 >= 0 && ayahNumber - 1 < verses.length) {
      return verses[ayahNumber - 1];
    }
    return '';
  }

  Future<void> setEdition(String editionId) async {
    if (!_hasEdition(editionId)) return;
    await ensureLoaded(editionId); // load before flipping so the UI has data
    selectedEditionId.value = editionId;
    await _pref?.set(editionKey, editionId);
    update();
  }
}
