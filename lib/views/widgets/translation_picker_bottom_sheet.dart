import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/translation_controller.dart';
import '../../models/translation_edition.dart';
import '../../utils/app_bottom_sheet.dart';
import 'translation_manage_bottom_sheet.dart';

/// Bottom sheet that lets the user pick a single active translation edition.
/// Editions are grouped by language, each showing the translator, a short
/// native-language title, and a description to help the user choose.
class TranslationPickerBottomSheet extends StatelessWidget {
  const TranslationPickerBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final TranslationController controller = Get.find<TranslationController>();
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
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
              'Translation',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Choose the translation shown under each ayah',
              style: TextStyle(
                fontSize: 13,
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Flexible(
            child: Obx(() {
              final grouped = controller.installedByLanguage;
              final selectedId = controller.selectedEditionId.value;
              return ListView(
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  for (final entry in grouped.entries) ...[
                    _languageHeader(context, entry.key),
                    for (final edition in entry.value)
                      _editionTile(context, controller, edition, selectedId == edition.id),
                  ],
                ],
              );
            }),
          ),
          // Download more translations
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    showAppBottomSheet(
                      context: context,
                      builder: (_) => const TranslationManageBottomSheet(),
                    );
                  },
                  icon: const Icon(Icons.download_outlined, size: 20),
                  label: const Text('Download more languages'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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

  Widget _editionTile(
    BuildContext context,
    TranslationController controller,
    TranslationEdition edition,
    bool isSelected,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      onTap: () {
        controller.setEdition(edition.id);
        Navigator.of(context).pop();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        color: isSelected ? colorScheme.primaryContainer.withOpacity(0.35) : Colors.transparent,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          edition.translator,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onBackground,
                          ),
                        ),
                      ),
                      if (edition.title.isNotEmpty)
                        Text(
                          edition.title,
                          style: TextStyle(
                            fontSize: 13,
                            color: colorScheme.onSurfaceVariant,
                          ),
                          textDirection:
                              edition.isRtl ? TextDirection.rtl : TextDirection.ltr,
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    edition.description,
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
