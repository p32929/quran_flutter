import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import '../controllers/quran_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/bookmark_controller.dart';
import '../controllers/audio_controller.dart';
import '../controllers/last_read_controller.dart';
import '../controllers/translation_controller.dart';
import '../models/surah_model.dart';
import '../models/ayah_model.dart';
import '../utils/text_styles.dart';
import '../utils/share_utils.dart';
import '../utils/app_bottom_sheet.dart';
import 'widgets/settings_bottom_sheet.dart';
import 'widgets/audio_bottom_sheet.dart';

class SurahDetailsScreen extends StatefulWidget {
  final Surah surah;

  const SurahDetailsScreen({Key? key, required this.surah}) : super(key: key);

  @override
  State<SurahDetailsScreen> createState() => _SurahDetailsScreenState();
}

class _SurahDetailsScreenState extends State<SurahDetailsScreen> {
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener = ItemPositionsListener.create();
  final QuranController quranController = Get.find<QuranController>();
  final BookmarkController bookmarkController = Get.find<BookmarkController>();
  final ThemeController themeController = Get.find<ThemeController>();
  late final AudioController audioController;
  final LastReadController lastReadController = Get.find<LastReadController>();
  late final TranslationController translationController;

  // Add a local loading state to ensure complete loading
  final RxBool isInitializing = true.obs;

  // Follows the currently playing ayah to auto-scroll it into view
  Worker? _playingAyahWorker;

  @override
  void initState() {
    super.initState();

    // Check if AudioController exists or initialize it
    if (!Get.isRegistered<AudioController>()) {
      Get.put(AudioController());
    }

    audioController = Get.find<AudioController>();

    if (!Get.isRegistered<TranslationController>()) {
      Get.put(TranslationController());
    }
    translationController = Get.find<TranslationController>();

    // Auto-scroll to the playing ayah when it changes (e.g. playlist advances)
    _playingAyahWorker = ever(audioController.currentAyahNumber, (int ayahNumber) {
      if (ayahNumber > 0 && audioController.currentAyahSurah.value == widget.surah.number) {
        _scrollToPlayingAyahIfNeeded(ayahNumber);
      }
    });

    // Handle initial data loading first, then check for scrollToAyah in a callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _playingAyahWorker?.dispose();

    // Stop audio when leaving the surah details screen
    if (audioController.isCurrentlyPlaying(widget.surah.number.toString()) ||
        audioController.currentAyahSurah.value == widget.surah.number) {
      audioController.stopAudio();
    }

    // Save the last read position
    final lastReadVerse = _getCurrentVerseNumber();
    if (lastReadVerse != null) {
      lastReadController.saveLastRead(widget.surah.number, lastReadVerse);
    }

    super.dispose();
  }

  int? _getCurrentVerseNumber() {
    final positions = itemPositionsListener.itemPositions.value;
    if (positions.isNotEmpty) {
      final firstVisibleItem = positions.first;
      final showArabic = themeController.showArabicText.value;
      final hasBismillah = widget.surah.number != 1 && widget.surah.number != 9 && showArabic;
      final headerItemCount = 1 + (hasBismillah ? 1 : 0);
      final ayahIndex = firstVisibleItem.index - headerItemCount;
      if (ayahIndex >= 0 && ayahIndex < quranController.ayahs.length) {
        return quranController.ayahs[ayahIndex].number;
      }
    }
    return null;
  }

  void _loadData() async {
    try {
      // Set initializing to true
      isInitializing.value = true;

      // First load the data
      await quranController.fetchSurahDetail(widget.surah.number);

      // Then check for scrolling arguments after data is loaded
      if (!quranController.hasError.value) {
        _checkForScrollToAyah();

        // Load audio data for this surah
        _loadAudioData();
      }

      // Add a slight delay to ensure UI has time to render properly
      await Future.delayed(const Duration(milliseconds: 300));

      // Mark initialization as complete
      isInitializing.value = false;
    } catch (e) {
      print('Error in _loadData: $e');
      isInitializing.value = false;
    }
  }

  void _loadAudioData() {
    // Get the surah detail and parse the audio data
    final surahDetail = quranController.currentSurahDetail.value;
    if (surahDetail != null) {
      // Access the raw JSON to get audio data
      final rawData = surahDetail.rawData;
      if (rawData != null && rawData.containsKey('audio')) {
        final audioData = rawData['audio'] as Map<String, dynamic>;
        audioController.loadReciters(audioData);
      }
    }
  }

  void _checkForScrollToAyah() {
    // Get arguments (might be null)
    final args = Get.arguments;
    if (args is Map<String, dynamic>) {
      // Handle scroll to ayah if present
      if (args.containsKey('scrollToAyah')) {
        final ayahNumber = args['scrollToAyah'] as int;
        print('Found scrollToAyah argument: $ayahNumber');

        // Give time for the list to render before scrolling
        Future.delayed(const Duration(milliseconds: 500), () {
          _scrollToAyah(ayahNumber);
        });
      }

      // Handle temporary translation language if present
      if (args.containsKey('tempTranslationLanguage') && args['tempTranslationLanguage'] != null) {
        final tempLang = args['tempTranslationLanguage'] as String;
        print('Found tempTranslationLanguage argument: $tempLang');

        // Only set if different from current
        if (tempLang != themeController.translationLanguage.value) {
          // Temporarily set the translation language based on the search language
          themeController.setTemporaryTranslationLanguage(tempLang);
        }
      }
    }
  }

  // Scrolls to the playing ayah only when it isn't already fully visible,
  // so it doesn't fight the user while they're looking right at it
  void _scrollToPlayingAyahIfNeeded(int ayahNumber) {
    final targetIndex = ayahNumber - 1;
    if (targetIndex < 0 || targetIndex >= quranController.ayahs.length) return;
    if (!itemScrollController.isAttached) return;

    final showArabic = themeController.showArabicText.value;
    final hasBismillah = widget.surah.number != 1 && widget.surah.number != 9 && showArabic;
    final headerItemCount = 1 + (hasBismillah ? 1 : 0);
    final scrollIndex = headerItemCount + targetIndex;

    // Already fully visible? Then leave the scroll position alone
    final positions = itemPositionsListener.itemPositions.value;
    final isFullyVisible = positions.any((p) =>
        p.index == scrollIndex && p.itemLeadingEdge >= 0 && p.itemTrailingEdge <= 1);
    if (isFullyVisible) return;

    itemScrollController.scrollTo(
      index: scrollIndex,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      alignment: 0.05,
    );
  }

  void _scrollToAyah(int ayahNumber) {
    print('Attempting to scroll to ayah $ayahNumber');
    // Ayah numbers start from 1, but list indices start from 0
    final targetIndex = ayahNumber - 1;

    // Ensure target index is valid
    if (targetIndex >= 0 && targetIndex < quranController.ayahs.length) {
      // Add header offset (surah header + bismillah if applicable and if Arabic text is shown)
      final showArabic = themeController.showArabicText.value;
      final hasBismillah = widget.surah.number != 1 && widget.surah.number != 9 && showArabic;
      final headerItemCount = 1 + (hasBismillah ? 1 : 0); // 1 for surah header

      // Calculate the actual index in the scrollable list (account for headers)
      final scrollIndex = headerItemCount + targetIndex;

      if (itemScrollController.isAttached) {
        print('Scroll controller is attached, scrolling to index $scrollIndex');
        itemScrollController.scrollTo(
          index: scrollIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1, // Scroll a little beyond the top
        );
      } else {
        print('Scroll controller not attached yet, retrying in 300ms');
        // If the controller isn't attached yet, try again after a delay
        Future.delayed(const Duration(milliseconds: 300), () {
          _scrollToAyah(ayahNumber);
        });
      }
    } else {
      print('Invalid ayah number or ayahs not loaded: $ayahNumber');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      // Content area - completely scrollable
      body: Obx(() {
              // Show loading only while this screen initializes or controller fetching detail
              final bool showLoading = isInitializing.value || quranController.isLoading.value;

              if (showLoading) {
                return _buildLoadingView(isPreloading: false, preloadedCount: 0, totalCount: quranController.totalSurahCount);
              }

              // Check for errors
              if (quranController.hasError.value) {
                return _buildErrorView();
              }

              // If ayahs not yet available, still show a light loader (rare with DB-first)
              if (quranController.ayahs.isEmpty) {
                return _buildLoadingView(isPreloading: false, preloadedCount: 0, totalCount: quranController.totalSurahCount);
              }

              // If everything is ready, show the content
              return GetBuilder<ThemeController>(
                  id: 'surah_details_view',
                  key: ValueKey('surah_details_${themeController.translationLanguage.value}_${themeController.showArabicText.value}_${themeController.showTranslation.value}'),
                  builder: (themeCtrl) {
                    final showArabic = themeCtrl.showArabicText.value;
                    final arabicFontSize = themeCtrl.arabicFontSize.value;
                    final englishFontSize = themeCtrl.englishFontSize.value;
                    final showTranslation = themeCtrl.showTranslation.value;
                    final translationLanguage = themeCtrl.translationLanguage.value;

                    return _buildAyahsList(showArabic: showArabic, arabicFontSize: arabicFontSize, englishFontSize: englishFontSize, showTranslation: showTranslation, translationLanguage: translationLanguage);
                  });
      }),
    );
  }

  Widget _buildLoadingView({
    required bool isPreloading,
    required int preloadedCount,
    required int totalCount,
  }) {
    return const Center(
      child: CircularProgressIndicator(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              quranController.errorMessage.value,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              quranController.fetchSurahDetail(widget.surah.number);
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      // Two-line title: surah name + translation/ayah count. Colors, height,
      // status-bar fill and spacing all come from the shared appBarTheme.
      titleSpacing: 0,
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            widget.surah.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          Text(
            "${widget.surah.nameTranslation} • ${widget.surah.totalAyah} Ayahs",
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onPrimary.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      actions: [
        // Audio play button
        Obx(() => IconButton(
              icon: Icon(
                audioController.isCurrentlyPlaying(widget.surah.number.toString()) ? Icons.stop_circle : Icons.play_circle,
              ),
              tooltip: audioController.isCurrentlyPlaying(widget.surah.number.toString()) ? 'Stop Audio' : 'Play Audio',
              onPressed: () {
                if (audioController.isCurrentlyPlaying(widget.surah.number.toString())) {
                  audioController.stopAudio();
                } else {
                  _showAudioBottomSheet(context);
                }
              },
            )),
        // Settings button
        IconButton(
          icon: const Icon(Icons.settings),
          tooltip: 'Settings',
          onPressed: () => _showSettingsBottomSheet(context),
        ),
      ],
    );
  }

  Widget _buildSurahHeader(BuildContext context, double arabicFontSize) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primaryContainer,
            colorScheme.primaryContainer.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Surah number circle
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colorScheme.primary.withOpacity(0.2),
            ),
            child: Center(
              child: Text(
                '${widget.surah.number}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Arabic name
          Text(
            widget.surah.nameArabic,
            style: TextStyle(
              fontFamily: 'IndoPak',
              fontSize: arabicFontSize,
              fontWeight: FontWeight.bold,
              color: colorScheme.onPrimaryContainer,
            ),
            textAlign: TextAlign.center,
          ),

          const SizedBox(height: 16),

          // Revelation place & ayah count
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  widget.surah.revelationPlace,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${widget.surah.totalAyah} Ayahs',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAyahsList({
    required bool showArabic,
    required double arabicFontSize,
    required double englishFontSize,
    required bool showTranslation,
    required String translationLanguage,
  }) {
    final quranCtrl = Get.find<QuranController>();
    final ayahs = quranCtrl.ayahs;

    // Safety check - show loading if no ayahs
    if (ayahs.isEmpty) {
      return _buildLoadingView(isPreloading: quranCtrl.isPreloading.value, preloadedCount: quranCtrl.preloadedCount.value, totalCount: quranCtrl.totalSurahCount);
    }

    // We might have Bismillah (0 or 1 item) if Arabic text is shown
    final hasBismillah = widget.surah.number != 1 && widget.surah.number != 9 && showArabic;

    // Calculate total items (surah header + bismillah + ayahs)
    final totalItems = 1 + (hasBismillah ? 1 : 0) + ayahs.length;

    return ScrollablePositionedList.builder(
      itemCount: totalItems,
      itemBuilder: (context, index) {
        // Surah header is the first item
        if (index == 0) {
          return _buildSurahHeader(context, arabicFontSize);
        }

        // Bismillah is the second item (if present and Arabic is shown)
        if (hasBismillah && index == 1) {
          return _buildBismillah(context, arabicFontSize);
        }

        // Adjust index for ayahs (account for surah header and bismillah if present)
        final ayahIndex = hasBismillah ? index - 2 : index - 1;

        // Safety check to prevent index out of range
        if (ayahIndex < 0 || ayahIndex >= ayahs.length) {
          return SizedBox.shrink();
        }

        return _buildAyahCard(
          context,
          ayahs[ayahIndex],
          ayahIndex,
          showArabic: showArabic,
          arabicFontSize: arabicFontSize,
          englishFontSize: englishFontSize,
          showTranslation: showTranslation,
          translationLanguage: translationLanguage,
        );
      },
      itemScrollController: itemScrollController,
      itemPositionsListener: itemPositionsListener,
      padding: const EdgeInsets.only(bottom: 24),
    );
  }

  Widget _buildBismillah(BuildContext context, double arabicFontSize) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.primary.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        'بِسْمِ اللَّهِ الرَّحْمَٰنِ الرَّحِيمِ',
        style: TextStyle(
          fontFamily: 'IndoPak',
          fontSize: arabicFontSize,
          height: 1.5,
          color: colorScheme.primary,
          fontWeight: FontWeight.bold,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildAyahCard(
    BuildContext context,
    Ayah ayah,
    int index, {
    required bool showArabic,
    required double arabicFontSize,
    required double englishFontSize,
    required bool showTranslation,
    required String translationLanguage,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Obx(() {
      final isThisAyahCurrent = audioController.isAyahCurrent(widget.surah.number, ayah.number);
      final isThisAyahPlaying = audioController.isAyahPlaying(widget.surah.number, ayah.number);

      // Read the selected edition HERE (inside the Obx closure) so GetX records
      // the dependency and the card rebuilds when the translation changes.
      final edition = translationController.selected;
      String translationText = translationController.verseText(widget.surah.number, ayah.number);
      if (translationText.isEmpty) translationText = ayah.translationFor(edition.languageCode);

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          boxShadow: isThisAyahPlaying
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.45),
                    blurRadius: 16,
                    spreadRadius: 1,
                  ),
                ]
              : null,
        ),
        child: Card(
          key: ValueKey('ayah_${ayah.number}_${translationLanguage}_${showArabic}_${showTranslation}'),
          margin: EdgeInsets.zero,
          elevation: 1,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isThisAyahCurrent
                ? BorderSide(color: colorScheme.primary, width: 1.5)
                : BorderSide.none,
          ),
          child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                // Ayah number
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${ayah.number}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),

                const Spacer(),

                // Play/pause button for this ayah
                audioController.isAyahLoadingFor(widget.surah.number, ayah.number)
                    ? const SizedBox(
                        width: 48,
                        height: 48,
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          isThisAyahPlaying ? Icons.pause_circle : Icons.play_circle,
                          color: colorScheme.primary,
                        ),
                        tooltip: isThisAyahPlaying ? 'Pause' : 'Play Ayah',
                        onPressed: () => audioController.playAyah(widget.surah.number, ayah.number),
                      ),

                // Bookmark button (using GetBuilder to avoid nesting Obx)
                GetBuilder<BookmarkController>(builder: (bookmarkCtrl) {
                  final isBookmarked = bookmarkCtrl.isBookmarked(widget.surah.number, ayah.number);
                  return IconButton(
                    icon: Icon(
                      isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                      color: isBookmarked ? colorScheme.primary : colorScheme.onBackground.withOpacity(0.6),
                    ),
                    tooltip: 'Bookmark',
                    onPressed: () => bookmarkCtrl.toggleBookmark(
                      ayah,
                      widget.surah.number,
                      widget.surah.name,
                    ),
                  );
                }),

                // Share button
                IconButton(
                  icon: Icon(
                    Icons.share,
                    color: colorScheme.primary,
                  ),
                  tooltip: 'Share',
                  onPressed: () => ShareUtils.shareAyah(
                    ayah,
                    widget.surah.number,
                    widget.surah.name,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Arabic text in decorated container - conditionally displayed
            if (showArabic)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                ),
                child: Text(
                  ayah.arabic,
                  style: TextStyle(
                    fontFamily: 'IndoPak',
                    fontSize: arabicFontSize,
                    height: 1.8,
                    color: colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.right,
                ),
              ),

            // Only add spacing if both Arabic and translation are visible
            if (showArabic && showTranslation) const SizedBox(height: 16),

            // Translation text from the selected edition - conditionally displayed.
            // `edition`/`translationText` are read in the enclosing Obx closure
            // so switching editions rebuilds this text live.
            if (showTranslation)
              Container(
                padding: showArabic ? null : const EdgeInsets.all(16),
                decoration: showArabic
                    ? null
                    : BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: colorScheme.outline.withOpacity(0.2)),
                      ),
                child: Text(
                  translationText,
                  style: TextStyle(
                    fontSize: englishFontSize,
                    height: 1.6,
                    color: colorScheme.onBackground.withOpacity(0.9),
                  ),
                  textAlign: edition.isRtl ? TextAlign.right : TextAlign.left,
                  textDirection: edition.isRtl ? TextDirection.rtl : TextDirection.ltr,
                ),
              ),
          ],
            ),
          ),
        ),
      );
    });
  }

  void _showAudioBottomSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      builder: (context) => AudioBottomSheet(surah: widget.surah),
    );
  }

  void _showSettingsBottomSheet(BuildContext context) {
    showAppBottomSheet(
      context: context,
      builder: (context) => const SettingsBottomSheet(),
    );
  }
}
