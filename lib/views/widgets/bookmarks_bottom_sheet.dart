import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/bookmark_controller.dart';
import '../../models/bookmark_model.dart';
import '../../controllers/quran_controller.dart';
import '../../routes/app_routes.dart';

class BookmarksBottomSheet extends StatelessWidget {
  const BookmarksBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final BookmarkController bookmarkController = Get.find<BookmarkController>();
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.8,
      ),
      padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
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
              Obx(() => bookmarkController.bookmarks.isNotEmpty
                ? TextButton.icon(
                    onPressed: () => _showClearConfirmDialog(context, bookmarkController),
                    icon: Icon(Icons.delete_outline, color: colorScheme.error),
                    label: Text(
                      'Clear All',
                      style: TextStyle(color: colorScheme.error),
                    ),
                  )
                : const SizedBox(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Bookmarks list
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
                shrinkWrap: true,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 24),
                itemBuilder: (context, index) {
                  final Bookmark bookmark = bookmarkController.bookmarks[index];
                  return _buildBookmarkTile(context, bookmark, bookmarkController);
                },
              ),
            );
          }),
        ],
      ),
    );
  }
  
  Widget _buildBookmarkTile(
    BuildContext context, 
    Bookmark bookmark, 
    BookmarkController controller
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Get.back(); // Close bottom sheet
          
          // Get the surah object from controller
          final quranController = Get.find<QuranController>();
          final surah = quranController.getSurahByNumber(bookmark.surahNumber);
          
          print('Navigating to surah ${bookmark.surahNumber} with scrollToAyah ${bookmark.ayahNumber}');
          
          if (surah != null) {
            Get.toNamed(
              '/surah/${bookmark.surahNumber}',
              arguments: {
                'surah': surah,
                'scrollToAyah': bookmark.ayahNumber,
              },
            );
          } else {
            Get.toNamed(
              '/surah/${bookmark.surahNumber}',
              arguments: {
                'scrollToAyah': bookmark.ayahNumber,
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
                      '${bookmark.surahName} ${bookmark.surahNumber}:${bookmark.ayahNumber}',
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
                    onPressed: () => controller.removeBookmark(
                      bookmark.surahNumber,
                      bookmark.ayahNumber,
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
  
  void _showClearConfirmDialog(BuildContext context, BookmarkController controller) {
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
              controller.clearAllBookmarks();
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
} 