import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;

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
  AudioPlayer? _audioPlayer;
  bool _isInitialized = false;
  
  final RxBool isPlaying = false.obs;
  final RxBool isLoading = false.obs;
  final RxString currentSurahId = ''.obs;
  final RxString currentReciterId = ''.obs;
  final RxList<ReciterInfo> reciters = <ReciterInfo>[].obs;
  
  // Track if we're in web mode with error
  final RxBool hasWebAudioError = false.obs;
  
  AudioPlayer get audioPlayer {
    if (_audioPlayer == null) {
      _initializeAudioPlayer();
    }
    return _audioPlayer!;
  }
  
  @override
  void onInit() {
    super.onInit();
    // Delay audio initialization to prevent blocking app startup
    // This is especially important for web
    Future.delayed(Duration(milliseconds: 500), () {
      _initializeAudioPlayer();
    });
  }
  
  void _initializeAudioPlayer() {
    // Don't initialize again if already done
    if (_isInitialized) return;
    
    try {
      _audioPlayer = AudioPlayer();
      
      // Listen to player state changes
      _audioPlayer!.playerStateStream.listen((state) {
        if (state.playing) {
          isPlaying.value = true;
        } else {
          isPlaying.value = false;
        }
      });
      
      // Handle playback completion
      _audioPlayer!.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          isPlaying.value = false;
        }
      });
      
      _isInitialized = true;
      hasWebAudioError.value = false;
      print('Audio player initialized successfully');
    } catch (e) {
      print('Error initializing audio player: $e');
      // Mark that we have a web audio error
      if (kIsWeb) {
        hasWebAudioError.value = true;
      }
    }
  }
  
  @override
  void onClose() {
    if (_audioPlayer != null) {
      _audioPlayer!.dispose();
    }
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
    // Ensure the audio player is initialized before proceeding
    if (!_isInitialized) {
      _initializeAudioPlayer();
      await Future.delayed(Duration(milliseconds: 300)); // Give time to initialize
    }
    
    // If we have a web audio error, show a message and return
    if (hasWebAudioError.value) {
      Get.snackbar(
        'Audio Not Available',
        'Audio playback is not supported in this browser or environment.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }
    
    try {
      // If already playing the same audio, toggle pause/play
      if (currentSurahId.value == surahId && 
          currentReciterId.value == reciter.id && 
          _audioPlayer != null &&
          _audioPlayer!.processingState != ProcessingState.idle) {
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
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      } else {
        _initializeAudioPlayer();
      }
      
      // If we still don't have an audio player, show error and return
      if (_audioPlayer == null) {
        isLoading.value = false;
        Get.snackbar(
          'Error',
          'Failed to initialize audio player.',
          snackPosition: SnackPosition.BOTTOM,
        );
        return;
      }
      
      // Add a small artificial delay to ensure the loading UI is visible
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Load the audio
      print('Loading audio from URL: ${reciter.url}');
      await _audioPlayer!.setUrl(reciter.url);
      
      // Setup a listener for when playback actually starts 
      final completer = Completer<void>();
      bool hasCompleted = false;
      
      late StreamSubscription subscription;
      subscription = _audioPlayer!.playerStateStream.listen((state) {
        if (state.playing && !hasCompleted) {
          hasCompleted = true;
          completer.complete();
          subscription.cancel();
        }
      });
      
      // Start playing
      await _audioPlayer!.play();
      
      // Wait for playback to actually start or timeout after 10 seconds
      await Future.any([
        completer.future,
        Future.delayed(const Duration(seconds: 10)).then((_) {
          if (!hasCompleted) {
            hasCompleted = true;
            completer.complete();
          }
        })
      ]);
      
      // Give a brief moment for the UI to update before closing
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Only mark loading as complete after playback starts or times out
      isLoading.value = false;
    } catch (e) {
      // Make sure to clear loading state even if there's an error
      isLoading.value = false;
      print('Error playing audio: $e');
      
      // If on web and we get an error, mark as web audio error
      if (kIsWeb) {
        hasWebAudioError.value = true;
      }
      
      Get.snackbar(
        'Error',
        kIsWeb 
            ? 'Audio playback is not supported in this browser environment.'
            : 'Failed to play audio. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }
  
  Future<void> stopAudio() async {
    if (_audioPlayer == null) return;
    
    try {
      await _audioPlayer!.stop();
      isPlaying.value = false;
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }
  
  Future<void> pauseAudio() async {
    if (_audioPlayer == null) return;
    
    try {
      await _audioPlayer!.pause();
      isPlaying.value = false;
    } catch (e) {
      print('Error pausing audio: $e');
    }
  }
  
  Future<void> resumeAudio() async {
    if (_audioPlayer == null) return;
    
    try {
      await _audioPlayer!.play();
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