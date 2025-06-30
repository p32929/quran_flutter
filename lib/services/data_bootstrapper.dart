import 'dart:async';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'quran_repository.dart';
import 'importer.dart';
import '../services/quran_service.dart';

class DataBootstrapper {
  final QuranRepository repo;

  DataBootstrapper(this.repo);

  // Reads assets/data/version.txt and decides whether to import data to Sembast.
  // Returns the version detected and whether an import happened.
  Future<BootstrapResult> initialize({void Function(int, int)? onProgress}) async {
    // Open DB
    await repo.open();

    // Try to read asset version
    final int assetVersion = await _readAssetVersion();

    // Read DB meta
    final int? dbVersion = await repo.getDataVersion();
    final bool importComplete = await repo.getImportComplete();

    final bool needsImport = !importComplete || dbVersion == null || assetVersion > dbVersion;

    if (needsImport) {
      // Clear previous content if any
      await repo.clearContent();

      // Import from assets into DB
      final importer = DataImporter(repo);
      await importer.importAll(onProgress: onProgress);

      // Set version and flags
      await repo.setDataVersion(assetVersion);
      await repo.setImportComplete(true);
      await repo.setLastImportTs(DateTime.now().millisecondsSinceEpoch);
    }

    // Optionally hydrate QuranService's in-memory cache with index for instant list
    if (Get.isRegistered<QuranService>()) {
      final service = Get.find<QuranService>();
      // Let service lazily read from DB later; no-op here for Step A to keep changes minimal
      // A future step can hydrate memory cache for instant UI.
    }

    return BootstrapResult(
      assetVersion: assetVersion,
      dbVersion: dbVersion,
      imported: needsImport,
    );
  }

  Future<int> _readAssetVersion() async {
    try {
      final s = await rootBundle.loadString('assets/data/version.txt');
      final v = int.tryParse(s.trim());
      return v ?? 1;
    } catch (_) {
      // Default to 1 if missing
      return 1;
    }
  }
}

class BootstrapResult {
  final int assetVersion;
  final int? dbVersion;
  final bool imported;

  BootstrapResult({
    required this.assetVersion,
    required this.dbVersion,
    required this.imported,
  });
}
