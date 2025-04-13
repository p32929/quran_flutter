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
    
    // Listen to loading changes to close the sheet when audio starts playing
    ever(audioController.isLoading, (bool isLoading) {
      if (!isLoading && isReciterLoading.value) {
        // When loading completes and we were previously loading a reciter,
        // close the bottom sheet
        isReciterLoading.value = false;
        if (mounted) {
          Navigator.of(context).pop();
        }
      }
    });
    
    // Also listen to playing state to close sheet when audio starts playing
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
          
          // Subtitle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Select a reciter',
              style: TextStyle(
                fontSize: 14,
                color: colorScheme.onBackground.withOpacity(0.7),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Divider
          Divider(height: 1, color: Colors.grey.withOpacity(0.2)),
          
          // Global loading indicator (when all reciters are loading)
          Obx(() {
            if (audioController.isLoading.value && !isReciterLoading.value) {
              return Container(
                padding: const EdgeInsets.all(20),
                child: const Center(
                  child: CircularProgressIndicator(),
                ),
              );
            }
            return const SizedBox.shrink();
          }),
          
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
            
            return ListView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              itemCount: audioController.reciters.length,
              itemBuilder: (context, index) {
                final reciter = audioController.reciters[index];
                final isSelected = audioController.isCurrentlyPlaying(widget.surah.number.toString()) && 
                               audioController.currentReciterId.value == reciter.id;
                final isLoading = isReciterLoading.value && loadingReciterId.value == reciter.id;
                
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: colorScheme.primaryContainer,
                    child: isLoading 
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colorScheme.primary,
                          ),
                        )
                      : Icon(
                          isSelected ? Icons.pause : Icons.play_arrow,
                          color: colorScheme.primary,
                        ),
                  ),
                  title: Text(
                    reciter.name,
                    style: TextStyle(
                      fontWeight: FontWeight.w500,
                      color: colorScheme.onBackground,
                    ),
                  ),
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
                );
              },
            );
          }),
        ],
      ),
    );
  }
} 