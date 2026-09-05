import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/audio_controller.dart';
import '../controllers/memorize_controller.dart';
import '../models/surah_model.dart';

class MemorizeScreen extends StatefulWidget {
  final Surah surah;

  const MemorizeScreen({Key? key, required this.surah}) : super(key: key);

  @override
  State<MemorizeScreen> createState() => _MemorizeScreenState();
}

class _MemorizeScreenState extends State<MemorizeScreen> {
  late final MemorizeController memorizeController;
  late final AudioController audioController;
  final TextEditingController _searchController = TextEditingController();
  final RxString _reciterQuery = ''.obs;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<MemorizeController>()) {
      Get.put(MemorizeController());
    }
    memorizeController = Get.find<MemorizeController>();
    audioController = Get.find<AudioController>();
    memorizeController.startSession(widget.surah.number, widget.surah.totalAyah);
  }

  @override
  void dispose() {
    _searchController.dispose();
    memorizeController.stopLoop();
    audioController.stopAudio();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Memorize', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            Text(
              widget.surah.name,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
      // Controls stay pinned at the top; only the reciter list scrolls.
      body: Column(
        children: [
          _buildControlPanel(context),
          Divider(height: 1, color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
          Expanded(child: _buildReciterSection(context)),
        ],
      ),
    );
  }

  // ---- Top (pinned) control panel: selected reciter + download/loop ----

  Widget _buildControlPanel(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [colorScheme.primaryContainer, colorScheme.primaryContainer.withOpacity(0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Obx(() {
        final reciter = audioController.reciters.firstWhereOrNull((r) => r.id == memorizeController.reciterId.value);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.record_voice_over, color: colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    reciter?.name ?? 'Choose a reciter below',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: colorScheme.onPrimaryContainer),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDownloadAndLoopControls(context),
          ],
        );
      }),
    );
  }

  // Reads memorizeController/audioController Rx state directly (no nested
  // Builder/itemBuilder) so it stays inside the enclosing Obx's tracking scope.
  Widget _buildDownloadAndLoopControls(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (memorizeController.isCheckingDownload.value) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 6),
        child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
      );
    }

    if (memorizeController.isDownloading.value) {
      final done = memorizeController.downloadedCount.value;
      final total = memorizeController.downloadTotal.value;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Downloading… $done/$total ayahs', style: TextStyle(color: colorScheme.onPrimaryContainer, fontSize: 13)),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(value: total > 0 ? done / total : 0, minHeight: 6),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(onPressed: memorizeController.cancelDownload, child: const Text('Cancel')),
          ),
        ],
      );
    }

    if (!memorizeController.isDownloaded.value) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: memorizeController.reciterId.value.isEmpty ? null : memorizeController.downloadCurrentSurah,
          icon: const Icon(Icons.download),
          label: Text('Download ${widget.surah.totalAyah} ayahs'),
        ),
      );
    }

    // Downloaded: range picker + loop controls
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Ayah ${memorizeController.rangeStart.value} – ${memorizeController.rangeEnd.value}',
              style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600, fontSize: 13),
            ),
            TextButton(
              onPressed: memorizeController.deleteDownload,
              style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 0), tapTargetSize: MaterialTapTargetSize.shrinkWrap),
              child: const Text('Delete download', style: TextStyle(fontSize: 12)),
            ),
          ],
        ),
        RangeSlider(
          min: 1,
          max: widget.surah.totalAyah.toDouble().clamp(2, double.infinity),
          divisions: (widget.surah.totalAyah - 1).clamp(1, 1000),
          labels: RangeLabels('${memorizeController.rangeStart.value}', '${memorizeController.rangeEnd.value}'),
          values: RangeValues(
            memorizeController.rangeStart.value.toDouble(),
            memorizeController.rangeEnd.value.toDouble(),
          ),
          onChanged: (values) {
            memorizeController.setRange(values.start.round(), values.end.round());
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton.filled(
              icon: Icon(memorizeController.isLooping.value ? Icons.stop : Icons.repeat),
              onPressed: memorizeController.isLooping.value ? memorizeController.stopLoop : memorizeController.playLoop,
            ),
            const SizedBox(width: 12),
            Text(
              memorizeController.isLooping.value
                  ? (audioController.currentAyahNumber.value > 0
                      ? 'Repeating ayah ${audioController.currentAyahNumber.value}'
                      : 'Starting…')
                  : 'Loops until you stop it',
              style: TextStyle(
                color: memorizeController.isLooping.value ? colorScheme.primary : colorScheme.onSurfaceVariant.withOpacity(0.9),
                fontWeight: memorizeController.isLooping.value ? FontWeight.w600 : FontWeight.normal,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---- Reciter section: pinned title + search, scrollable list below ----

  Widget _buildReciterSection(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 4),
          child: Text('Reciters', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: colorScheme.onBackground)),
        ),
        _buildReciterSearch(context),
        const SizedBox(height: 4),
        Expanded(child: _buildReciterList(context)),
      ],
    );
  }

  Widget _buildReciterSearch(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: colorScheme.onSurface),
        decoration: InputDecoration(
          hintText: 'Search reciters...',
          hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
          prefixIcon: Icon(Icons.search, color: colorScheme.primary),
          suffixIcon: Obx(() => _reciterQuery.value.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    _reciterQuery.value = '';
                  },
                )
              : const SizedBox.shrink()),
          filled: true,
          fillColor: colorScheme.surface,
          contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 12),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: colorScheme.primary, width: 2),
          ),
        ),
        onChanged: (value) => _reciterQuery.value = value,
      ),
    );
  }

  Widget _buildReciterList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    // Single Obx covering the whole scrollable list: rows are built inline
    // (not via ListView.builder's itemBuilder, which runs outside this
    // closure's tracking window and would silently stop reacting to state).
    return Obx(() {
      final query = _reciterQuery.value.trim().toLowerCase();
      final reciters = query.isEmpty
          ? audioController.reciters
          : audioController.reciters.where((r) => r.name.toLowerCase().contains(query)).toList();

      if (reciters.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Text('No reciters match "$query"', style: TextStyle(color: colorScheme.onSurfaceVariant)),
        );
      }

      final downloadedIds = memorizeController.downloadedReciterIds;
      final downloaded = reciters.where((r) => downloadedIds.contains(r.id)).toList();
      final rest = reciters.where((r) => !downloadedIds.contains(r.id)).toList();

      return ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 16),
        children: [
          if (downloaded.isNotEmpty) ...[
            _buildReciterGroupHeader(context, 'Downloaded'),
            for (final reciter in downloaded) _buildReciterRow(context, reciter),
          ],
          if (downloaded.isNotEmpty && rest.isNotEmpty) _buildReciterGroupHeader(context, 'All reciters'),
          for (final reciter in rest) _buildReciterRow(context, reciter),
        ],
      );
    });
  }

  Widget _buildReciterGroupHeader(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.6, color: colorScheme.primary),
      ),
    );
  }

  Widget _buildReciterRow(BuildContext context, ReciterInfo reciter) {
    final colorScheme = Theme.of(context).colorScheme;

    final isSelected = memorizeController.reciterId.value == reciter.id;
    final isPreviewing = audioController.isAyahPlaying(widget.surah.number, MemorizeController.previewAyahNumber) &&
        audioController.currentReciterId.value == reciter.id;
    final isPreviewLoading = audioController.isAyahLoadingFor(widget.surah.number, MemorizeController.previewAyahNumber) &&
        audioController.currentReciterId.value == reciter.id;

    return InkWell(
      onTap: memorizeController.isDownloading.value ? null : () => memorizeController.selectReciter(reciter.id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: isSelected ? colorScheme.primaryContainer.withOpacity(0.35) : Colors.transparent,
        child: Row(
          children: [
            isPreviewLoading
                ? const SizedBox(
                    width: 40,
                    height: 40,
                    child: Center(
                      child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                    ),
                  )
                : IconButton(
                    icon: Icon(
                      isPreviewing ? Icons.pause_circle : Icons.play_circle_outline,
                      color: colorScheme.primary,
                      size: 28,
                    ),
                    tooltip: 'Preview',
                    onPressed: () => memorizeController.previewSampleAyah(reciter.id),
                  ),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                reciter.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: colorScheme.onBackground,
                ),
              ),
            ),
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? colorScheme.primary : colorScheme.onSurfaceVariant,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
