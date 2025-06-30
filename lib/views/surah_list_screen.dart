import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/quran_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/bookmark_controller.dart';
import '../controllers/last_read_controller.dart';
import '../models/last_read_model.dart';
import '../models/surah_model.dart';
import '../routes/app_routes.dart';
import 'package:url_launcher/url_launcher.dart';
import 'widgets/last_read_bottom_sheet.dart';
import 'widgets/about_bottom_sheet.dart';
import 'widgets/theme_bottom_sheet.dart';
import '../services/quran_service.dart';

class SurahListScreen extends StatefulWidget {
  const SurahListScreen({super.key});

  @override
  State<SurahListScreen> createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  final QuranController quranController = Get.find<QuranController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final BookmarkController bookmarkController = Get.find<BookmarkController>();
  final LastReadController lastReadController = Get.find<LastReadController>();
  final TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showLastReadBottomSheet();
    });
  }

  void _showLastReadBottomSheet() {
    final lastRead = lastReadController.lastRead.value;
    if (lastRead != null) {
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => LastReadBottomSheet(lastRead: lastRead),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Obx(() {
        // Show loading only during initial surah list fetch
        if (quranController.isLoading.value) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (quranController.hasError.value) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${quranController.errorMessage.value}',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: quranController.fetchSurahs,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        if (quranController.surahs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.warning_amber_rounded, size: 48, color: Colors.amber),
                SizedBox(height: 16),
                Text('No surahs found'),
              ],
            ),
          );
        }

        // Always show list when available (DB-first makes this instant after first import)
        return _buildSurahsList(context);
      }),
    );
  }

  Widget _buildSurahsList(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Column(
          children: [
            // Header with app title and controls
            SafeArea(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: colorScheme.primary,
                child: Row(
                  children: [
                    Icon(
                      Icons.menu_book,
                      color: colorScheme.onPrimary,
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'The Holy Quran',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onPrimary,
                      ),
                    ),
                    const Spacer(),
                    // Bookmarks icon
                    IconButton(
                      icon: const Icon(Icons.bookmark),
                      tooltip: 'Bookmarks',
                      color: colorScheme.onPrimary,
                      onPressed: () => _showBookmarksBottomSheet(context),
                    ),
                    // Theme icon
                    IconButton(
                      icon: Obx(() {
                        if (themeController.useSystemTheme.value) {
                          // Show the actual current theme with a system indicator
                          final brightness = MediaQuery.of(context).platformBrightness;
                          return Stack(
                            alignment: Alignment.bottomRight,
                            children: [
                              // Show the actual current theme icon
                              Icon(brightness == Brightness.dark ? Icons.dark_mode : Icons.light_mode),
                              // Add a small indicator that it's system-controlled
                              Container(
                                height: 10,
                                width: 10,
                                decoration: BoxDecoration(
                                  color: colorScheme.onPrimary,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.brightness_auto,
                                  size: 8,
                                  color: colorScheme.primary,
                                ),
                              ),
                            ],
                          );
                        } else if (themeController.isDarkMode.value) {
                          return const Icon(Icons.dark_mode);
                        } else {
                          return const Icon(Icons.light_mode);
                        }
                      }),
                      tooltip: 'Theme Settings',
                      color: colorScheme.onPrimary,
                      onPressed: () => _showThemeDialog(context),
                    ),
                    // Menu icon
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'Menu',
                      color: colorScheme.onPrimary,
                      onPressed: () => _showMenuBottomSheet(context),
                    ),
                  ],
                ),
              ),
            ),

            // Enhanced search box that can search both surahs and ayats
            Padding(
              padding: const EdgeInsets.all(16),
              child: Container(
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: searchController,
                  onChanged: quranController.filterSurahs,
                  decoration: InputDecoration(
                    hintText: 'Search surah by name or number',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: Obx(() {
                      if (quranController.searchQuery.value.isNotEmpty) {
                        return IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            searchController.clear();
                            quranController.filterSurahs('');
                          },
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: colorScheme.primary, width: 1),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    filled: true,
                    fillColor: colorScheme.surface,
                  ),
                ),
              ),
            ),

            // List view of surahs
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.only(bottom: 24),
                physics: const BouncingScrollPhysics(),
                itemCount: quranController.filteredSurahs.length,
                itemBuilder: (context, index) {
                  final surah = quranController.filteredSurahs[index];
                  return _buildSurahTile(context, surah);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSurahTile(BuildContext context, Surah surah) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          print('Tapped on surah: ${surah.name} (${surah.number})');
          // Ensure detail is already cached in memory from DB for instant render
          try {
            final quranService = Get.find<QuranService>();
            await quranService.ensureDetailCached(surah.number);
          } catch (_) {
            // ignore; detail will still resolve quickly due to DB-first path
          }
          // Navigate to surah details with surah number in URL
          Get.toNamed(
            '/surah/${surah.number}',
            arguments: surah,
          );
          print('Navigation completed');
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Surah number in decorative container
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: colorScheme.primaryContainer,
                ),
                child: Center(
                  child: Text(
                    '${surah.number}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),

              // Surah name and details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            surah.name,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: colorScheme.onBackground,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      surah.nameTranslation,
                      style: TextStyle(
                        fontSize: 14,
                        color: colorScheme.onBackground.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildInfoChip(context, '${surah.totalAyah} Ayahs'),
                        const SizedBox(width: 8),
                        _buildInfoChip(context, surah.revelationPlace),
                      ],
                    ),
                  ],
                ),
              ),

              // Arabic name on the right
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(BuildContext context, String label) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  void _showBookmarksBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBookmarksContent(context),
    );
  }

  Widget _buildBookmarksContent(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle for the bottom sheet
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

          // Title
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bookmarks',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onBackground,
                ),
              ),
              if (bookmarkController.bookmarks.isNotEmpty)
                TextButton.icon(
                  onPressed: () {
                    // Show confirmation dialog
                    _showClearBookmarksDialog(context);
                  },
                  icon: Icon(Icons.delete_outline, color: colorScheme.error),
                  label: Text(
                    'Clear All',
                    style: TextStyle(color: colorScheme.error),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // Bookmarks list or empty state
          Obx(() {
            if (bookmarkController.bookmarks.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.bookmark_border,
                        size: 64,
                        color: colorScheme.primary.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No bookmarks yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onBackground,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Bookmark verses to find them here',
                        style: TextStyle(
                          color: colorScheme.onBackground.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            return Expanded(
              child: ListView.builder(
                itemCount: bookmarkController.bookmarks.length,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                itemBuilder: (context, index) {
                  final bookmark = bookmarkController.bookmarks[index];
                  return _buildBookmarkItem(context, bookmark);
                },
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBookmarkItem(BuildContext context, dynamic bookmark) {
    final colorScheme = Theme.of(context).colorScheme;
    final surahNumber = bookmark.surahNumber;
    final ayahNumber = bookmark.ayahNumber;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.pop(context); // Close bottom sheet

          // Get the surah object from controller
          final quranController = Get.find<QuranController>();
          final surah = quranController.getSurahByNumber(surahNumber);

          if (surah != null) {
            print('Navigating to surah ${surah.name} from bookmark, scrolling to ayah $ayahNumber');
            Get.toNamed(
              '/surah/${surahNumber}',
              arguments: {
                'surah': surah,
                'scrollToAyah': ayahNumber
              },
            );
          } else {
            print('Navigating to surah $surahNumber from bookmark by ID, scrolling to ayah $ayahNumber');
            Get.toNamed(
              '/surah/${surahNumber}',
              arguments: {
                'scrollToAyah': ayahNumber
              },
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${bookmark.surahName} ${surahNumber}:${ayahNumber}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(
                      Icons.delete_outline,
                      size: 20,
                      color: colorScheme.error,
                    ),
                    tooltip: 'Remove bookmark',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () => bookmarkController.removeBookmark(
                      surahNumber,
                      ayahNumber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                bookmark.ayahText,
                style: TextStyle(
                  fontFamily: 'IndoPak',
                  fontSize: 18,
                  height: 1.6,
                  color: colorScheme.onBackground,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
              ),
              const SizedBox(height: 8),
              Text(
                bookmark.translation,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: colorScheme.onBackground.withOpacity(0.8),
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showClearBookmarksDialog(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Clear All Bookmarks',
          style: TextStyle(color: colorScheme.onBackground),
        ),
        content: Text(
          'Are you sure you want to remove all bookmarks? This action cannot be undone.',
          style: TextStyle(color: colorScheme.onBackground),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: TextStyle(color: colorScheme.primary),
            ),
          ),
          TextButton(
            onPressed: () {
              bookmarkController.clearAllBookmarks();
              Navigator.pop(context);
            },
            child: Text(
              'Clear',
              style: TextStyle(color: colorScheme.error),
            ),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AboutBottomSheet(),
    );
  }

  void _showThemeDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const ThemeBottomSheet(),
    );
  }

  void _showMenuBottomSheet(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.6,
        ),
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 24),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle for the bottom sheet
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
            const SizedBox(height: 24),

            // Menu items
            ListTile(
              leading: Icon(Icons.search, color: colorScheme.primary),
              title: const Text('Advanced Search'),
              onTap: () {
                Navigator.pop(context);
                Get.toNamed('/search');
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: colorScheme.primary),
              title: const Text('About'),
              onTap: () {
                Navigator.pop(context);
                _showAboutDialog(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
