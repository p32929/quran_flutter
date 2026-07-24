import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:path_provider/path_provider.dart';
import 'package:sembast/sembast.dart';
import 'package:sembast/sembast_io.dart' as sembast_io;
import 'package:sembast_web/sembast_web.dart' as sembast_web;

class QuranRepository {
  static const String _dbName = 'quran_db.sembast';
  static const String _storeMeta = 'meta';
  static const String _storeSurahIndex = 'surah_index';
  static const String _storeSurahDetail = 'surah_detail';
  static const String _storeTranslations = 'translation_editions';

  late Database _db;

  final StoreRef<String, dynamic> _metaStore = StoreRef<String, dynamic>(_storeMeta);
  final StoreRef<int, Map<String, dynamic>> _surahIndexStore = intMapStoreFactory.store(_storeSurahIndex);
  final StoreRef<int, Map<String, dynamic>> _surahDetailStore = intMapStoreFactory.store(_storeSurahDetail);
  // Downloaded translation editions: key = editionId, value = { "1": [verses], ... }
  final StoreRef<String, Map<String, dynamic>> _translationStore =
      stringMapStoreFactory.store(_storeTranslations);

  Database get db => _db;

  Future<void> open() async {
    DatabaseFactory dbFactory;
    String dbPath;

    if (kIsWeb) {
      dbFactory = sembast_web.databaseFactoryWeb;
      dbPath = _dbName;
    } else {
      final dir = await getApplicationDocumentsDirectory();
      dbPath = '${dir.path}/$_dbName';
      dbFactory = sembast_io.databaseFactoryIo;
    }

    _db = await dbFactory.openDatabase(dbPath);
  }

  Future<void> close() async {
    await _db.close();
  }

  // Meta
  Future<int?> getDataVersion() async {
    final rec = await _metaStore.record('data_version').get(_db);
    if (rec == null) return null;
    if (rec is int) return rec;
    if (rec is String) return int.tryParse(rec);
    return null;
  }

  Future<void> setDataVersion(int version) async {
    await _metaStore.record('data_version').put(_db, version);
  }

  Future<bool> getImportComplete() async {
    final v = await _metaStore.record('import_complete').get(_db);
    return v == true;
  }

  Future<void> setImportComplete(bool done) async {
    await _metaStore.record('import_complete').put(_db, done);
  }

  Future<void> setLastImportTs(int epochMs) async {
    await _metaStore.record('last_import_ts').put(_db, epochMs);
  }

  // Index
  Future<void> putSurahIndexBatch(List<Map<String, dynamic>> items) async {
    await _db.transaction((txn) async {
      for (final m in items) {
        final key = (m['number'] ?? m['surahNo'] ?? 0) as int;
        await _surahIndexStore.record(key).put(txn, m);
      }
    });
  }

  Future<List<Map<String, dynamic>>> getAllSurahIndex() async {
    final records = await _surahIndexStore.find(_db,
        finder: Finder(sortOrders: [
          SortOrder(Field.key, true)
        ]));
    return records.map((r) => r.value).toList();
  }

  // Details
  Future<void> putSurahDetail(int number, Map<String, dynamic> json) async {
    await _surahDetailStore.record(number).put(_db, json);
  }

  Future<Map<String, dynamic>?> getSurahDetail(int number) async {
    return await _surahDetailStore.record(number).get(_db);
  }

  // Downloaded translation editions
  Future<void> putTranslationEdition(String editionId, Map<String, dynamic> versesBySurah) async {
    await _translationStore.record(editionId).put(_db, versesBySurah);
  }

  Future<Map<String, dynamic>?> getTranslationEdition(String editionId) async {
    return await _translationStore.record(editionId).get(_db);
  }

  Future<List<String>> getDownloadedEditionIds() async {
    final keys = await _translationStore.findKeys(_db);
    return keys;
  }

  Future<void> deleteTranslationEdition(String editionId) async {
    await _translationStore.record(editionId).delete(_db);
  }

  // Maintenance
  Future<void> clearContent() async {
    await _db.transaction((txn) async {
      await _surahIndexStore.delete(txn);
      await _surahDetailStore.delete(txn);
      await _metaStore.record('import_complete').put(txn, false);
    });
  }
}
