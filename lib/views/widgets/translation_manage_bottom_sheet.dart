import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/translation_controller.dart';
import '../../models/translation_edition.dart';
import '../../utils/snackbar_utils.dart';

/// Browse and download translation editions grouped by language, with search.
/// Downloaded editions can be selected (to display) or removed.
class TranslationManageBottomSheet extends StatefulWidget {
  const TranslationManageBottomSheet({super.key});

  @override
  State<TranslationManageBottomSheet> createState() => _TranslationManageBottomSheetState();
}

class _TranslationManageBottomSheetState extends State<TranslationManageBottomSheet> {
  final TranslationController controller = Get.find<TranslationController>();
  final TextEditingController _searchCtrl = TextEditingController();
  final RxString _query = ''.obs;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withOpacity(0.4),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Download languages',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => _query.value = v.trim().toLowerCase(),
              decoration: InputDecoration(
                hintText: 'Search language or translator',
                prefixIcon: const Icon(Icons.search),
                isDense: true,
                filled: true,
                fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Obx(() {
              final q = _query.value;
              // touch reactive sources so the list rebuilds on download/delete
              controller.downloadedIds.length;
              controller.downloadingIds.length;

              final grouped = controller.availableByLanguage;
              final entries = grouped.entries.where((e) {
                if (q.isEmpty) return true;
                if (e.key.toLowerCase().contains(q)) return true;
                return e.value.any((ed) => ed.translator.toLowerCase().contains(q));
              }).toList();

              if (entries.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(
                    child: Text('No matches',
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ),
                );
              }

              return ListView(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  for (final entry in entries) ...[
                    _languageHeader(context, entry.key),
                    for (final ed in _filterEditions(entry.value, q))
                      _editionRow(context, ed),
                  ],
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  List<TranslationEdition> _filterEditions(List<TranslationEdition> list, String q) {
    if (q.isEmpty) return list;
    final lang = list.isNotEmpty ? list.first.language.toLowerCase() : '';
    // Language name matched → show all its editions; else only matching translators
    if (lang.contains(q)) return list;
    return list.where((ed) => ed.translator.toLowerCase().contains(q)).toList();
  }

  Widget _languageHeader(BuildContext context, String language) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Text(
        language.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.8,
          color: colorScheme.primary,
        ),
      ),
    );
  }

  Widget _editionRow(BuildContext context, TranslationEdition ed) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDownloaded = controller.isDownloaded(ed.id);
    final isDownloading = controller.isDownloading(ed.id);
    final isSelected = controller.selectedEditionId.value == ed.id;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      color: isSelected ? colorScheme.primaryContainer.withOpacity(0.3) : Colors.transparent,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ed.translator,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onBackground,
                  ),
                ),
                Text(
                  ed.isRtl ? '${ed.language} · right-to-left' : ed.language,
                  style: TextStyle(fontSize: 12, color: colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _trailing(context, ed, isDownloaded, isDownloading, isSelected),
        ],
      ),
    );
  }

  Widget _trailing(BuildContext context, TranslationEdition ed, bool isDownloaded,
      bool isDownloading, bool isSelected) {
    final colorScheme = Theme.of(context).colorScheme;

    if (isDownloading) {
      return const SizedBox(
        width: 24, height: 24,
        child: CircularProgressIndicator(strokeWidth: 2.4),
      );
    }

    if (isDownloaded) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.check_circle, color: colorScheme.primary, size: 22),
            )
          else
            TextButton(
              onPressed: () => controller.setEdition(ed.id),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(0, 34),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text('Select'),
            ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colorScheme.error, size: 20),
            tooltip: 'Remove',
            visualDensity: VisualDensity.compact,
            onPressed: () => controller.deleteDownloaded(ed.id),
          ),
        ],
      );
    }

    // Not downloaded → download button
    return TextButton.icon(
      onPressed: () async {
        final ok = await controller.downloadEdition(ed.id, selectWhenDone: true);
        if (!ok) {
          SnackbarUtils.show('Download failed',
              'Could not download ${ed.translator}. Check your connection and try again.');
        }
      },
      icon: const Icon(Icons.download_outlined, size: 18),
      label: const Text('Download'),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        minimumSize: const Size(0, 34),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
    );
  }
}
