import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/audio_controller.dart';
import '../../models/surah_model.dart';

class AudioBottomSheet extends StatefulWidget {
  final Surah surah;
  
  const AudioBottomSheet({
    Key? key,
    required this.surah,
  }) : super(key: key);

  @override
  State<AudioBottomSheet> createState() => _AudioBottomSheetState();
}

class _AudioBottomSheetState extends State<AudioBottomSheet> {
  late final AudioController audioController;
  final RxBool isReciterLoading = false.obs;
  final RxString loadingReciterId = ''.obs;
  
  @override
  void initState() {
    super.initState();
    audioController = Get.find<AudioController>();
    
    // Only listen to playing state to close sheet when audio starts playing
    ever(audioController.isPlaying, (bool isPlaying) {
      if (isPlaying && isReciterLoading.value) {
        // When audio starts playing and we were loading a reciter,
        // close the bottom sheet
        isReciterLoading.value = false;
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
    
    // Listen to errors or completion of loading without playing
    ever(audioController.isLoading, (bool isLoading) {
      // Only handle the case when loading stops but audio isn't playing
      if (!isLoading && isReciterLoading.value && !audioController.isPlaying.value) {
        // This might be an error case, but don't close the sheet
        // just reset the loading state for the selected reciter
        isReciterLoading.value = false;
        loadingReciterId.value = '';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    
    return Container(
      padding: EdgeInsets.only(
        top: 16,
        bottom: MediaQuery.of(context).padding.bottom + 16,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Listen to ${widget.surah.name}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: colorScheme.onBackground,
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Subtitle and loading indicator
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Obx(() => Text(
                  isReciterLoading.value 
                    ? 'Loading audio, please wait...' 
                    : 'Select a reciter',
                  style: TextStyle(
                    fontSize: 14,
                    color: isReciterLoading.value 
                      ? colorScheme.primary
                      : colorScheme.onBackground.withOpacity(0.7),
                    fontWeight: isReciterLoading.value 
                      ? FontWeight.bold 
                      : FontWeight.normal,
                  ),
                )),
                const SizedBox(width: 10),
                // Global loading indicator
                Obx(() => isReciterLoading.value 
                  ? SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: colorScheme.primary,
                      ),
                    )
                  : const SizedBox.shrink()
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Divider
          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
          
          // Reciter list
          Obx(() {
            if (audioController.reciters.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    'No reciters available',
                    style: TextStyle(
                      color: colorScheme.onBackground.withOpacity(0.7),
                    ),
                  ),
                ),
              );
            }
            
            return ListView.separated(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: audioController.reciters.length,
              separatorBuilder: (context, index) => const Divider(height: 1, indent: 64),
              itemBuilder: (context, index) {
                final reciter = audioController.reciters[index];
                final isSelected = audioController.isCurrentlyPlaying(widget.surah.number.toString()) && 
                               audioController.currentReciterId.value == reciter.id;
                final isLoading = isReciterLoading.value && loadingReciterId.value == reciter.id;
                
                return Material(
                  color: isLoading 
                    ? colorScheme.primaryContainer.withOpacity(0.3)
                    : Colors.transparent,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: isLoading 
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: colorScheme.primary,
                              ),
                            )
                          : Icon(
                              isSelected ? Icons.pause : Icons.play_arrow,
                              color: colorScheme.primary,
                              size: 22,
                            ),
                      ),
                    ),
                    title: Text(
                      reciter.name,
                      style: TextStyle(
                        fontWeight: isLoading ? FontWeight.bold : FontWeight.w500,
                        color: colorScheme.onBackground,
                      ),
                    ),
                    subtitle: isLoading 
                      ? Row(
                          children: [
                            Text(
                              'Loading audio...',
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: colorScheme.primary,
                              ),
                            ),
                          ],
                        )
                      : null,
                    onTap: isLoading ? null : () {
                      // Set loading state for this specific reciter
                      isReciterLoading.value = true;
                      loadingReciterId.value = reciter.id;
                      
                      // Play the audio
                      audioController.playAudio(
                        widget.surah.number.toString(),
                        reciter,
                      );
                    },
                  ),
                );
              },
            );
          }),
        ],
      ),
    );
  }
} 