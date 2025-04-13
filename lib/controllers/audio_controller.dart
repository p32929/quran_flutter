import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';

class ReciterInfo {
  final String id;
  final String name;
  final String url;

  ReciterInfo({
    required this.id,
    required this.name,
    required this.url,
  });
}

class AudioController extends GetxController {
  final AudioPlayer audioPlayer = AudioPlayer();
  
  final RxBool isPlaying = false.obs;
  final RxBool isLoading = false.obs;
  final RxString currentSurahId = ''.obs;
  final RxString currentReciterId = ''.obs;
  final RxList<ReciterInfo> reciters = <ReciterInfo>[].obs;
  
  @override
  void onInit() {
    super.onInit();
    
    // Listen to player state changes
    audioPlayer.playerStateStream.listen((state) {
      if (state.playing) {
        isPlaying.value = true;
      } else {
        isPlaying.value = false;
      }
    });
    
    // Handle playback completion
    audioPlayer.processingStateStream.listen((state) {
      if (state == ProcessingState.completed) {
        isPlaying.value = false;
      }
    });
  }
  
  @override
  void onClose() {
    audioPlayer.dispose();
    super.onClose();
  }
  
  Future<void> loadReciters(Map<String, dynamic> audioData) async {
    reciters.clear();
    
    // Convert audio data to reciter list
    audioData.forEach((key, value) {
      if (value is Map<String, dynamic>) {
        reciters.add(ReciterInfo(
          id: key,
          name: value['reciter'] ?? 'Unknown',
          url: value['originalUrl'] ?? '',
        ));
      }
    });
  }

  Future<void> playAudio(String surahId, ReciterInfo reciter) async {
    try {
      // If already playing the same audio, toggle pause/play
      if (currentSurahId.value == surahId && 
          currentReciterId.value == reciter.id && 
          audioPlayer.processingState != ProcessingState.idle) {
        if (isPlaying.value) {
          await pauseAudio();
        } else {
          await resumeAudio();
        }
        return;
      }
      
      // Set loading state before attempting to load new audio
      isLoading.value = true;
      currentSurahId.value = surahId;
      currentReciterId.value = reciter.id;
      
      // Stop any currently playing audio
      await audioPlayer.stop();
      
      // Load and play the new audio
      await audioPlayer.setUrl(reciter.url);
      await audioPlayer.play();
      
      // Clear loading state once audio has started playing
      isLoading.value = false;
    } catch (e) {
      // Make sure to clear loading state even if there's an error
      isLoading.value = false;
      print('Error playing audio: $e');
      Get.snackbar(
        'Error',
        'Failed to play audio. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  Future<void> stopAudio() async {
    try {
      await audioPlayer.stop();
      isPlaying.value = false;
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }
  
  Future<void> pauseAudio() async {
    try {
      await audioPlayer.pause();
      isPlaying.value = false;
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }
  
  Future<void> resumeAudio() async {
    try {
      await audioPlayer.play();
      isPlaying.value = true;
    } catch (e) {
      print('Error resuming audio: $e');
    }
  }
  
  // Check if this surah is currently playing
  bool isCurrentlyPlaying(String surahId) {
    return isPlaying.value && currentSurahId.value == surahId;
  }
  
  // Check if this surah is the current loaded audio (playing or paused)
  bool isCurrentAudio(String surahId) {
    return currentSurahId.value == surahId;
  }
} 