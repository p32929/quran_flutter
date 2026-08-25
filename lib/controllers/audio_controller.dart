import 'package:get/get.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:pref/pref.dart';
import '../utils/snackbar_utils.dart';

class ReciterInfo {
  final String id;
  final String name;
  final String shortName; // compact label for chips
  final String url;
  final String everyAyahDir; // everyayah.com per-ayah directory

  ReciterInfo({
    required this.id,
    required this.name,
    this.shortName = '',
    this.url = '',
    this.everyAyahDir = '',
  });

  String get displayShort => shortName.isNotEmpty ? shortName : name;
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
  // Ayah number of index 0 in the current playlist (e.g. 1 for a full-surah
  // playlist, or the range start for a memorization loop over a sub-range)
  int _playlistStartAyah = 1;

  // Curated reciter catalog, sourced + verified against everyayah.com's own
  // reciters.js listing (translation/non-Hafs riwayah folders excluded).
  // Every reciter has a complete set of per-ayah files on everyayah.com, so
  // all support the ayah-by-ayah playlist + glow. id == everyayah directory
  // (stable, unique). Kept sorted alphabetically by name.
  static final List<ReciterInfo> _reciterCatalog = [
    ReciterInfo(id: 'Abdul_Basit_Mujawwad_128kbps', name: 'Abdul Basit Abdus Samad (Mujawwad)', shortName: 'Abdul Basit (Mujawwad)', everyAyahDir: 'Abdul_Basit_Mujawwad_128kbps'),
    ReciterInfo(id: 'Abdul_Basit_Murattal_192kbps', name: 'Abdul Basit Abdus Samad (Murattal)', shortName: 'Abdul Basit (Murattal)', everyAyahDir: 'Abdul_Basit_Murattal_192kbps'),
    ReciterInfo(id: 'Abdullah_Matroud_128kbps', name: 'Abdullah Al-Matroud', shortName: 'Al-Matroud', everyAyahDir: 'Abdullah_Matroud_128kbps'),
    ReciterInfo(id: 'Abdullaah_3awwaad_Al-Juhaynee_128kbps', name: 'Abdullah Awad Al-Juhani', shortName: 'Al-Juhani', everyAyahDir: 'Abdullaah_3awwaad_Al-Juhaynee_128kbps'),
    ReciterInfo(id: 'Abdullah_Basfar_192kbps', name: 'Abdullah Basfar', shortName: 'Basfar', everyAyahDir: 'Abdullah_Basfar_192kbps'),
    ReciterInfo(id: 'Abdurrahmaan_As-Sudais_192kbps', name: 'Abdurrahman As-Sudais', shortName: 'As-Sudais', everyAyahDir: 'Abdurrahmaan_As-Sudais_192kbps'),
    ReciterInfo(id: 'Abu_Bakr_Ash-Shaatree_128kbps', name: 'Abu Bakr Al-Shatri', shortName: 'Al-Shatri', everyAyahDir: 'Abu_Bakr_Ash-Shaatree_128kbps'),
    ReciterInfo(id: 'ahmed_ibn_ali_al_ajamy_128kbps', name: 'Ahmed Al-Ajamy', shortName: 'Al-Ajamy', everyAyahDir: 'ahmed_ibn_ali_al_ajamy_128kbps'),
    ReciterInfo(id: 'Ahmed_Neana_128kbps', name: 'Ahmed Neana', shortName: 'Neana', everyAyahDir: 'Ahmed_Neana_128kbps'),
    ReciterInfo(id: 'Akram_AlAlaqimy_128kbps', name: 'Akram Al-Alaqimy', shortName: 'Al-Alaqimy', everyAyahDir: 'Akram_AlAlaqimy_128kbps'),
    ReciterInfo(id: 'Hudhaify_128kbps', name: 'Ali Al-Hudhaify', shortName: 'Al-Hudhaify', everyAyahDir: 'Hudhaify_128kbps'),
    ReciterInfo(id: 'Ali_Hajjaj_AlSuesy_128kbps', name: 'Ali Hajjaj Al-Suesy', shortName: 'Al-Suesy', everyAyahDir: 'Ali_Hajjaj_AlSuesy_128kbps'),
    ReciterInfo(id: 'Ali_Jaber_64kbps', name: 'Ali Jaber', shortName: 'Ali Jaber', everyAyahDir: 'Ali_Jaber_64kbps'),
    ReciterInfo(id: 'Ayman_Sowaid_64kbps', name: 'Ayman Sowaid', shortName: 'Sowaid', everyAyahDir: 'Ayman_Sowaid_64kbps'),
    ReciterInfo(id: 'aziz_alili_128kbps', name: 'Aziz Alili', shortName: 'Alili', everyAyahDir: 'aziz_alili_128kbps'),
    ReciterInfo(id: 'Fares_Abbad_64kbps', name: 'Fares Abbad', shortName: 'Fares Abbad', everyAyahDir: 'Fares_Abbad_64kbps'),
    ReciterInfo(id: 'Hani_Rifai_192kbps', name: 'Hani Ar-Rifai', shortName: 'Ar-Rifai', everyAyahDir: 'Hani_Rifai_192kbps'),
    ReciterInfo(id: 'Karim_Mansoori_40kbps', name: 'Karim Mansoori', shortName: 'Mansoori', everyAyahDir: 'Karim_Mansoori_40kbps'),
    ReciterInfo(id: 'Khaalid_Abdullaah_al-Qahtaanee_192kbps', name: 'Khalid Abdullah Al-Qahtani', shortName: 'Al-Qahtani', everyAyahDir: 'Khaalid_Abdullaah_al-Qahtaanee_192kbps'),
    ReciterInfo(id: 'khalefa_al_tunaiji_64kbps', name: 'Khalifa Al-Tunaiji', shortName: 'Al-Tunaiji', everyAyahDir: 'khalefa_al_tunaiji_64kbps'),
    ReciterInfo(id: 'MaherAlMuaiqly128kbps', name: 'Maher Al-Muaiqly', shortName: 'Al-Muaiqly', everyAyahDir: 'MaherAlMuaiqly128kbps'),
    ReciterInfo(id: 'mahmoud_ali_al_banna_32kbps', name: 'Mahmoud Ali Al-Banna', shortName: 'Al-Banna', everyAyahDir: 'mahmoud_ali_al_banna_32kbps'),
    ReciterInfo(id: 'Husary_128kbps', name: 'Mahmoud Khalil Al-Husary', shortName: 'Al-Husary', everyAyahDir: 'Husary_128kbps'),
    ReciterInfo(id: 'Husary_Muallim_128kbps', name: 'Mahmoud Khalil Al-Husary (Muallim)', shortName: 'Al-Husary (Muallim)', everyAyahDir: 'Husary_Muallim_128kbps'),
    ReciterInfo(id: 'Husary_128kbps_Mujawwad', name: 'Mahmoud Khalil Al-Husary (Mujawwad)', shortName: 'Al-Husary (Mujawwad)', everyAyahDir: 'Husary_128kbps_Mujawwad'),
    ReciterInfo(id: 'Alafasy_128kbps', name: 'Mishary Rashid Al-Afasy', shortName: 'Al-Afasy', everyAyahDir: 'Alafasy_128kbps'),
    ReciterInfo(id: 'Minshawy_Mujawwad_192kbps', name: 'Mohamed Al-Minshawi (Mujawwad)', shortName: 'Al-Minshawi (Mujawwad)', everyAyahDir: 'Minshawy_Mujawwad_192kbps'),
    ReciterInfo(id: 'Minshawy_Murattal_128kbps', name: 'Mohamed Al-Minshawi (Murattal)', shortName: 'Al-Minshawi (Murattal)', everyAyahDir: 'Minshawy_Murattal_128kbps'),
    ReciterInfo(id: 'Mohammad_al_Tablaway_128kbps', name: 'Mohammad Al-Tablawi', shortName: 'Al-Tablawi', everyAyahDir: 'Mohammad_al_Tablaway_128kbps'),
    ReciterInfo(id: 'Muhammad_AbdulKareem_128kbps', name: 'Muhammad Abdul Kareem', shortName: 'Abdul Kareem', everyAyahDir: 'Muhammad_AbdulKareem_128kbps'),
    ReciterInfo(id: 'Muhammad_Ayyoub_128kbps', name: 'Muhammad Ayyoub', shortName: 'Ayyoub', everyAyahDir: 'Muhammad_Ayyoub_128kbps'),
    ReciterInfo(id: 'Muhammad_Jibreel_128kbps', name: 'Muhammad Jibreel', shortName: 'Jibreel', everyAyahDir: 'Muhammad_Jibreel_128kbps'),
    ReciterInfo(id: 'Muhsin_Al_Qasim_192kbps', name: 'Muhsin Al-Qasim', shortName: 'Al-Qasim', everyAyahDir: 'Muhsin_Al_Qasim_192kbps'),
    ReciterInfo(id: 'Mustafa_Ismail_48kbps', name: 'Mustafa Ismail', shortName: 'Mustafa Ismail', everyAyahDir: 'Mustafa_Ismail_48kbps'),
    ReciterInfo(id: 'Nasser_Alqatami_128kbps', name: 'Nasser Al-Qatami', shortName: 'Al-Qatami', everyAyahDir: 'Nasser_Alqatami_128kbps'),
    ReciterInfo(id: 'Ghamadi_40kbps', name: 'Saad Al-Ghamdi', shortName: 'Al-Ghamdi', everyAyahDir: 'Ghamadi_40kbps'),
    ReciterInfo(id: 'Sahl_Yassin_128kbps', name: 'Sahl Yassin', shortName: 'Sahl Yassin', everyAyahDir: 'Sahl_Yassin_128kbps'),
    ReciterInfo(id: 'Salaah_AbdulRahman_Bukhatir_128kbps', name: 'Salah Abdul Rahman Bukhatir', shortName: 'Bukhatir', everyAyahDir: 'Salaah_AbdulRahman_Bukhatir_128kbps'),
    ReciterInfo(id: 'Salah_Al_Budair_128kbps', name: 'Salah Al-Budair', shortName: 'Al-Budair', everyAyahDir: 'Salah_Al_Budair_128kbps'),
    ReciterInfo(id: 'Saood_ash-Shuraym_128kbps', name: 'Saud Al-Shuraim', shortName: 'Al-Shuraim', everyAyahDir: 'Saood_ash-Shuraym_128kbps'),
    ReciterInfo(id: 'Yaser_Salamah_128kbps', name: 'Yaser Salamah', shortName: 'Salamah', everyAyahDir: 'Yaser_Salamah_128kbps'),
    ReciterInfo(id: 'Yasser_Ad-Dussary_128kbps', name: 'Yasser Al-Dosari', shortName: 'Al-Dosari', everyAyahDir: 'Yasser_Ad-Dussary_128kbps'),
  ];
  static const String _defaultEveryAyahDir = 'Alafasy_128kbps';
  static const String _defaultReciterId = 'Alafasy_128kbps';
  static const String _defaultReciterPrefKey = 'default_reciter';

  // Persisted preferred reciter, used when tapping the header play button
  // and for per-ayah playback.
  final RxString defaultReciterId = _defaultReciterId.obs;

  String? _dirForReciterId(String reciterId) {
    for (final r in _reciterCatalog) {
      if (r.id == reciterId) return r.everyAyahDir;
    }
    return null;
  }
  
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
    // Reciter list is a fixed catalog; make it available immediately,
    // alphabetically by name.
    reciters.assignAll(_reciterCatalog);
    reciters.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    // Restore the saved default reciter, if any
    try {
      if (Get.isRegistered<BasePrefService>()) {
        final saved = Get.find<BasePrefService>().get<String>(_defaultReciterPrefKey);
        if (saved != null && _dirForReciterId(saved) != null) {
          defaultReciterId.value = saved;
        }
      }
    } catch (_) {}
    // Delay audio initialization to prevent blocking app startup
    // This is especially important for web
    Future.delayed(Duration(milliseconds: 500), () {
      _initializeAudioPlayer();
    });
  }

  ReciterInfo get defaultReciter =>
      reciters.firstWhereOrNull((r) => r.id == defaultReciterId.value) ??
      _reciterCatalog.first;

  Future<void> setDefaultReciter(String reciterId) async {
    if (_dirForReciterId(reciterId) == null) return;
    defaultReciterId.value = reciterId;
    try {
      if (Get.isRegistered<BasePrefService>()) {
        await Get.find<BasePrefService>().set(_defaultReciterPrefKey, reciterId);
      }
    } catch (_) {}
  }
  
  void _initializeAudioPlayer() {
    // Don't initialize again if already done
    if (_isInitialized) return;
    
    try {
      _audioPlayer = AudioPlayer();
      
      // Listen to player state changes.
      // Note: just_audio keeps `playing == true` after the last track
      // completes, so treat completed/idle as not playing — otherwise the
      // play/stop buttons stay stuck in the "playing" state.
      _audioPlayer!.playerStateStream.listen((state) {
        isPlaying.value = state.playing &&
            state.processingState != ProcessingState.completed &&
            state.processingState != ProcessingState.idle;
      });

      // Handle playback completion
      _audioPlayer!.processingStateStream.listen((state) {
        if (state == ProcessingState.completed) {
          isPlaying.value = false;
          // Clear playback state so the glow turns off and the surah play
          // button resets when playback finishes
          _playlistSurah = null;
          currentAyahSurah.value = 0;
          currentAyahNumber.value = 0;
          currentSurahId.value = '';
          // Reset the player so the next play starts fresh instead of
          // resuming a completed session
          _audioPlayer!.stop();
        }
      });

      // Track which ayah is sounding during ayah-by-ayah surah playback
      _audioPlayer!.currentIndexStream.listen((index) {
        if (index != null && _playlistSurah != null) {
          currentAyahSurah.value = _playlistSurah!;
          currentAyahNumber.value = _playlistStartAyah + index;
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
    // The reciter list is now a curated everyayah.com catalog (all support
    // per-ayah playback + glow), independent of the per-surah audio data.
    if (reciters.length != _reciterCatalog.length) {
      reciters.assignAll(_reciterCatalog);
      reciters.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    }
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
      
      // Make sure the player exists (setAudioSource/setUrl below replaces
      // whatever source is currently loaded, so an explicit stop() first is
      // unnecessary — it only adds a redundant native player deactivate
      // +reactivate round trip, which is slower now that it's routed
      // through the just_audio_background isolate/foreground service)
      if (_audioPlayer == null) {
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

      // Load the audio as an ayah-by-ayah playlist from everyayah.com so the
      // UI can highlight the exact ayah being recited. Falls back to the
      // reciter's single full-surah file if no per-ayah directory is set.
      final everyAyahDir = reciter.everyAyahDir.isNotEmpty
          ? reciter.everyAyahDir
          : _dirForReciterId(reciter.id);
      final surahNumber = int.tryParse(surahId);
      // A previous memorization loop may have left looping enabled
      unawaited(_audioPlayer!.setLoopMode(LoopMode.off));

      if (everyAyahDir != null && surahNumber != null && totalAyah != null && totalAyah > 0) {
        print('Loading ayah-by-ayah playlist for surah $surahId ($everyAyahDir)');
        _playlistSurah = surahNumber;
        _playlistStartAyah = 1;
        final playlist = ConcatenatingAudioSource(
          children: [
            for (int a = 1; a <= totalAyah; a++)
              AudioSource.uri(
                Uri.parse(_everyAyahUrl(everyAyahDir, surahNumber, a)),
                tag: _mediaItem(surahNumber, a, album: reciter.displayShort),
              ),
          ],
        );
        await _audioPlayer!.setAudioSource(playlist);
      } else {
        print('Loading audio from URL: ${reciter.url}');
        _playlistSurah = null;
        await _audioPlayer!.setUrl(
          reciter.url,
          tag: MediaItem(id: surahId, album: reciter.displayShort, title: 'Surah $surahId'),
        );
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
      await _audioPlayer!.setLoopMode(LoopMode.off);
      await _audioPlayer!.stop();
      isPlaying.value = false;
      _playlistSurah = null;
      _playlistStartAyah = 1;
      currentAyahSurah.value = 0;
      currentAyahNumber.value = 0;
    } catch (e) {
      print('Error stopping audio: $e');
    }
  }

  // ---- Memorization loop (offline, downloaded ayah files) ----

  // Plays a range of already-downloaded local ayah files on a continuous
  // loop, so the user can listen to the same passage repeatedly to
  // memorize it. `localFilePaths` must be ordered ayah-by-ayah starting at
  // `startAyah`.
  Future<void> playLocalRangeLooping({
    required int surahNumber,
    required int startAyah,
    required List<String> localFilePaths,
  }) async {
    if (!_isInitialized) {
      _initializeAudioPlayer();
      await Future.delayed(const Duration(milliseconds: 300));
    }

    if (_audioPlayer == null) {
      SnackbarUtils.show('Error', 'Failed to initialize audio player.');
      return;
    }

    if (localFilePaths.isEmpty) return;

    try {
      isLoading.value = true;

      // Local-loop playback takes over from any streamed playback
      // (setAudioSource below replaces the current source directly, so an
      // explicit stop() first is unnecessary)
      currentSurahId.value = '';
      _playlistSurah = surahNumber;
      _playlistStartAyah = startAyah;
      currentAyahSurah.value = 0;
      currentAyahNumber.value = 0;

      final playlist = ConcatenatingAudioSource(
        children: [
          for (int i = 0; i < localFilePaths.length; i++)
            AudioSource.uri(
              Uri.file(localFilePaths[i]),
              tag: _mediaItem(surahNumber, startAyah + i, album: 'Memorizing'),
            ),
        ],
      );
      await _audioPlayer!.setAudioSource(playlist);
      await _audioPlayer!.setLoopMode(LoopMode.all);
      await _audioPlayer!.play();

      isLoading.value = false;
    } catch (e) {
      isLoading.value = false;
      print('Error playing local memorization loop: $e');
      SnackbarUtils.show('Error', 'Failed to play downloaded audio.');
    }
  }

  Future<void> stopMemorizationLoop() async {
    if (_audioPlayer == null) return;

    try {
      await _audioPlayer!.setLoopMode(LoopMode.off);
      await _audioPlayer!.stop();
      isPlaying.value = false;
      _playlistSurah = null;
      _playlistStartAyah = 1;
      currentAyahSurah.value = 0;
      currentAyahNumber.value = 0;
    } catch (e) {
      print('Error stopping memorization loop: $e');
    }
  }

  // ---- Per-ayah playback (everyayah.com) ----

  String _everyAyahUrl(String reciterDir, int surahNumber, int ayahNumber) {
    final s = surahNumber.toString().padLeft(3, '0');
    final a = ayahNumber.toString().padLeft(3, '0');
    return 'https://everyayah.com/data/$reciterDir/$s$a.mp3';
  }

  // Metadata shown in the lock-screen/notification media controls
  // (just_audio_background). Also required so headset media-button events
  // have a queue item to act on.
  MediaItem _mediaItem(int surahNumber, int ayahNumber, {String? album}) {
    return MediaItem(
      id: '$surahNumber:$ayahNumber',
      album: album ?? 'Surah $surahNumber',
      title: 'Ayah $ayahNumber',
    );
  }

  String _ayahAudioUrl(int surahNumber, int ayahNumber) {
    // Prefer the reciter of the active surah playback, else the default reciter
    final dir = _dirForReciterId(currentReciterId.value) ??
        _dirForReciterId(defaultReciterId.value) ??
        _defaultEveryAyahDir;
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
      _playlistStartAyah = 1;
      currentSurahId.value = '';

      currentAyahSurah.value = surahNumber;
      currentAyahNumber.value = ayahNumber;
      isAyahLoading.value = true;

      final reciterName = reciters.firstWhereOrNull((r) => r.id == currentReciterId.value)?.displayShort ??
          reciters.firstWhereOrNull((r) => r.id == defaultReciterId.value)?.displayShort;

      // setUrl() already replaces whatever source is currently loaded, so an
      // explicit stop() first is redundant — it was forcing an extra
      // deactivate+reactivate round trip through the native player (now
      // routed through the just_audio_background isolate/foreground
      // service), which is what was making every tap feel slow.
      unawaited(_audioPlayer!.setLoopMode(LoopMode.off));
      await _audioPlayer!.setUrl(
        _ayahAudioUrl(surahNumber, ayahNumber),
        tag: _mediaItem(surahNumber, ayahNumber, album: reciterName),
      );

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