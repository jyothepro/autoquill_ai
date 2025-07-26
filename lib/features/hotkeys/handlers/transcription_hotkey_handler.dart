import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hotkey_manager/hotkey_manager.dart';

import '../../../core/stats/stats_service.dart';

import 'package:autoquill_ai/features/recording/domain/repositories/recording_repository.dart';
import 'package:autoquill_ai/features/transcription/domain/repositories/transcription_repository.dart';
import '../../../features/transcription/services/smart_transcription_service.dart';
import '../../../features/transcription/services/phrase_replacement_service.dart';
import '../../../features/recording/data/platform/recording_overlay_platform.dart';
import '../services/clipboard_service.dart';
import '../../../core/utils/sound_player.dart';
import '../utils/hotkey_converter.dart';
import '../core/hotkey_handler.dart';
import 'package:autoquill_ai/core/services/whisper_kit_service.dart';
import '../../../core/services/volume_service.dart';

/// Handler for transcription hotkey functionality
class TranscriptionHotkeyHandler {
  // Flag to track if recording is in progress via hotkey
  static bool _isHotkeyRecordingActive = false;

  // Path to the recorded audio file when using hotkey
  static String? _hotkeyRecordedFilePath;

  // Repositories for direct access
  static RecordingRepository? _recordingRepository;
  static TranscriptionRepository? _transcriptionRepository;

  // Recording start time for tracking duration
  static DateTime? _recordingStartTime;

  // User notification tracking
  static bool _hasShownVolumeWarning = false;

  // Stats service for tracking stats
  static final StatsService _statsService = StatsService();

  /// Initialize the handler with necessary repositories
  static void initialize(RecordingRepository recordingRepository,
      TranscriptionRepository transcriptionRepository) {
    _recordingRepository = recordingRepository;
    _transcriptionRepository = transcriptionRepository;

    // Initialize stats service without blocking
    _ensureStatsInitialized();
  }

  /// Ensure stats box is initialized
  static void _ensureStatsInitialized() {
    // Run async initialization without awaiting to avoid blocking
    Future(() async {
      try {
        if (!Hive.isBoxOpen('stats')) {
          await Hive.openBox('stats');
        }
        await _statsService.init();
      } catch (e) {
        if (kDebugMode) {
          print('Error initializing stats in TranscriptionHotkeyHandler: $e');
        }
      }
    });
  }

  /// Handles the transcription hotkey press
  static void handleHotkey() async {
    if (_recordingRepository == null || _transcriptionRepository == null) {
      BotToast.showText(text: 'Recording system not initialized');
      return;
    }

    // Ensure settings box is open
    if (!Hive.isBoxOpen('settings')) {
      try {
        await Hive.openBox('settings');
      } catch (e) {
        if (kDebugMode) {
          print('Error opening settings box: $e');
        }
        BotToast.showText(text: 'Error accessing settings');
        return;
      }
    }

    // Ensure stats box is open
    if (!Hive.isBoxOpen('stats')) {
      try {
        await Hive.openBox('stats');
        await _statsService.init();
      } catch (e) {
        if (kDebugMode) {
          print('Error opening stats box: $e');
        }
        // Continue anyway, as this is not critical
      }
    }

    // Retrieve API key (may be null/empty)
    String apiKey = Hive.box('settings').get('groq_api_key') ?? '';

    // If API key is missing, verify if local transcription is ready
    if (apiKey.isEmpty) {
      final settingsBox = Hive.box('settings');
      final bool localEnabled = settingsBox.get('local_transcription_enabled',
          defaultValue: false) as bool;
      bool localReady = false;

      if (localEnabled) {
        final String selectedLocalModel = settingsBox
            .get('selected_local_model', defaultValue: 'base') as String;
        localReady =
            await WhisperKitService.isModelInitialized(selectedLocalModel);
      }

      if (!localReady) {
        BotToast.showText(
            text:
                'Recording requires a Groq API key or an initialized local transcription model.');
        return;
      }
    }

    // Check if this is our own recording or another mode's recording
    if (RecordingOverlayPlatform.isRecordingInProgress &&
        !_isHotkeyRecordingActive) {
      // Another mode is recording, don't interrupt it
      BotToast.showText(text: 'Another recording is in progress');
      return;
    }

    if (!_isHotkeyRecordingActive) {
      // Start recording directly using the repository
      try {
        // Register Esc key for cancellation
        await HotkeyHandler.registerEscKeyForRecording();

        // Play the start recording sound
        await SoundPlayer.playStartRecordingSound();

        // Check if auto-mute system is enabled and mute if so
        final autoMuteEnabled = Hive.box('settings')
            .get('auto_mute_system_enabled', defaultValue: false) as bool;
        if (autoMuteEnabled) {
          try {
            await VolumeService.instance.initialize();
            final success = await VolumeService.instance.muteVolume();
            if (success) {
              if (kDebugMode) {
                print('System volume muted for transcription recording');
              }
            } else {
              if (kDebugMode) {
                print(
                    'Volume control not available on this system - continuing without auto-mute');
              }
              // Only show this warning once per session to avoid spam
              if (!_hasShownVolumeWarning) {
                BotToast.showText(
                  text:
                      'Auto-mute not available on this system. Please manually mute media.',
                  duration: Duration(seconds: 4),
                );
                _hasShownVolumeWarning = true;
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print(
                  'Error with volume control: $e - continuing without auto-mute');
            }
          }
        }

        // Get the transcription hotkey for display
        final transcriptionHotkey =
            _getHotkeyDisplayString('transcription_hotkey');

        if (kDebugMode) {
          print('Transcription hotkey display string: "$transcriptionHotkey"');
        }

        // Show the overlay with the transcription mode and hotkey info
        await RecordingOverlayPlatform.showOverlayWithModeAndHotkeys(
            'Transcription', transcriptionHotkey, 'Esc');
        await _recordingRepository!.startRecording();
        _isHotkeyRecordingActive = true;
        _recordingStartTime = DateTime.now();
        BotToast.showText(text: 'Recording started');
      } catch (e) {
        if (kDebugMode) {
          print('Error starting recording: $e');
        }
        // Unregister Esc key if recording failed to start
        await HotkeyHandler.unregisterEscKeyForRecording();
        // Play error sound
        await SoundPlayer.playErrorSound();
        BotToast.showText(text: 'Failed to start recording: $e');
      }
    } else {
      // Stop recording and transcribe directly
      try {
        // Restore system volume if it was muted
        final autoMuteEnabled = Hive.box('settings')
            .get('auto_mute_system_enabled', defaultValue: false) as bool;
        if (autoMuteEnabled) {
          try {
            final success = await VolumeService.instance.restoreVolume();
            if (success) {
              if (kDebugMode) {
                print('System volume restored after transcription recording');
              }
            } else {
              if (kDebugMode) {
                print('Volume control not available - no restoration needed');
              }
            }
          } catch (e) {
            if (kDebugMode) {
              print('Error with volume control: $e - no restoration needed');
            }
          }
        }

        // Play the stop recording sound
        await SoundPlayer.playStopRecordingSound();

        // Stop recording
        _hotkeyRecordedFilePath = await _recordingRepository!.stopRecording();
        _isHotkeyRecordingActive = false;

        // Unregister Esc key since recording is done
        await HotkeyHandler.unregisterEscKeyForRecording();

        // Calculate recording duration
        if (_recordingStartTime != null) {
          try {
            final recordingDuration =
                DateTime.now().difference(_recordingStartTime!);
            await _statsService
                .addTranscriptionTime(recordingDuration.inSeconds);
          } catch (e) {
            if (kDebugMode) {
              print('Error updating transcription time: $e');
            }
            // Fallback to direct Hive update if the stats service fails
            try {
              if (Hive.isBoxOpen('stats')) {
                final box = Hive.box('stats');
                final currentTime =
                    box.get('transcription_time_seconds', defaultValue: 0);
                box.put(
                    'transcription_time_seconds',
                    currentTime +
                        DateTime.now()
                            .difference(_recordingStartTime!)
                            .inSeconds);
              }
            } catch (_) {}
          } finally {
            _recordingStartTime = null;
          }
        }

        BotToast.showText(text: 'Recording stopped, transcribing...');

        // Transcribe the audio
        await _transcribeAndCopyToClipboard(_hotkeyRecordedFilePath!, apiKey);
      } catch (e) {
        BotToast.showText(text: 'Error during recording or transcription: $e');
      }
    }
  }

  /// Transcribe audio and copy to clipboard without affecting UI
  static Future<void> _transcribeAndCopyToClipboard(
      String audioPath, String apiKey) async {
    try {
      // Update overlay to show we're processing the audio
      await RecordingOverlayPlatform.setProcessingAudio();

      // Track this as an ongoing operation
      HotkeyHandler.addOngoingOperation('transcription');

      // Start transcription request immediately
      final transcriptionFuture =
          _transcriptionRepository!.transcribeAudio(audioPath, apiKey);

      // Check settings while transcription is in progress
      final settingsBox = Hive.box('settings');
      final smartTranscriptionEnabled = settingsBox
          .get('smart_transcription_enabled', defaultValue: false) as bool;
      final Map<dynamic, dynamic>? storedReplacements =
          settingsBox.get('phrase_replacements');

      // Wait for transcription to complete
      final response = await transcriptionFuture;

      // Trim any leading/trailing whitespace from the transcription text
      var transcriptionText = response.text.trim();

      // Apply phrase replacements if available
      if (storedReplacements != null && storedReplacements.isNotEmpty) {
        final Map<String, String> phraseReplacements =
            Map<String, String>.from(storedReplacements);

        if (kDebugMode) {
          print('Applying phrase replacements: $phraseReplacements');
        }

        transcriptionText = PhraseReplacementService.applyReplacements(
            transcriptionText, phraseReplacements);

        if (kDebugMode) {
          print(
              'Transcription text after phrase replacements: "$transcriptionText"');
        }
      }

      if (kDebugMode) {
        print('Smart transcription enabled: $smartTranscriptionEnabled');
        print('Transcription text length: ${transcriptionText.length}');
        print(
            'Checking smart transcription condition: ${smartTranscriptionEnabled && transcriptionText.isNotEmpty}');
      }

      // If smart transcription is enabled, start it in parallel
      Future<String>? smartTranscriptionFuture;
      if (smartTranscriptionEnabled &&
          transcriptionText.isNotEmpty &&
          apiKey.isNotEmpty) {
        if (kDebugMode) {
          print('Starting smart transcription enhancement');
        }

        // Track smart transcription as an ongoing operation
        HotkeyHandler.addOngoingOperation('smart_transcription');

        smartTranscriptionFuture =
            SmartTranscriptionService.enhanceTranscription(
                transcriptionText, apiKey);
      }

      // If smart transcription is running, wait for it with timeout
      if (smartTranscriptionFuture != null) {
        try {
          transcriptionText = await smartTranscriptionFuture.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              if (kDebugMode) {
                print('Smart transcription timed out, using original text');
              }
              return transcriptionText;
            },
          );

          if (kDebugMode) {
            print('Smart transcription result: $transcriptionText');
          }
        } catch (e) {
          if (kDebugMode) {
            print('Smart transcription failed, using original text: $e');
          }
          // Continue with original transcription if smart transcription fails
        } finally {
          // Remove smart transcription from ongoing operations
          HotkeyHandler.removeOngoingOperation('smart_transcription');
        }
      }

      // Copy to clipboard - this will also update the overlay state to "Transcription copied"
      // and hide the overlay after pasting
      await ClipboardService.copyToClipboard(transcriptionText,
          mode: 'transcription');

      // Update word count in Hive using StatsService
      try {
        await _statsService.addTranscriptionWords(transcriptionText);
      } catch (e) {
        if (kDebugMode) {
          print('Error updating word count: $e');
        }
        // Fallback to direct Hive update if the stats service fails
        try {
          if (Hive.isBoxOpen('stats')) {
            final box = Hive.box('stats');
            final currentCount =
                box.get('transcription_words_count', defaultValue: 0);
            final wordCount = transcriptionText.split(RegExp(r'\s+')).length;
            box.put('transcription_words_count', currentCount + wordCount);
          }
        } catch (_) {}
      }

      // Remove transcription from ongoing operations
      HotkeyHandler.removeOngoingOperation('transcription');

      if (kDebugMode) {
        print('Transcription and clipboard operation completed');
      }
    } catch (e) {
      // Remove from ongoing operations on error
      HotkeyHandler.removeOngoingOperation('transcription');
      HotkeyHandler.removeOngoingOperation('smart_transcription');

      if (kDebugMode) {
        print('Error in transcription process: $e');
      }

      // Hide overlay on error
      await RecordingOverlayPlatform.hideOverlay();

      BotToast.showText(text: 'Transcription failed: $e');
    }
  }

  /// Get hotkey display string for the overlay
  static String? _getHotkeyDisplayString(String hotkeyKey) {
    try {
      if (!Hive.isBoxOpen('settings')) return null;

      final settingsBox = Hive.box('settings');
      final hotkeyData = settingsBox.get(hotkeyKey);

      if (hotkeyData == null) return null;

      // Convert the stored hotkey data to a HotKey object and use its display formatting
      if (hotkeyData is Map) {
        try {
          // Use the existing hotkey converter to get a proper HotKey object
          final hotkey = hotKeyConverter(hotkeyData);

          // Format for macOS display with spaces between symbols
          List<String> keyParts = [];

          // Add modifiers in the correct order for macOS
          if (hotkey.modifiers?.contains(HotKeyModifier.meta) ?? false) {
            keyParts.add('⌘');
          }
          if (hotkey.modifiers?.contains(HotKeyModifier.control) ?? false) {
            keyParts.add('⌃');
          }
          if (hotkey.modifiers?.contains(HotKeyModifier.alt) ?? false) {
            keyParts.add('⌥');
          }
          if (hotkey.modifiers?.contains(HotKeyModifier.shift) ?? false) {
            keyParts.add('⇧');
          }

          // Add the key itself using Flutter's built-in keyLabel
          keyParts.add(_getMacKeySymbol(hotkey.key));

          // Join with spaces
          final keyText = keyParts.join(' ');

          return keyText.isNotEmpty ? keyText : null;
        } catch (e) {
          if (kDebugMode) {
            print('Error converting hotkey data to HotKey object: $e');
          }
          return null;
        }
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting hotkey display string: $e');
      }
      return null;
    }
  }

  /// Convert key to Mac symbol (similar to HotkeyDisplay widget)
  static String _getMacKeySymbol(KeyboardKey key) {
    // Convert common keys to their Mac symbols
    switch (key.keyLabel) {
      case 'Arrow Up':
        return '↑';
      case 'Arrow Down':
        return '↓';
      case 'Arrow Left':
        return '←';
      case 'Arrow Right':
        return '→';
      case 'Enter':
        return '↩';
      case 'Tab':
        return '⇥';
      case 'Escape':
        return '⎋';
      case 'Delete':
        return '⌫';
      case 'Page Up':
        return '⇞';
      case 'Page Down':
        return '⇟';
      case 'Home':
        return '↖';
      case 'End':
        return '↘';
      case 'Space':
        return 'Space';
      default:
        // For letter keys and others, just use the label
        return key.keyLabel;
    }
  }

  /// Check if transcription recording is currently active
  static bool isRecordingActive() {
    return _isHotkeyRecordingActive;
  }

  /// Cancel the current transcription recording
  static Future<void> cancelRecording() async {
    if (!_isHotkeyRecordingActive) {
      // Even if not actively recording, we might have ongoing operations to cancel
      if (HotkeyHandler.hasOngoingOperations()) {
        if (kDebugMode) {
          print('Cancelling ongoing transcription operations...');
        }

        // Remove any ongoing operations
        HotkeyHandler.removeOngoingOperation('transcription');
        HotkeyHandler.removeOngoingOperation('smart_transcription');

        // Hide the overlay
        await RecordingOverlayPlatform.hideOverlay();

        BotToast.showText(text: 'Transcription operations cancelled');
      }
      return;
    }

    try {
      // Restore system volume if it was muted
      final autoMuteEnabled = Hive.box('settings')
          .get('auto_mute_system_enabled', defaultValue: false) as bool;
      if (autoMuteEnabled) {
        try {
          final success = await VolumeService.instance.restoreVolume();
          if (success) {
            if (kDebugMode) {
              print(
                  'System volume restored after cancelling transcription recording');
            }
          } else {
            if (kDebugMode) {
              print('Volume control not available - no restoration needed');
            }
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error with volume control: $e - no restoration needed');
          }
        }
      }

      // Cancel the recording
      await _recordingRepository?.cancelRecording();
      _isHotkeyRecordingActive = false;
      _recordingStartTime = null;
      _hotkeyRecordedFilePath = null;

      // Remove any ongoing operations
      HotkeyHandler.removeOngoingOperation('transcription');
      HotkeyHandler.removeOngoingOperation('smart_transcription');

      // Unregister Esc key since recording is cancelled
      await HotkeyHandler.unregisterEscKeyForRecording();

      // Hide the overlay
      await RecordingOverlayPlatform.hideOverlay();

      BotToast.showText(text: 'Transcription recording cancelled');

      if (kDebugMode) {
        print('Transcription recording cancelled');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error cancelling transcription recording: $e');
      }
      BotToast.showText(text: 'Error cancelling recording');
    }
  }
}
