import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart' as app;
import '../controllers/theme_controller.dart';
import '../controllers/bookmark_controller.dart';
import '../utils/share_utils.dart';
import 'dart:async';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final app.SearchController searchController = Get.find<app.SearchController>();
  final ThemeController themeController = Get.find<ThemeController>();
  final BookmarkController bookmarkController = Get.find<BookmarkController>();
  final TextEditingController textController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();
  
  // Add debounce timer for auto-search
  Timer? _debounce;
  // Add a reactive variable to track debounce state
  final RxBool isDebouncing = false.obs;
  // Add language detection for search
  final RxString detectedSearchLanguage = 'default'.obs;

  @override
  void initState() {
    super.initState();
    // Give focus to search field on screen open
    WidgetsBinding.instance.addPostFrameCallback((_) {
      searchFocusNode.requestFocus();
    });
  }
  
  @override
  void dispose() {
    textController.dispose();
    searchFocusNode.dispose();
    _debounce?.cancel(); // Cancel timer when disposing
    // Clear search state when disposing
    searchController.clearSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Search Quran',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: colorScheme.onPrimary,
          ),
        ),
        centerTitle: false, // Left align the title
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Get.back(),
        ),
      ),
      body: Column(
        children: [
          // Enhanced search input area with language filters built-in
          Material(
            elevation: 2,
            color: colorScheme.surface,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: TextField(
                    controller: textController,
                    focusNode: searchFocusNode,
                    style: TextStyle(color: colorScheme.onSurface),
                    decoration: InputDecoration(
                      hintText: 'Search for words in the Quran...',
                      hintStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
                      prefixIcon: Icon(Icons.search, color: colorScheme.primary),
                      suffixIcon: Obx(() {
                        if (isDebouncing.value) {
                          // Show loading spinner during debounce
                          return Padding(
                            padding: const EdgeInsets.all(12),
                            child: SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
                              ),
                            ),
                          );
                        } else if (searchController.searchQuery.value.isNotEmpty) {
                          // Show clear button if there's text
                          return IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              textController.clear();
                              searchController.clearSearch();
                              detectedSearchLanguage.value = 'default';
                            },
                          );
                        } else {
                          return const SizedBox.shrink();
                        }
                      }),
                      filled: true,
                      fillColor: colorScheme.surface,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.outline.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: colorScheme.primary, width: 2),
                      ),
                    ),
                    onSubmitted: (value) {
                      searchController.searchAyahs(value);
                    },
                    onChanged: (value) {
                      if (value.isEmpty) {
                        searchController.clearSearch();
                        isDebouncing.value = false;
                        detectedSearchLanguage.value = 'default';
                      } else {
                        // Debounce search while typing
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        // Show loading indicator while debouncing
                        isDebouncing.value = true;
                        
                        // Detect language of search term
                        detectSearchLanguage(value);
                        
                        _debounce = Timer(const Duration(milliseconds: 500), () {
                          // Auto search after typing stops for 500ms
                          if (value.trim().length > 2) { // Only search if at least 3 characters
                            searchController.searchAyahs(value);
                          }
                          isDebouncing.value = false;
                        });
                      }
                    },
                  ),
                ),
                
                // Language filters as toggleable chips
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Row(
                    children: [
                      Text(
                        'Search in:',
                        style: TextStyle(
                          color: colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Obx(() => Row(
                            children: [
                              _buildLanguageChip('English', searchController.searchInEnglish.value, 
                                () => searchController.toggleEnglishSearch()),
                              const SizedBox(width: 8),
                              _buildLanguageChip('Bengali', searchController.searchInBengali.value, 
                                () => searchController.toggleBengaliSearch()),
                            ],
                          )),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Detected language indicator
                Obx(() {
                  if (detectedSearchLanguage.value != 'default' && searchController.searchQuery.value.isNotEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      color: colorScheme.tertiaryContainer.withOpacity(0.5),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome, 
                            size: 16, 
                            color: colorScheme.tertiary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Detected ${detectedSearchLanguage.value} search',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onTertiaryContainer,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'Showing results in ${_getDisplayLanguage()}',
                            style: TextStyle(
                              fontSize: 12,
                              color: colorScheme.onTertiaryContainer,
                            ),
                          ),
                        ],
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                }),
              ],
            ),
          ),
          
          // Status bar with search info
          Obx(() {
            if (searchController.searchQuery.value.isNotEmpty && 
                !searchController.isSearching.value && 
                !isDebouncing.value &&
                searchController.hasResults.value) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: colorScheme.surfaceVariant,
                child: Row(
                  children: [
                    Text(
                      '${searchController.searchResults.length} results found',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    // Sort button could be added here in future
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          
          // Results or loading state
          Expanded(
            child: Obx(() {
              if (searchController.isSearching.value || isDebouncing.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(),
                      const SizedBox(height: 16),
                      Text(
                        isDebouncing.value ? 'Preparing search...' : 'Searching Quran...',
                        style: TextStyle(color: colorScheme.onBackground),
                      ),
                    ],
                  ),
                );
              }
              
              if (searchController.hasError.value) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: colorScheme.error),
                      const SizedBox(height: 16),
                      Text(
                        searchController.errorMessage.value,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.error),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          if (searchController.searchQuery.value.isNotEmpty) {
                            searchController.searchAyahs(searchController.searchQuery.value);
                          }
                        },
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              if (searchController.searchQuery.value.isEmpty) {
                return _buildSearchPlaceholder(context);
              }
              
              if (!searchController.hasResults.value) {
                return _buildNoResultsView(context);
              }
              
              return _buildSearchResults(context);
            }),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLanguageChip(String label, bool isSelected, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        onTap();
        // Re-search with new filters if we have a query
        if (searchController.searchQuery.value.isNotEmpty) {
          searchController.searchAyahs(searchController.searchQuery.value);
        }
      },
      backgroundColor: colorScheme.surface,
      selectedColor: colorScheme.primaryContainer,
      checkmarkColor: colorScheme.primary,
      labelStyle: TextStyle(
        color: isSelected ? colorScheme.primary : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
  
  Widget _buildSearchPlaceholder(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.search,
              size: 64,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            Text(
              'Search the entire Quran',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Find specific verses by searching for words or phrases in Arabic, English, or Bengali',
              style: TextStyle(
                fontSize: 16,
                color: colorScheme.onBackground.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Search Tips:',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildSearchTip('Use simple words like "mercy" or "light"'),
                  _buildSearchTip('Try different languages for more results'),
                  _buildSearchTip('Tap on results to see the verse in context'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchTip(String tip) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.arrow_right,
            size: 16,
            color: colorScheme.primary,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNoResultsView(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: colorScheme.primary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSuggestionItem(String text) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.tips_and_updates,
              size: 16,
              color: colorScheme.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: colorScheme.onBackground,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildSearchResults(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: searchController.searchResults.length,
      itemBuilder: (context, index) {
        final result = searchController.searchResults[index];
        return _buildAyahResultCard(context, result, index);
      },
    );
  }
  
  Widget _buildAyahResultCard(BuildContext context, app.AyahSearchResult result, int index) {
    final colorScheme = Theme.of(context).colorScheme;
    // Determine which translation to show based on detected language
    final String displayTranslationLanguage = _getDisplayLanguage();
    final bool isHighlighted = index % 2 == 0; // Alternate highlighting for better readability
    final String searchTerm = searchController.searchQuery.value.toLowerCase();
    
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      elevation: 1,
      color: isHighlighted ? colorScheme.surface : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isHighlighted ? colorScheme.primary.withOpacity(0.2) : Colors.transparent,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // Navigate to surah with specific ayah and detected language
          final Map<String, dynamic> arguments = {
            'scrollToAyah': result.ayah.number,
          };
          
          // Always pass the detected language, not just when it's not default
          if (detectedSearchLanguage.value != 'default') {
            arguments['tempTranslationLanguage'] = detectedSearchLanguage.value;
          }
          
          Get.toNamed(
            '/surah/${result.surahNumber}',
            arguments: arguments,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with surah info and actions
              Row(
                children: [
                  // Reference badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.bookmark, 
                          size: 14, 
                          color: colorScheme.primary
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${result.surahName} ${result.surahNumber}:${result.ayah.number}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  
                  // Context button - shows how to view in context
                  IconButton(
                    icon: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'View',
                          style: TextStyle(
                            fontSize: 12,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    tooltip: 'View in context',
                    constraints: const BoxConstraints(),
                    padding: EdgeInsets.zero,
                    onPressed: () {
                      // Apply same navigation logic as the card tap
                      final Map<String, dynamic> arguments = {
                        'scrollToAyah': result.ayah.number,
                      };
                      
                      // Always pass the detected language, not just when it's not default
                      if (detectedSearchLanguage.value != 'default') {
                        arguments['tempTranslationLanguage'] = detectedSearchLanguage.value;
                      }
                      
                      Get.toNamed(
                        '/surah/${result.surahNumber}',
                        arguments: arguments,
                      );
                    },
                  ),
                  
                  const SizedBox(width: 8),
                  
                  // Action menu
                  PopupMenuButton(
                    icon: Icon(
                      Icons.more_vert,
                      color: colorScheme.onSurfaceVariant,
                      size: 20,
                    ),
                    padding: EdgeInsets.zero,
                    tooltip: 'More options',
                    itemBuilder: (context) => [
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(
                              Icons.bookmark_outline,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text('Bookmark'),
                          ],
                        ),
                        onTap: () {
                          bookmarkController.toggleBookmark(
                            result.ayah,
                            result.surahNumber,
                            result.surahName,
                          );
                        },
                      ),
                      PopupMenuItem(
                        child: Row(
                          children: [
                            Icon(
                              Icons.share,
                              size: 18,
                              color: colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            const Text('Share'),
                          ],
                        ),
                        onTap: () {
                          ShareUtils.shareAyah(
                            result.ayah,
                            result.surahNumber,
                            result.surahName,
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
              
              // Translation text with highlighted search term
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildHighlightedText(
                  _getTranslationTextByLanguage(result, displayTranslationLanguage),
                  searchTerm,
                  TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: colorScheme.onBackground.withOpacity(0.9),
                  ),
                  TextStyle(
                    fontSize: 16,
                    height: 1.5,
                    color: colorScheme.onBackground,
                    backgroundColor: colorScheme.primary.withOpacity(0.2),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  // Helper method to highlight search terms in text
  Widget _buildHighlightedText(
    String text,
    String searchTerm,
    TextStyle normalStyle,
    TextStyle highlightStyle, {
    TextAlign? textAlign,
  }) {
    if (searchTerm.isEmpty) {
      return Text(
        text, 
        style: normalStyle,
        textAlign: textAlign,
      );
    }
    
    // Create a TextSpan with highlighted parts
    List<TextSpan> spans = [];
    final String lowercaseText = text.toLowerCase();
    int currentIndex = 0;
    
    while (true) {
      final int matchIndex = lowercaseText.indexOf(searchTerm, currentIndex);
      if (matchIndex == -1) {
        // No more matches, add the rest of the text
        if (currentIndex < text.length) {
          spans.add(TextSpan(
            text: text.substring(currentIndex),
            style: normalStyle,
          ));
        }
        break;
      }
      
      // Add text before match
      if (matchIndex > currentIndex) {
        spans.add(TextSpan(
          text: text.substring(currentIndex, matchIndex),
          style: normalStyle,
        ));
      }
      
      // Add highlighted text
      spans.add(TextSpan(
        text: text.substring(matchIndex, matchIndex + searchTerm.length),
        style: highlightStyle,
      ));
      
      // Move index past this match
      currentIndex = matchIndex + searchTerm.length;
    }
    
    return RichText(
      text: TextSpan(children: spans),
      textAlign: textAlign ?? TextAlign.left,
    );
  }
  
  // Helper method to detect search language
  void detectSearchLanguage(String searchText) {
    // Check if the search text contains any Bengali characters
    final bool hasBengaliChars = RegExp(r'[\u0980-\u09FF]').hasMatch(searchText);
    if (hasBengaliChars) {
      detectedSearchLanguage.value = 'bengali';
      // Ensure Bengali search is enabled when searching Bengali text
      if (!searchController.searchInBengali.value) {
        searchController.toggleBengaliSearch();
      }
      return;
    }
    
    // Otherwise, assume English
    detectedSearchLanguage.value = 'english';
    // Ensure English search is enabled when searching English text
    if (!searchController.searchInEnglish.value) {
      searchController.toggleEnglishSearch();
    }
  }
  
  // Helper method to get which translation to display based on the detected language
  String _getDisplayLanguage() {
    // Use the detected language for translations
    return detectedSearchLanguage.value == 'default' ? 
        themeController.translationLanguage.value : detectedSearchLanguage.value;
  }
  
  // Helper method to get translation text by language
  String _getTranslationTextByLanguage(app.AyahSearchResult result, String language) {
    switch (language) {
      case 'bengali':
        return result.ayah.bengali;
      case 'english':
        return result.ayah.english;
      default:
        return themeController.translationLanguage.value == 'bengali' ? 
            result.ayah.bengali : result.ayah.english;
    }
  }
} 