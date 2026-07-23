import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../utils/snackbar_utils.dart';

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

  // Per-ayah playback state (0 = none)
  final RxInt currentAyahSurah = 0.obs;
  final RxInt currentAyahNumber = 0.obs;
  final RxBool isAyahLoading = false.obs;

  // When surah playback runs as an ayah-by-ayah playlist, this holds the
  // surah number so the currentIndexStream listener can track which ayah
  // is sounding (null = not in playlist mode)
  int? _playlistSurah;

  // Map of the app's reciter ids to everyayah.com per-ayah directories
  static const Map<String, String> _everyAyahDirs = {
    '1': 'Alafasy_128kbps', // Mishary Rashid Al-Afasy
    '2': 'Abu_Bakr_Ash-Shaatree_128kbps', // Abu Bakr Al-Shatri
    '3': 'Nasser_Alqatami_128kbps', // Nasser Al-Qatami
    '4': 'Yasser_Ad-Dussary_128kbps', // Yasser Al-Dosari
  };
  static const String _defaultEveryAyahDir = 'Alafasy_128kbps';
  
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
          // Clear per-ayah state so the glow turns off when playback finishes
          _playlistSurah = null;
          currentAyahSurah.value = 0;
          currentAyahNumber.value = 0;
        }
      });

      // Track which ayah is sounding during ayah-by-ayah surah playback
      _audioPlayer!.currentIndexStream.listen((index) {
        if (index != null && _playlistSurah != null) {
          currentAyahSurah.value = _playlistSurah!;
          currentAyahNumber.value = index + 1;
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

  Future<void> playAudio(String surahId, ReciterInfo reciter, {int? totalAyah}) async {
    // Ensure the audio player is initialized before proceeding
    if (!_isInitialized) {
      _initializeAudioPlayer();
      await Future.delayed(Duration(milliseconds: 300)); // Give time to initialize
    }
    
    // If we have a web audio error, show a message and return
    if (hasWebAudioError.value) {
      SnackbarUtils.show(
        'Audio Not Available',
        'Audio playback is not supported in this browser or environment.',
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

      // Surah playback takes over from any per-ayah playback
      currentAyahSurah.value = 0;
      currentAyahNumber.value = 0;
      
      // Stop any currently playing audio
      if (_audioPlayer != null) {
        await _audioPlayer!.stop();
      } else {
        _initializeAudioPlayer();
      }
      
      // If we still don't have an audio player, show error and return
      if (_audioPlayer == null) {
        isLoading.value = false;
        SnackbarUtils.show(
          'Error',
          'Failed to initialize audio player.',
        );
        return;
      }
      
      // Add a small artificial delay to ensure the loading UI is visible
      await Future.delayed(const Duration(milliseconds: 500));

      // Load the audio.
      // Preferred: ayah-by-ayah playlist from everyayah.com so the UI can
      // highlight the exact ayah being recited. Falls back to the single
      // full-surah file when the reciter has no per-ayah source mapping.
      final everyAyahDir = _everyAyahDirs[reciter.id];
      final surahNumber = int.tryParse(surahId);
      if (everyAyahDir != null && surahNumber != null && totalAyah != null && totalAyah > 0) {
        print('Loading ayah-by-ayah playlist for surah $surahId ($everyAyahDir)');
        _playlistSurah = surahNumber;
        final playlist = ConcatenatingAudioSource(
          children: [
            for (int a = 1; a <= totalAyah; a++)
              AudioSource.uri(Uri.parse(_everyAyahUrl(everyAyahDir, surahNumber, a))),
          ],
        );
        await _audioPlayer!.setAudioSource(playlist);
      } else {
        print('Loading audio from URL: ${reciter.url}');
        _playlistSurah = null;
        await _audioPlayer!.setUrl(reciter.url);
      }
      
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
      
      SnackbarUtils.show(
        'Error',
        kIsWeb
            ? 'Audio playback is not supported in this browser environment.'
            : 'Failed to play audio. Please try again.',
      );
    }
  }
  
  Future<void> stopAudio() async {
    if (_audioPlayer == null) return;

    try {
      await _audioPlayer!.stop();
      isPlaying.value = false;
      _playlistSurah = null;
      currentAyahSurah.value = 0;
      currentAyahNumber.value = 0;
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  // ---- Per-ayah playback (everyayah.com) ----

  String _everyAyahUrl(String reciterDir, int surahNumber, int ayahNumber) {
    final s = surahNumber.toString().padLeft(3, '0');
    final a = ayahNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$reciterDir/$s$a.mp3';
  }

  String _ayahAudioUrl(int surahNumber, int ayahNumber) {
    // Use the last-selected reciter when it has a per-ayah source, else Alafasy
    final dir = _everyAyahDirs[currentReciterId.value] ?? _defaultEveryAyahDir;
    return _everyAyahUrl(dir, surahNumber, ayahNumber);
  }

  // Is this exact ayah the currently loaded one (playing or paused)?
  bool isAyahCurrent(int surahNumber, int ayahNumber) {
    return currentAyahSurah.value == surahNumber && currentAyahNumber.value == ayahNumber;
  }

  // Is this exact ayah actively playing right now?
  bool isAyahPlaying(int surahNumber, int ayahNumber) {
    return isAyahCurrent(surahNumber, ayahNumber) && isPlaying.value;
  }

  // Is this exact ayah currently buffering/loading?
  bool isAyahLoadingFor(int surahNumber, int ayahNumber) {
    return isAyahCurrent(surahNumber, ayahNumber) && isAyahLoading.value;
  }

  Future<void> playAyah(int surahNumber, int ayahNumber) async {
    // Ensure the audio player is initialized before proceeding
    if (!_isInitialized) {
      _initializeAudioPlayer();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (_audioPlayer == null) {
      SnackbarUtils.show('Error', 'Failed to initialize audio player.');
      return;
    }

    // Tapping the ayah that's already loaded toggles pause/resume
    if (isAyahCurrent(surahNumber, ayahNumber) &&
        _audioPlayer!.processingState != ProcessingState.idle &&
        !isAyahLoading.value) {
      if (isPlaying.value) {
        await _audioPlayer!.pause();
      } else {
        await _audioPlayer!.play();
      }
      return;
    }

    try {
      // Per-ayah playback takes over from any surah playback
      // (keep currentReciterId so single-ayah playback uses the same reciter)
      _playlistSurah = null;
      currentSurahId.value = '';

      currentAyahSurah.value = surahNumber;
      currentAyahNumber.value = ayahNumber;
      isAyahLoading.value = true;

      await _audioPlayer!.stop();
      await _audioPlayer!.setUrl(_ayahAudioUrl(surahNumber, ayahNumber));

      isAyahLoading.value = false;
      _audioPlayer!.play();
    } catch (e) {
      isAyahLoading.value = false;
      // Only clear state if another ayah hasn't been requested meanwhile
      if (isAyahCurrent(surahNumber, ayahNumber)) {
        currentAyahSurah.value = 0;
        currentAyahNumber.value = 0;
      }
      print('Error playing ayah audio: $e');
      SnackbarUtils.show('Error', 'Failed to play ayah audio. Please try again.');
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