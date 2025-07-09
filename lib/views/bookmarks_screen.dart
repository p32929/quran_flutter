import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/bookmark_controller.dart';
import '../controllers/theme_controller.dart';
import '../utils/share_utils.dart';
import '../models/ayah_model.dart';

class BookmarksScreen extends StatelessWidget {
  const BookmarksScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final BookmarkController bookmarkController = Get.find<BookmarkController>();
    final ThemeController themeController = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Bookmarks'),
        centerTitle: false, // Left align the title
      ),
      body: Obx(() {
        if (bookmarkController.bookmarks.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.bookmark_border,
                  size: 64,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No bookmarks yet',
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Bookmark your favorite ayahs to see them here',
                  style: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: bookmarkController.bookmarks.length,
          itemBuilder: (context, index) {
            final bookmark = bookmarkController.bookmarks[index];
            final Ayah ayah = Ayah(
              number: bookmark.ayahNumber,
              arabic: bookmark.ayahText,
              english: bookmark.translation,
              bengali: '', // We don't have this in bookmarks
            );
            
            final int surahNumber = bookmark.surahNumber;
            final String surahName = bookmark.surahName;

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Surah $surahName ($surahNumber:${ayah.number})',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.bookmark,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () => bookmarkController.toggleBookmark(
                            ayah,
                            surahNumber,
                            surahName,
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.share,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          onPressed: () => ShareUtils.shareAyah(
                            ayah,
                            surahNumber,
                            surahName,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Obx(() => Text(
                      ayah.arabic,
                      style: TextStyle(
                        fontFamily: 'IndoPak',
                        fontSize: themeController.arabicFontSize.value,
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                      textAlign: TextAlign.right,
                    )),
                    const SizedBox(height: 16),
                    Obx(() => Text(
                      ayah.english,
                      style: TextStyle(
                        fontSize: themeController.englishFontSize.value,
                        height: 1.5,
                        color: Theme.of(context).colorScheme.onBackground,
                      ),
                    )),
                  ],
                ),
              ),
            );
          },
        );
      }),
    );
  }
} 