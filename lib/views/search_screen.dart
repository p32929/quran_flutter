import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/search_controller.dart' as app;
import '../controllers/bookmark_controller.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({Key? key}) : super(key: key);

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final app.SearchController searchController = Get.find<app.SearchController>();
  final BookmarkController bookmarkController = Get.find<BookmarkController>();
  final TextEditingController textController = TextEditingController();
  final FocusNode searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    textController.addListener(() {
      searchController.onQueryChanged(textController.text);
    });
  }
  
  @override
  void dispose() {
    textController.dispose();
    searchFocusNode.dispose();
    super.dispose();
  }

  void _performSearch(String query) {
    textController.text = query;
    searchController.performSearch(query);
    searchFocusNode.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colorScheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Search header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Search bar
                  Row(
                    children: [
                      IconButton(
          onPressed: () => Get.back(),
                        icon: const Icon(Icons.arrow_back_rounded),
                      ),
                      Expanded(
                  child: TextField(
                    controller: textController,
                    focusNode: searchFocusNode,
                    decoration: InputDecoration(
                            hintText: 'Search Quran...',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: colorScheme.surfaceVariant.withOpacity(0.5),
                            prefixIcon: const Icon(Icons.search_rounded),
                            suffixIcon: Obx(() => searchController.searchQuery.value.isNotEmpty
                              ? IconButton(
                            onPressed: () {
                              textController.clear();
                              searchController.clearSearch();
                                  },
                                  icon: const Icon(Icons.clear_rounded),
                                )
                              : const SizedBox.shrink()),
                          ),
                          onSubmitted: _performSearch,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Search filters
                  Obx(() => Row(
                    children: [
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                           child: Row(
                            children: [
                               _buildFilterChip(
                                 'English', 
                                 searchController.searchInEnglish.value,
                                 searchController.toggleEnglishSearch,
                               ),
                              const SizedBox(width: 8),
                               _buildFilterChip(
                                 'Bengali', 
                                 searchController.searchInBengali.value,
                                 searchController.toggleBengaliSearch,
                               ),
                             ],
                           ),
                        ),
                      ),
                    ],
                  )),
              ],
            ),
          ),
          
            // Content area
          Expanded(
            child: Obx(() {
                if (searchController.isSearching.value) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (!searchController.hasSearched.value) {
                  return _buildSuggestionsView();
                }
                
                return _buildResultsView();
            }),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildFilterChip(String label, bool isSelected, VoidCallback onTap) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary : colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
                    style: TextStyle(
            fontSize: 12,
            color: isSelected ? colorScheme.onPrimary : colorScheme.onSurfaceVariant,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
  
  Widget _buildSuggestionsView() {
    return ListView(
      padding: const EdgeInsets.all(16),
        children: [
        Text(
          'Search Suggestions',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        
        Obx(() {
          final suggestions = searchController.suggestions;
          
          return Column(
            children: suggestions.map((suggestion) {
              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                child: ListTile(
                  leading: _getIconForSuggestionType(suggestion.type),
                  title: Text(suggestion.text),
                  subtitle: suggestion.description != null 
                    ? Text(suggestion.description!) 
                    : null,
                  trailing: const Icon(Icons.north_west_rounded, size: 16),
                  onTap: () => _performSearch(suggestion.text),
                ),
              );
            }).toList(),
          );
        }),
        
        const SizedBox(height: 24),
        
        Text(
          'Quick Searches',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            'mercy', 'prayer', 'guidance', 'patience', 'Allah', 'believers',
            'দয়া', 'নামাজ', 'হেদায়েত', 'ধৈর্য', 'আল্লাহ', 'মুমিন'
          ].map((term) => GestureDetector(
              onTap: () => _performSearch(term),
              child: Chip(
                label: Text(term),
                backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              ),
            )).toList(),
        ),
      ],
    );
  }

  Widget _buildResultsView() {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Obx(() {
      final surahResults = searchController.surahResults;
      final ayahResults = searchController.ayahResults;
      
      if (surahResults.isEmpty && ayahResults.isEmpty) {
    return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                Icons.search_off_rounded,
              size: 64,
                color: colorScheme.onSurface.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
                'No results found',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'Try different keywords or check your spelling',
                style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
              ),
            ],
      ),
    );
  }
  
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (surahResults.isNotEmpty) ...[
            Text(
              'Surahs (${surahResults.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              color: colorScheme.primary,
            ),
          ),
            const SizedBox(height: 12),
            ...surahResults.map((result) => Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: colorScheme.primary.withOpacity(0.1),
            child: Text(
                    result.surah.number.toString(),
              style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.bold,
              ),
            ),
          ),
                title: Text(
                  result.surah.name,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                subtitle: Text('${result.surah.totalAyah} verses • ${result.surah.revelationPlace}'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => Get.toNamed('/surah/${result.surah.number}'),
              ),
            )).toList(),
            const SizedBox(height: 24),
          ],
          
          if (ayahResults.isNotEmpty) ...[
            Text(
              'Verses (${ayahResults.length})',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 12),
            ...ayahResults.map((result) => Card(
              margin: const EdgeInsets.only(bottom: 8),
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
                          '${result.surahName} ${result.surahNumber}:${result.ayah.number}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: colorScheme.primary,
                          ),
                        ),
                        ),
                        const Spacer(),
                        Text(
                          result.matchLanguage,
                          style: TextStyle(
                            fontSize: 10,
                            color: colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      result.matchedText,
                      style: const TextStyle(fontSize: 15, height: 1.6),
                    ),
                  ],
                ),
              ),
            )).toList(),
          ],
        ],
      );
    });
  }

  Icon _getIconForSuggestionType(String type) {
    final colorScheme = Theme.of(context).colorScheme;
    
    IconData iconData = switch (type) {
      'recent' => Icons.history_rounded,
      'popular' => Icons.trending_up_rounded,
      'topic' => Icons.topic_rounded,
      'surah' => Icons.book_rounded,
      _ => Icons.search_rounded,
    };
    
    Color iconColor = switch (type) {
      'recent' => colorScheme.secondary,
      'popular' => Colors.orange,
      'topic' => Colors.green,
      'surah' => colorScheme.primary,
      _ => colorScheme.onSurface,
    };
    
    return Icon(iconData, color: iconColor, size: 20);
  }
} 